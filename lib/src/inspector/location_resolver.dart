import 'dart:convert';

import 'package:flutter/widgets.dart';

/// A widget's constructor call site, as recorded by
/// `--track-widget-creation`.
///
/// [column] is part of the identity on purpose: more than one widget can
/// start on the same line (`Row(children: [Padding(...), Padding(...)])`),
/// so file+line alone is not a unique key.
@immutable
class WidgetLocation {
  const WidgetLocation({
    required this.file,
    required this.line,
    required this.column,
    required this.widgetType,
  });

  final String file;
  final int line;
  final int column;

  /// The Flutter class name at this call site, e.g. 'Padding'. Used to pick
  /// the matching entry in the render-bridge / source-patcher adapter
  /// registries.
  final String widgetType;

  @override
  String toString() => '$file:$line:$column ($widgetType)';
}

/// Resolves an [Element] to its source [WidgetLocation].
///
/// This relies on `WidgetInspectorService` internals ([selection] and
/// `getSelectedWidget`) that Flutter marks `@protected` because they're
/// designed to be driven by DevTools over the VM service protocol, not
/// called directly in-process. There is no public, stable API for reading a
/// widget's creation location from application code - DevTools itself is
/// the sanctioned first-party consumer of exactly these members.
///
/// We call them directly anyway: it's the only way to get this data without
/// standing up a loopback VM-service client, and this whole package only
/// ever runs in debug builds. Every call is wrapped so that if a future
/// Flutter version changes this internal shape, resolution fails closed
/// (returns null) instead of throwing - see [TrackingProbe] for the
/// upfront self-test that turns that failure into a clear banner instead of
/// silent misbehavior.
class LocationResolver {
  const LocationResolver();

  static const String _group = 'design_qa';

  WidgetLocation? locate(Element element) {
    if (element.debugIsDefunct) return null;
    final WidgetInspectorService service = WidgetInspectorService.instance;
    try {
      // ignore: invalid_use_of_protected_member
      service.selection.currentElement = element;
      // ignore: invalid_use_of_protected_member
      final String json = service.getSelectedWidget(null, _group);
      final Map<String, dynamic> map = jsonDecode(json) as Map<String, dynamic>;
      final Map<String, dynamic>? loc = map['creationLocation'] as Map<String, dynamic>?;
      if (loc == null) return null;
      final Object? file = loc['file'];
      final Object? line = loc['line'];
      final Object? column = loc['column'];
      if (file is! String || line is! int || column is! int) return null;
      return WidgetLocation(
        file: file,
        line: line,
        column: column,
        widgetType: element.widget.runtimeType.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
