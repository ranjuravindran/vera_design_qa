import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/design_qa_controller.dart';
import '../core/design_qa_scope.dart';
import '../export/exporter.dart';
import 'design_qa_icons.dart';
import 'device_preset.dart';
import 'overlay_dialog.dart';

/// The always-visible entry point to everything else: draggable, remembers
/// its position for the life of the run via [DesignQAController.pillPosition].
class FloatingPill extends StatefulWidget {
  const FloatingPill({super.key});

  @override
  State<FloatingPill> createState() => _FloatingPillState();
}

class _FloatingPillState extends State<FloatingPill> {
  final GlobalKey _dragHandleKey = GlobalKey();
  bool _devicePickerOpen = false;

  Future<void> _handleReference(DesignQAController controller) async {
    if (controller.referenceImagePath == null) {
      final FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: <String>['png']);
      final String? path = result?.files.single.path;
      if (path == null) return;
      controller
        ..setReferenceImage(path)
        ..cycleReferenceBlend();
      return;
    }
    controller.cycleReferenceBlend();
  }

  Future<void> _handleDevicePreset(BuildContext context, DesignQAController controller) async {
    setState(() => _devicePickerOpen = true);
    final DevicePreset? picked = await showOverlayDialog<DevicePreset>(
      context: context,
      builder: (BuildContext context) => _DevicePickerDialog(current: controller.devicePreset),
    );
    if (!mounted) return;
    setState(() => _devicePickerOpen = false);
    if (picked != null) controller.setDevicePreset(picked);
  }

  Future<void> _handleExport(BuildContext context, DesignQAController controller) async {
    final ExportResult result = await const Exporter().export();
    if (!context.mounted) return;
    final String title = result.filesWritten.isEmpty ? 'Nothing to export' : 'Exported';
    final String message = result.filesWritten.isEmpty
        ? 'No live edits recorded yet - inspect a widget and change a property first.'
        : 'Wrote a patch + changelog for ${result.editedFileCount} file'
            '${result.editedFileCount == 1 ? '' : 's'} to design_qa_out/.';
    showOverlayDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => OverlayDialog.of<void>(context).pop(),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF00A6FF).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFF00A6FF),
              fixedSize: const Size(120, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    final Offset? position = controller.pillPosition;

    final Widget toolbar = GestureDetector(
      key: _dragHandleKey,
      onPanStart: (DragStartDetails details) {
        // Seed a concrete position from wherever the toolbar is actually
        // rendered right now (bottom-center by default) so the first drag
        // doesn't jump the toolbar to some other spot before following the
        // cursor.
        if (controller.pillPosition != null) return;
        final RenderBox? box = _dragHandleKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) return;
        controller.movePillTo(box.localToGlobal(Offset.zero));
      },
      onPanUpdate: (DragUpdateDetails details) =>
          controller.movePillTo((controller.pillPosition ?? Offset.zero) + details.delta),
      child: Material(
        elevation: 8,
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: <Widget>[
              // Two mutually-exclusive tools, Figma-style, rather than one
              // button that silently toggles a hidden mode: Move is what's
              // selected by default, behaves exactly like the app normally
              // does (taps reach it, navigation works), and Inspect is an
              // explicit, visibly-active opt-in for selecting elements -
              // switch back to Move any time to use the app again.
              _PillButton(
                icon: const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
                tooltip: 'Move - click to use the app normally',
                active: controller.mode == DesignQAMode.idle,
                onTap: () => controller.mode = DesignQAMode.idle,
              ),
              _PillButton(
                icon: const DesignQAIconWidget(DesignQAIcon.touch, size: 20),
                tooltip: 'Inspect - click an element to select and edit it',
                active: controller.mode == DesignQAMode.inspecting,
                onTap: () {
                  controller.mode = DesignQAMode.inspecting;
                  debugPrint('[design_qa] pill: inspect tapped, mode now ${controller.mode}');
                },
              ),
              const _PillDivider(),
              _PillButton(
                icon: const DesignQAIconWidget(DesignQAIcon.devicePreview, size: 20),
                tooltip: 'Preview at device size: ${controller.devicePreset.label}',
                active: _devicePickerOpen,
                onTap: () => _handleDevicePreset(context, controller),
              ),
              _PillButton(
                icon: const DesignQAIconWidget(DesignQAIcon.route, size: 20),
                tooltip: 'Jump to screen',
                active: controller.routeJumperOpen,
                onTap: controller.toggleRouteJumper,
              ),
              _PillButton(
                icon: const DesignQAIconWidget(DesignQAIcon.imageReference, size: 20),
                tooltip: 'Overlay a reference image',
                active: controller.referenceBlend != ReferenceBlendState.off,
                onTap: () => _handleReference(controller),
              ),
              _PillButton(
                icon: const DesignQAIconWidget(DesignQAIcon.export, size: 20),
                tooltip: 'Save my changes',
                onTap: () => _handleExport(context, controller),
              ),
            ],
          ),
        ),
      ),
    );

    if (position == null) {
      return Positioned.fill(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(padding: const EdgeInsets.only(bottom: 24), child: toolbar),
        ),
      );
    }
    return Positioned(left: position.dx, top: position.dy, child: toolbar);
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2962FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon,
        ),
      ),
    );
  }
}

class _PillDivider extends StatelessWidget {
  const _PillDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white12,
    );
  }
}

class _DevicePickerDialog extends StatelessWidget {
  const _DevicePickerDialog({required this.current});
  final DevicePreset current;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Preview at device size',
                  style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            for (final DevicePreset preset in DevicePreset.values)
              InkWell(
                onTap: () => OverlayDialog.of<DevicePreset>(context).pop(preset),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 18,
                        child: preset == current
                            ? const Icon(Icons.check_rounded, color: Color(0xFF2962FF), size: 16)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        preset.label,
                        style: TextStyle(
                          color: preset == current ? Colors.white : Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
