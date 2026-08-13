import 'package:flutter/foundation.dart';

import 'edit_key.dart';
import 'edit_record.dart';
import 'edit_value.dart';

/// Global, in-memory store of every live edit made through the overlay this
/// run, keyed by [EditKey] so re-editing the same property replaces the
/// prior value instead of accumulating history.
///
/// Deliberately a static singleton: hot reload re-runs `main()` and rebuilds
/// the widget tree, but does not reset static field values - only a hot
/// *restart* does. A static instance is what lets corrections survive the
/// hot reloads a designer does while iterating on a screen.
///
/// This is the only Flutter-dependent piece of the edit-recording story
/// (it needs [ChangeNotifier] for the UI); [EditRecord] itself stays plain
/// Dart so it can also be built from JSON on the host-side export CLI,
/// which never has Flutter loaded. See edit_value.dart.
class EditSession extends ChangeNotifier {
  EditSession._();

  static final EditSession instance = EditSession._();

  final Map<EditKey, EditRecord> _edits = <EditKey, EditRecord>{};

  Map<EditKey, EditRecord> get edits => Map.unmodifiable(_edits);

  bool get isEmpty => _edits.isEmpty;
  bool get isNotEmpty => _edits.isNotEmpty;

  EditRecord? recordFor(EditKey key) => _edits[key];

  void apply({
    required EditKey key,
    required String widgetType,
    required EditValue value,
    required EditValue originalValue,
  }) {
    final EditRecord? existing = _edits[key];
    _edits[key] = EditRecord(
      key: key,
      widgetType: widgetType,
      value: value,
      // Keep the *first* original value we ever saw for this key, so
      // repeated tweaks still diff against the true source value.
      originalValue: existing?.originalValue ?? originalValue,
      editedAt: DateTime.now(),
    );
    notifyListeners();
  }

  void revert(EditKey key) {
    if (_edits.remove(key) != null) notifyListeners();
  }

  void clear() {
    if (_edits.isEmpty) return;
    _edits.clear();
    notifyListeners();
  }

  List<EditRecord> forFile(String file) =>
      _edits.values.where((EditRecord e) => e.key.file == file).toList(growable: false);

  Set<String> get touchedFiles => _edits.keys.map((EditKey k) => k.file).toSet();
}
