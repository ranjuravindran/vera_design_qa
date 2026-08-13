import 'package:flutter/widgets.dart';

import '../adapter.dart';

class DecoratedBoxAdapter extends PropertyAdapter {
  const DecoratedBoxAdapter();

  @override
  List<String> get widgetTypes => const <String>['DecoratedBox'];

  @override
  Set<String> get supportedProperties => const <String>{'color', 'borderRadius'};

  @override
  Object? read(Element element, String property) {
    final RenderObject? ro = element.renderObject;
    if (ro == null) return null;
    final Decoration decoration = (ro as dynamic).decoration as Decoration;
    if (decoration is! BoxDecoration) return null;
    return property == 'color' ? decoration.color : decoration.borderRadius;
  }

  @override
  void write(Element element, String property, Object? value) {
    final RenderObject? ro = element.renderObject;
    if (ro == null) {
      throw AdapterUnsupportedException('This DecoratedBox has no render object to edit live yet.');
    }
    final Decoration decoration = (ro as dynamic).decoration as Decoration;
    if (decoration is! BoxDecoration) {
      throw AdapterUnsupportedException('Only BoxDecoration is supported for live editing.');
    }
    (ro as dynamic).decoration = property == 'color'
        ? decoration.copyWith(color: value as Color)
        : decoration.copyWith(borderRadius: value as BorderRadiusGeometry);
  }
}

class ColoredBoxAdapter extends PropertyAdapter {
  const ColoredBoxAdapter();

  @override
  List<String> get widgetTypes => const <String>['ColoredBox'];

  @override
  Set<String> get supportedProperties => const <String>{'color'};

  @override
  Object? read(Element element, String property) {
    final RenderObject? ro = element.renderObject;
    return ro == null ? null : (ro as dynamic).color as Color;
  }

  @override
  void write(Element element, String property, Object? value) {
    final RenderObject? ro = element.renderObject;
    if (ro == null || value is! Color) {
      throw AdapterUnsupportedException('This ColoredBox has no render object to edit live yet.');
    }
    (ro as dynamic).color = value;
  }
}
