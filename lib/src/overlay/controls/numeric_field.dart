import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A labeled numeric control supporting every input mode the spec calls
/// for: drag the *label* to scrub (kept separate from the text field so the
/// drag gesture never fights the field's own text-selection drag), arrow
/// keys for ±[step], shift+arrow for ±[bigStep], or type a value directly.
class NumericField extends StatefulWidget {
  const NumericField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.bigStep = 8,
    this.suffix,
    this.labelWidth = 76,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final double bigStep;
  final String? suffix;

  /// Width of the (draggable-to-scrub) label column. Defaults to a width
  /// that fits full words like "Corner radius"; pass something narrower
  /// (e.g. in [EdgeInsetsField]'s compact grid) for single-letter labels.
  final double labelWidth;

  @override
  State<NumericField> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<NumericField> {
  late final TextEditingController _text;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: _fmt(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant NumericField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _text.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // double.toInt() throws for non-finite values (double.infinity is a real,
  // common value here - e.g. SizedBox(width: double.infinity)) - guard
  // defensively since this is a reusable control, even though the one
  // known non-finite case is now caught earlier in _PropertyRow.
  String _fmt(double v) {
    if (!v.isFinite) return v.toString();
    return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final bool shift = HardwareKeyboard.instance.isShiftPressed;
    final double delta = shift ? widget.bigStep : widget.step;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onChanged(widget.value + delta);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onChanged(widget.value - delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            onHorizontalDragUpdate: (DragUpdateDetails d) =>
                widget.onChanged(widget.value + d.delta.dx),
            child: SizedBox(
              width: widget.labelWidth,
              child: Text(
                widget.label,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: KeyboardListener(
            focusNode: _focusNode,
            onKeyEvent: _handleKey,
            child: TextField(
              controller: _text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[-\d.]'))
              ],
              decoration: InputDecoration(
                isDense: true,
                suffixText: widget.suffix,
                suffixStyle:
                    const TextStyle(color: Colors.white38, fontSize: 11),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              onSubmitted: (String text) {
                final double? v = double.tryParse(text);
                if (v != null) widget.onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
