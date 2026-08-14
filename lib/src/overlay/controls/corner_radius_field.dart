import 'package:flutter/material.dart';

import 'numeric_field.dart';

/// Four-corner BorderRadius control with a link toggle, matching Figma's
/// own corner-radius UI - a single "Corner radius" number (what this
/// showed before) hid that Flutter's BorderRadius, like Figma's, actually
/// supports each corner independently (`BorderRadius.only(...)`).
/// Defaults linked (all four corners move together) unless the source
/// already has different values per corner, in which case it starts
/// unlinked so an existing intentional asymmetry isn't silently flattened.
class CornerRadiusField extends StatefulWidget {
  const CornerRadiusField({super.key, required this.value, required this.onChanged});

  final BorderRadius value;
  final ValueChanged<BorderRadius> onChanged;

  @override
  State<CornerRadiusField> createState() => _CornerRadiusFieldState();
}

class _CornerRadiusFieldState extends State<CornerRadiusField> {
  late bool _linked = _allCornersEqual(widget.value);

  static bool _allCornersEqual(BorderRadius r) =>
      r.topLeft == r.topRight && r.topRight == r.bottomLeft && r.bottomLeft == r.bottomRight;

  void _updateCorner({double? tl, double? tr, double? bl, double? br}) {
    if (_linked) {
      final double v = tl ?? tr ?? bl ?? br ?? 0;
      widget.onChanged(BorderRadius.circular(v));
      return;
    }
    final BorderRadius r = widget.value;
    widget.onChanged(BorderRadius.only(
      topLeft: Radius.circular(tl ?? r.topLeft.x),
      topRight: Radius.circular(tr ?? r.topRight.x),
      bottomLeft: Radius.circular(bl ?? r.bottomLeft.x),
      bottomRight: Radius.circular(br ?? r.bottomRight.x),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius r = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: NumericField(
                labelWidth: 20,
                label: 'TL',
                value: r.topLeft.x,
                onChanged: (double v) => _updateCorner(tl: v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumericField(
                labelWidth: 20,
                label: 'TR',
                value: r.topRight.x,
                onChanged: (double v) => _updateCorner(tr: v),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: _linked ? 'Corners linked - unlink to set independently' : 'Corners independent - link to match all four',
              child: InkWell(
                onTap: () => setState(() => _linked = !_linked),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _linked ? Icons.link_rounded : Icons.link_off_rounded,
                    size: 16,
                    color: _linked ? const Color(0xFF2962FF) : Colors.white38,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: NumericField(
                labelWidth: 20,
                label: 'BL',
                value: r.bottomLeft.x,
                onChanged: (double v) => _updateCorner(bl: v),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumericField(
                labelWidth: 20,
                label: 'BR',
                value: r.bottomRight.x,
                onChanged: (double v) => _updateCorner(br: v),
              ),
            ),
            // Matches the link toggle's footprint above so both rows' pairs
            // of fields line up.
            const SizedBox(width: 32),
          ],
        ),
      ],
    );
  }
}
