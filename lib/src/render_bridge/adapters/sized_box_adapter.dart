import 'package:flutter/widgets.dart';

import '../adapter.dart';

class SizedBoxAdapter extends PropertyAdapter {
  const SizedBoxAdapter();

  @override
  List<String> get widgetTypes => const <String>['SizedBox'];

  @override
  Set<String> get supportedProperties => const <String>{'width', 'height'};

  @override
  Object? read(Element element, String property) {
    final RenderObject? ro = element.renderObject;
    if (ro == null) return null;
    final BoxConstraints c = (ro as dynamic).additionalConstraints as BoxConstraints;
    if (property == 'width') return c.hasTightWidth ? c.minWidth : null;
    return c.hasTightHeight ? c.minHeight : null;
  }

  @override
  void write(Element element, String property, Object? value) {
    final RenderObject? ro = element.renderObject;
    if (ro == null || value is! num) {
      throw AdapterUnsupportedException('This SizedBox has no render object to edit live yet.');
    }
    final BoxConstraints current = (ro as dynamic).additionalConstraints as BoxConstraints;
    final double? width =
        property == 'width' ? value.toDouble() : (current.hasTightWidth ? current.minWidth : null);
    final double? height =
        property == 'height' ? value.toDouble() : (current.hasTightHeight ? current.minHeight : null);
    (ro as dynamic).additionalConstraints = BoxConstraints.tightFor(width: width, height: height);
  }
}
