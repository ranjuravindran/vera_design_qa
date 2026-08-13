import 'package:flutter/widgets.dart';

import 'location_resolver.dart';

/// Flutter's own convention for a private class is a leading underscore -
/// meaningless (and odd-looking) to a designer reading a layer name in the
/// breadcrumb or property panel, so it's stripped everywhere a widget type
/// is shown in design_qa's chrome.
String friendlyWidgetTypeName(String type) => type.startsWith('_') ? type.substring(1) : type;

/// One entry in the ancestor breadcrumb - lets a designer who tapped a
/// child widget walk up to "the Padding or Container I actually meant to
/// hit" without re-tapping pixel-perfectly.
class BreadcrumbEntry {
  const BreadcrumbEntry({required this.element, required this.location});

  final Element element;
  final WidgetLocation? location;

  String get label =>
      friendlyWidgetTypeName(location?.widgetType ?? element.widget.runtimeType.toString());
}

/// The widget currently selected in inspect mode, plus enough ancestor
/// context to render the breadcrumb and enough geometry to draw the
/// highlight box.
class WidgetSelection {
  WidgetSelection({
    required this.element,
    required this.location,
    required this.breadcrumb,
  });

  final Element element;
  final WidgetLocation? location;

  /// Nearest-first: index 0 is [element] itself.
  final List<BreadcrumbEntry> breadcrumb;

  bool get isValid => !element.debugIsDefunct;

  RenderBox? get renderBox {
    final RenderObject? ro = element.renderObject;
    return ro is RenderBox ? ro : null;
  }

  Rect? get globalRect {
    final RenderBox? box = renderBox;
    if (box == null || !box.attached || !box.hasSize) return null;
    final Offset topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  /// Re-target the selection to an ancestor from the breadcrumb.
  WidgetSelection withAncestor(BreadcrumbEntry entry) {
    final int index = breadcrumb.indexOf(entry);
    return WidgetSelection(
      element: entry.element,
      location: entry.location,
      breadcrumb: index >= 0 ? breadcrumb.sublist(index) : breadcrumb,
    );
  }
}
