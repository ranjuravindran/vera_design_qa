import '../core/edit_record.dart';
import '../core/edit_value.dart';
import 'value_serializer.dart';

/// Plain-English summary of a batch of edits, grouped by file - the
/// non-technical half of an export, meant to be read by whoever reviews
/// the patch, not just the engineer applying it.
String buildChangelog(Map<String, List<EditRecord>> byFile, {required String projectRoot}) {
  final StringBuffer out = StringBuffer('# design_qa changes\n\n');
  if (byFile.isEmpty) {
    out.writeln('No edits recorded.');
    return out.toString();
  }
  for (final MapEntry<String, List<EditRecord>> entry in byFile.entries) {
    final String relative =
        entry.key.startsWith(projectRoot) ? entry.key.substring(projectRoot.length + 1) : entry.key;
    out.writeln('## $relative\n');
    for (final EditRecord e in entry.value) {
      out.writeln('- ${_describe(e)}');
    }
    out.writeln();
  }
  return out.toString();
}

String _describe(EditRecord e) {
  final String from = _fmt(e.originalValue);
  final String to = _fmt(e.value);
  return '**${e.widgetType}.${e.key.property}** (line ${e.key.line}): `$from` -> `$to`';
}

String _fmt(EditValue v) {
  return switch (v) {
    NumValue value => serializeNum(value.value),
    ColorValue value => serializeColor(value),
    EdgeInsetsValue value => serializeEdgeInsets(value),
    BorderRadiusValue value => serializeBorderRadius(value),
    EnumValue value => serializeEnum(value),
  };
}
