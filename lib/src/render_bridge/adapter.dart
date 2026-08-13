import 'package:flutter/widgets.dart';

/// Reads and writes one family of live properties directly on the
/// [RenderObject] tree for a specific Flutter widget type - no rebuild, no
/// setState.
///
/// Field access on the render object is done via `dynamic` on purpose: some
/// of the concrete `RenderObject` classes involved (e.g. `ColoredBox`'s)
/// are framework-private, so their type can't be named from this package.
/// Dart's privacy only hides the *type name* across libraries, not member
/// access on an instance you already hold - so `(renderObject as
/// dynamic).color = value` still works. A property name that's changed or
/// removed on a future Flutter version surfaces as a normal
/// [NoSuchMethodError], which callers turn into the same graceful
/// "unsupported" message used for widget types with no adapter at all,
/// rather than a crash.
abstract class PropertyAdapter {
  const PropertyAdapter();

  /// Flutter widget class names this adapter targets, e.g. `['Row',
  /// 'Column']`. More than one when several widgets share a render shape.
  List<String> get widgetTypes;

  /// Logical property names this adapter supports, matching the names used
  /// in [EditKey] and by the source-patcher's argument map.
  Set<String> get supportedProperties;

  /// Current live value, read straight from the render tree. The property
  /// panel seeds its controls from this - never from re-parsing source.
  Object? read(Element element, String property);

  /// Mutate the render tree in place.
  ///
  /// Throws [AdapterUnsupportedException] when this element doesn't
  /// currently have the render structure the property needs (e.g. asking
  /// for 'borderRadius' on a `Container` with no `decoration` yet) - there
  /// is deliberately no live "add a new branch to the render tree" path;
  /// that requires a real rebuild, which is exactly what live mutation is
  /// avoiding. See doc/limitations.md.
  void write(Element element, String property, Object? value);
}

class AdapterUnsupportedException implements Exception {
  AdapterUnsupportedException(this.message);
  final String message;

  @override
  String toString() => message;
}
