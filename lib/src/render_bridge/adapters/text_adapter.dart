import 'package:flutter/widgets.dart';

import '../adapter.dart';

/// `Text` builds a `RichText` (no extra wrapper), so its element has exactly
/// one child element whose render object is the `RenderParagraph` that
/// actually owns the mutable style.
///
/// Only the single-style case is supported live: `Text('label')` produces a
/// root `TextSpan` with a style and no child spans. Multi-span `RichText` /
/// `Text.rich` trees are out of scope for live style edits - see
/// doc/limitations.md - because there's no single unambiguous "the" style
/// to point a font-size slider at.
class TextAdapter extends PropertyAdapter {
  const TextAdapter();

  @override
  List<String> get widgetTypes => const <String>['Text'];

  @override
  Set<String> get supportedProperties =>
      const <String>{'fontSize', 'fontWeight', 'letterSpacing', 'lineHeight'};

  Element? _paragraphElement(Element textElement) {
    Element? found;
    textElement.visitChildren((Element e) {
      if (e.widget.runtimeType.toString() == 'RichText') found = e;
    });
    return found;
  }

  TextStyle? _currentStyle(Element textElement) {
    final Element? richTextElement = _paragraphElement(textElement);
    final RenderObject? ro = richTextElement?.renderObject;
    if (ro == null) return null;
    final InlineSpan span = (ro as dynamic).text as InlineSpan;
    return span is TextSpan ? span.style : null;
  }

  @override
  Object? read(Element element, String property) {
    final TextStyle? style = _currentStyle(element);
    if (style == null) return null;
    switch (property) {
      case 'fontSize':
        return style.fontSize;
      case 'fontWeight':
        return style.fontWeight?.value ?? FontWeight.normal.value;
      case 'letterSpacing':
        return style.letterSpacing ?? 0.0;
      case 'lineHeight':
        return style.height;
    }
    return null;
  }

  @override
  void write(Element element, String property, Object? value) {
    final Element? richTextElement = _paragraphElement(element);
    final RenderObject? ro = richTextElement?.renderObject;
    if (ro == null) {
      throw AdapterUnsupportedException('This Text has no render object to edit live yet.');
    }
    final InlineSpan span = (ro as dynamic).text as InlineSpan;
    if (span is! TextSpan) {
      throw AdapterUnsupportedException('Only single-style Text is supported for live editing.');
    }
    final TextStyle style = span.style ?? const TextStyle();
    final TextStyle updated = switch (property) {
      'fontSize' => style.copyWith(fontSize: (value as num).toDouble()),
      'fontWeight' => style.copyWith(fontWeight: _weightFromInt((value as num).toInt())),
      'letterSpacing' => style.copyWith(letterSpacing: (value as num).toDouble()),
      'lineHeight' => style.copyWith(height: (value as num).toDouble()),
      _ => style,
    };
    (ro as dynamic).text = TextSpan(
      text: span.text,
      children: span.children,
      style: updated,
      recognizer: span.recognizer,
      semanticsLabel: span.semanticsLabel,
    );
  }

  FontWeight _weightFromInt(int weight) {
    final int index = ((weight ~/ 100) - 1).clamp(0, FontWeight.values.length - 1);
    return FontWeight.values[index];
  }
}
