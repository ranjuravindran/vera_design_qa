/// Identifies a single editable property on a single widget instantiation
/// in source: the exact constructor call site plus the named argument it
/// controls.
///
/// Column is part of the identity (not just file:line) because
/// `--track-widget-creation` locations are precise to the column, and more
/// than one widget can start on the same line (e.g. `Row(children: [Padding(...), Padding(...)])`).
class EditKey {
  const EditKey({
    required this.file,
    required this.line,
    required this.column,
    required this.property,
  });

  final String file;
  final int line;
  final int column;

  /// Logical property name, e.g. 'padding', 'color', 'fontSize'.
  /// Adapters agree on these names between the render-bridge (live preview)
  /// and the source-patcher (export) sides.
  final String property;

  @override
  bool operator ==(Object other) =>
      other is EditKey &&
      other.file == file &&
      other.line == line &&
      other.column == column &&
      other.property == property;

  @override
  int get hashCode => Object.hash(file, line, column, property);

  @override
  String toString() => '$file:$line:$column#$property';
}
