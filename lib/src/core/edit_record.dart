import 'edit_key.dart';
import 'edit_value.dart';

/// One recorded correction: what property, on what kind of widget, changed
/// from what to what. Pure Dart on purpose - see [EditValue] for why - so
/// it can be shared between the live in-app [EditSession] and the
/// host-side export CLI, which never has Flutter loaded.
class EditRecord {
  const EditRecord({
    required this.key,
    required this.widgetType,
    required this.value,
    required this.originalValue,
    required this.editedAt,
  });

  final EditKey key;

  /// The Flutter widget class this edit was made against, e.g. 'Padding'.
  /// Both the render-bridge (live preview) and the source-patcher (export)
  /// use this to pick the matching adapter - it must stay in sync with the
  /// adapter registry's type keys.
  final String widgetType;

  final EditValue value;
  final EditValue originalValue;
  final DateTime editedAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'file': key.file,
        'line': key.line,
        'column': key.column,
        'property': key.property,
        'widgetType': widgetType,
        'value': value.toJson(),
        'originalValue': originalValue.toJson(),
        'editedAt': editedAt.toIso8601String(),
      };

  static EditRecord fromJson(Map<String, Object?> json) => EditRecord(
        key: EditKey(
          file: json['file']! as String,
          line: json['line']! as int,
          column: json['column']! as int,
          property: json['property']! as String,
        ),
        widgetType: json['widgetType']! as String,
        value: EditValue.fromJson(json['value']! as Map<String, Object?>),
        originalValue: EditValue.fromJson(json['originalValue']! as Map<String, Object?>),
        editedAt: DateTime.parse(json['editedAt']! as String),
      );
}
