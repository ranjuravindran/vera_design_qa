import 'package:flutter/widgets.dart';

import '../adapter.dart';

/// `Row` and `Column` are both `Flex` subclasses with no build() step of
/// their own, so an element for either has a `RenderFlex` as its own render
/// object directly - no descending required, unlike `Container`.
class FlexAdapter extends PropertyAdapter {
  const FlexAdapter();

  @override
  List<String> get widgetTypes => const <String>['Row', 'Column'];

  @override
  Set<String> get supportedProperties =>
      const <String>{'spacing', 'mainAxisAlignment', 'crossAxisAlignment'};

  @override
  Object? read(Element element, String property) {
    final RenderObject? ro = element.renderObject;
    if (ro == null) return null;
    final dynamic flex = ro;
    switch (property) {
      case 'spacing':
        return flex.spacing as double;
      case 'mainAxisAlignment':
        return flex.mainAxisAlignment as MainAxisAlignment;
      case 'crossAxisAlignment':
        return flex.crossAxisAlignment as CrossAxisAlignment;
    }
    return null;
  }

  @override
  void write(Element element, String property, Object? value) {
    final RenderObject? ro = element.renderObject;
    if (ro == null) {
      throw AdapterUnsupportedException('This widget has no render object to edit live yet.');
    }
    final dynamic flex = ro;
    switch (property) {
      case 'spacing':
        flex.spacing = (value as num).toDouble();
        return;
      case 'mainAxisAlignment':
        flex.mainAxisAlignment = value as MainAxisAlignment;
        return;
      case 'crossAxisAlignment':
        flex.crossAxisAlignment = value as CrossAxisAlignment;
        return;
    }
  }
}
