import 'package:flutter/material.dart';

import '../overlay_dialog.dart';

/// Swatch + picker, per the spec - a small built-in ARGB slider/hex picker
/// rather than pulling in an extra pub dependency for something this
/// self-contained.
class ColorField extends StatelessWidget {
  const ColorField(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged});

  final String label;
  final Color value;
  final ValueChanged<Color> onChanged;

  Future<void> _openPicker(BuildContext context) async {
    final Color? picked = await showOverlayDialog<Color>(
      context: context,
      builder: (BuildContext context) => _ColorPickerDialog(initial: value),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(
            width: 76,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12))),
        Expanded(
          child: InkWell(
            onTap: () => _openPicker(context),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                // Same resting fill as every other field for visual
                // consistency - unlike a text field this one keeps a
                // hairline border regardless of state, since it's
                // containing a color swatch that needs a defined edge
                // (a near-white or near-background fill would otherwise
                // disappear against the panel).
                color: const Color(0xFF141414),
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: value,
                      // A rounded square, not a circle: matches Figma's own
                      // fill-swatch shape - reads as "the shape of the fill
                      // itself" rather than a selection/avatar dot.
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${value.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});
  final Color initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late double _r, _g, _b, _a;
  late TextEditingController _hex;

  @override
  void initState() {
    super.initState();
    _r = widget.initial.r * 255;
    _g = widget.initial.g * 255;
    _b = widget.initial.b * 255;
    _a = widget.initial.a * 255;
    _hex = TextEditingController(text: _currentHex());
  }

  Color get _current =>
      Color.fromARGB(_a.round(), _r.round(), _g.round(), _b.round());

  String _currentHex() =>
      _current.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();

  void _applyHex(String text) {
    String hex = text.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return;
    final int? argb = int.tryParse(hex, radix: 16);
    if (argb == null) return;
    setState(() {
      _a = ((argb >> 24) & 0xFF).toDouble();
      _r = ((argb >> 16) & 0xFF).toDouble();
      _g = ((argb >> 8) & 0xFF).toDouble();
      _b = (argb & 0xFF).toDouble();
    });
  }

  // Each channel's active track is tinted to match (red/green/blue, grey
  // for alpha) - a common convention (Photoshop, Sketch, Figma's own
  // "advanced" color panel) that makes four otherwise-identical sliders
  // scannable at a glance instead of relying only on the letter label.
  Widget _slider(String label, Color trackColor, double value,
      ValueChanged<double> onChanged) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 16,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: trackColor,
              thumbColor: trackColor,
              overlayColor: trackColor.withValues(alpha: 0.16),
            ),
            child: Slider(value: value, min: 0, max: 255, onChanged: onChanged),
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fill color'),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: _current,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(height: 16),
            _slider(
                'R',
                const Color(0xFFEA4335),
                _r,
                (double v) => setState(() {
                      _r = v;
                      _hex.text = _currentHex();
                    })),
            _slider(
                'G',
                const Color(0xFF34A853),
                _g,
                (double v) => setState(() {
                      _g = v;
                      _hex.text = _currentHex();
                    })),
            _slider(
                'B',
                const Color(0xFF4285F4),
                _b,
                (double v) => setState(() {
                      _b = v;
                      _hex.text = _currentHex();
                    })),
            _slider(
                'A',
                Colors.white70,
                _a,
                (double v) => setState(() {
                      _a = v;
                      _hex.text = _currentHex();
                    })),
            const SizedBox(height: 4),
            TextField(
              controller: _hex,
              style: const TextStyle(fontSize: 13),
              decoration:
                  const InputDecoration(labelText: 'Hex', prefixText: '#'),
              onSubmitted: _applyHex,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
            onPressed: () => OverlayDialog.of<Color>(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () => OverlayDialog.of<Color>(context).pop(_current),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
