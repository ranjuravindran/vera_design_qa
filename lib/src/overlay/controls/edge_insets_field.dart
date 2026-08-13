import 'package:flutter/material.dart';

import 'numeric_field.dart';

/// Four-side EdgeInsets control, as a compact 2x2 grid (Left/Top over
/// Right/Bottom) rather than four stacked full-width rows - the same
/// property took a quarter of the panel's visible height for no reason,
/// and cramped side-by-side fields still read fine at this width since
/// each one only needs to show a couple of digits.
class EdgeInsetsField extends StatelessWidget {
  const EdgeInsetsField(
      {super.key, required this.value, required this.onChanged});

  final EdgeInsets value;
  final ValueChanged<EdgeInsets> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: NumericField(
                labelWidth: 14,
                label: 'L',
                value: value.left,
                onChanged: (double v) => onChanged(value.copyWith(left: v)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumericField(
                labelWidth: 14,
                label: 'T',
                value: value.top,
                onChanged: (double v) => onChanged(value.copyWith(top: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: NumericField(
                labelWidth: 14,
                label: 'R',
                value: value.right,
                onChanged: (double v) => onChanged(value.copyWith(right: v)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: NumericField(
                labelWidth: 14,
                label: 'B',
                value: value.bottom,
                onChanged: (double v) => onChanged(value.copyWith(bottom: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
