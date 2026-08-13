import 'package:flutter/widgets.dart';

import '../adapter.dart';

class PaddingAdapter extends PropertyAdapter {
  const PaddingAdapter();

  @override
  List<String> get widgetTypes => const <String>['Padding'];

  @override
  Set<String> get supportedProperties => const <String>{'padding'};

  @override
  Object? read(Element element, String property) {
    final RenderObject? ro = element.renderObject;
    if (ro == null) return null;
    return (ro as dynamic).padding as EdgeInsetsGeometry?;
  }

  @override
  void write(Element element, String property, Object? value) {
    final RenderObject? ro = element.renderObject;
    if (ro == null || value is! EdgeInsetsGeometry) {
      throw AdapterUnsupportedException('This Padding has no render object to edit live yet.');
    }
    (ro as dynamic).padding = value;
  }
}
