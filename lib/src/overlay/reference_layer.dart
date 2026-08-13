import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/design_qa_controller.dart';
import '../core/design_qa_scope.dart';

/// Pins a loaded PNG over the running app with opacity, X/Y offset, scale,
/// and a difference blend mode - per the spec, for spotting exact pixel
/// misalignment against a Figma export.
///
/// 'opacity' mode is a plain [Opacity] widget - ordinary alpha compositing,
/// nothing special needed. 'difference' mode needs the image's own paint
/// call to carry `BlendMode.difference`, which only blends correctly
/// against whatever the app already painted if there's no offscreen layer
/// (`saveLayer`) between them - so this paints directly via a
/// [CustomPainter] rather than through `Opacity`/`ColorFiltered`, which
/// would isolate it onto its own transparent layer and blend against
/// nothing.
class FigmaReferenceLayer extends StatefulWidget {
  const FigmaReferenceLayer({super.key});

  @override
  State<FigmaReferenceLayer> createState() => _FigmaReferenceLayerState();
}

class _FigmaReferenceLayerState extends State<FigmaReferenceLayer> {
  ui.Image? _image;
  String? _loadedPath;

  Future<void> _ensureLoaded(DesignQAController controller) async {
    final String? path = controller.referenceImagePath;
    if (path == null || path == _loadedPath) return;
    _loadedPath = path; // claim it before awaiting so concurrent builds don't double-load
    try {
      final ui.Image image = await _decodeFromPath(path);
      if (!mounted) return;
      setState(() => _image = image);
    } catch (_) {
      // Leave the previous image (if any) up rather than blanking the
      // overlay on a transient read failure.
    }
  }

  Future<ui.Image> _decodeFromPath(String path) async {
    final Uint8List bytes = await _readBytes(path);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<Uint8List> _readBytes(String path) async {
    final File file = File(path);
    return file.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    _ensureLoaded(controller);
    final ui.Image? image = _image;
    if (image == null) return const SizedBox.shrink();

    final Size size = Size(
      image.width.toDouble() * controller.referenceScale,
      image.height.toDouble() * controller.referenceScale,
    );

    Widget picture = CustomPaint(
      size: size,
      painter: controller.referenceBlend == ReferenceBlendState.difference
          ? _DifferencePainter(image)
          : _NormalPainter(image),
    );

    if (controller.referenceBlend == ReferenceBlendState.opacity) {
      picture = Opacity(opacity: controller.referenceOpacity, child: picture);
    }

    return Positioned(
      left: controller.referenceOffset.dx,
      top: controller.referenceOffset.dy,
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails d) =>
            controller.setReferenceOffset(controller.referenceOffset + d.delta),
        child: picture,
      ),
    );
  }
}

class _NormalPainter extends CustomPainter {
  _NormalPainter(this.image);
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(canvas: canvas, rect: Offset.zero & size, image: image, fit: BoxFit.fill);
  }

  @override
  bool shouldRepaint(covariant _NormalPainter oldDelegate) => oldDelegate.image != image;
}

class _DifferencePainter extends CustomPainter {
  _DifferencePainter(this.image);
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..blendMode = BlendMode.difference;
    final Rect src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, src, Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _DifferencePainter oldDelegate) => oldDelegate.image != image;
}

/// Floating control strip for opacity/scale, shown alongside the pill
/// whenever a reference image is loaded and active.
class ReferenceControls extends StatelessWidget {
  const ReferenceControls({super.key});

  Future<void> _pickImage(DesignQAController controller) async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: <String>['png']);
    final String? path = result?.files.single.path;
    if (path != null) controller.setReferenceImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    if (controller.referenceBlend == ReferenceBlendState.off) return const SizedBox.shrink();
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        color: const Color(0xEE1E1E1E),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.folder_open, color: Colors.white70, size: 18),
                tooltip: 'Load PNG',
                onPressed: () => _pickImage(controller),
              ),
              const Text('Opacity', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Expanded(
                child: Slider(
                  value: controller.referenceOpacity,
                  onChanged: controller.setReferenceOpacity,
                ),
              ),
              const Text('Scale', style: TextStyle(color: Colors.white70, fontSize: 11)),
              Expanded(
                child: Slider(
                  value: controller.referenceScale,
                  min: 0.25,
                  max: 3,
                  onChanged: controller.setReferenceScale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
