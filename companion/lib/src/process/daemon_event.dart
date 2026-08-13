/// One event from Flutter's `--machine` daemon protocol: each stdout line
/// is either plain human-readable text (passed through separately, see
/// `FlutterRunSession.rawOutput`) or a JSON array holding exactly one
/// `{"event": ..., "params": {...}}` object. Confirmed against a real
/// `flutter run --machine` session rather than assumed from docs - the
/// event names and shapes below are what actually comes across the wire on
/// Flutter 3.44.6.
class DaemonEvent {
  const DaemonEvent(this.name, this.params);
  final String name;
  final Map<String, Object?> params;

  Object? operator [](String key) => params[key];

  @override
  String toString() => '$name($params)';
}
