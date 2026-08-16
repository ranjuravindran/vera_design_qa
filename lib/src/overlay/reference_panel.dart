import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/design_qa_controller.dart';
import '../core/design_qa_scope.dart';
import 'design_qa_icons.dart';
import 'property_sidebar.dart' show panelSeamBorder;

/// Docked in the property sidebar (above whatever the selection panel is
/// showing) whenever a reference image is loaded - replaces the old
/// floating [ReferenceControls] bar, which sat at the bottom of the screen
/// and overlapped [FloatingPill] once the pill was dragged anywhere near
/// it. As a sidebar section it never overlaps app or chrome content, the
/// same reasoning [PropertySidebar] itself is built on.
class ReferencePanel extends StatelessWidget {
  const ReferencePanel({super.key});

  Future<void> _replaceImage(DesignQAController controller) async {
    final FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: <String>['png']);
    final String? path = result?.files.single.path;
    if (path != null) controller.setReferenceImage(path);
  }

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    final bool visible = controller.referenceBlend != ReferenceBlendState.off;

    return Container(
      decoration: const BoxDecoration(border: panelSeamBorder),
      child: Material(
        color: const Color(0xFF1E1E1E),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
              child: Row(
                children: <Widget>[
                  const DesignQAIconWidget(DesignQAIcon.imageReference, size: 16, color: Colors.white70),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Reference image',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  Tooltip(
                    message: 'Remove reference image',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => controller.removeReferenceImage(),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: DesignQAIconWidget(DesignQAIcon.close, size: 14, color: Colors.white54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      DesignQAIconWidget(
                        visible ? DesignQAIcon.visibility : DesignQAIcon.visibilityOff,
                        size: 16,
                        color: Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Visible', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                      Switch(
                        value: visible,
                        onChanged: controller.setReferenceVisible,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _BlendModeSwitch(
                    mode: controller.referenceBlend == ReferenceBlendState.off
                        ? ReferenceBlendState.opacity
                        : controller.referenceBlend,
                    onChanged: controller.setReferenceBlendMode,
                  ),
                  const SizedBox(height: 12),
                  _SliderRow(
                    icon: DesignQAIcon.opacity,
                    label: 'Opacity',
                    value: controller.referenceOpacity,
                    valueLabel: '${(controller.referenceOpacity * 100).round()}%',
                    onChanged: controller.setReferenceOpacity,
                  ),
                  const SizedBox(height: 8),
                  _SliderRow(
                    icon: DesignQAIcon.size,
                    label: 'Scale',
                    value: controller.referenceScale,
                    min: 0.25,
                    max: 3,
                    valueLabel: '${controller.referenceScale.toStringAsFixed(2)}x',
                    onChanged: controller.setReferenceScale,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _replaceImage(controller),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.folder_open, color: Colors.white70, size: 14),
                          SizedBox(width: 6),
                          Text('Replace image', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlendModeSwitch extends StatelessWidget {
  const _BlendModeSwitch({required this.mode, required this.onChanged});

  final ReferenceBlendState mode;
  final ValueChanged<ReferenceBlendState> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(color: const Color(0xFF141414), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: <Widget>[
          _BlendModeOption(
            label: 'Normal',
            selected: mode == ReferenceBlendState.opacity,
            onTap: () => onChanged(ReferenceBlendState.opacity),
          ),
          _BlendModeOption(
            label: 'Difference',
            selected: mode == ReferenceBlendState.difference,
            onTap: () => onChanged(ReferenceBlendState.difference),
          ),
        ],
      ),
    );
  }
}

class _BlendModeOption extends StatelessWidget {
  const _BlendModeOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF009DFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
  });

  final DesignQAIcon icon;
  final String label;
  final double value;
  final double min;
  final double max;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        DesignQAIconWidget(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        SizedBox(
          width: 46,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 38,
          child: Text(
            valueLabel,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
      ],
    );
  }
}
