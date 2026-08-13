import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'daemon_event.dart';

/// A running `flutter run --track-widget-creation --machine` process,
/// parsed into a typed event stream.
///
/// `--machine` mode is Flutter's own daemon protocol - the same one VS
/// Code's Flutter extension drives - so progress/ready state comes from
/// structured events (`app.progress`, `app.debugPort`, `app.started`)
/// instead of scraping human-readable terminal text, which is what makes
/// translating it into plain-English status messages reliable.
class FlutterRunSession {
  FlutterRunSession._(this._process);

  final Process _process;
  final StreamController<DaemonEvent> _events = StreamController<DaemonEvent>.broadcast();
  final StreamController<String> _rawOutput = StreamController<String>.broadcast();

  Stream<DaemonEvent> get events => _events.stream;

  /// Plain-text lines (build tool chatter, stack traces on failure) for an
  /// optional "show details" panel - never shown by default.
  Stream<String> get rawOutput => _rawOutput.stream;

  String? _wsUri;
  String? get vmServiceWsUri => _wsUri;

  bool _stopped = false;

  static Future<FlutterRunSession> start({
    required String flutterExecutable,
    required String projectRoot,
    required String deviceId,
    Map<String, String>? environment,
  }) async {
    final Process process = await Process.start(
      flutterExecutable,
      <String>['run', '--track-widget-creation', '--machine', '-d', deviceId],
      workingDirectory: projectRoot,
      environment: environment,
    );
    final FlutterRunSession session = FlutterRunSession._(process);
    session._listen();
    return session;
  }

  void _listen() {
    _process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen(_handleLine);
    _process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen(_rawOutput.add);
    unawaited(
      _process.exitCode.then((int code) {
        if (!_stopped) {
          _events.add(DaemonEvent('process.exit', <String, Object?>{'code': code}));
        }
        _events.close();
        _rawOutput.close();
      }),
    );
  }

  void _handleLine(String line) {
    final String trimmed = line.trim();
    if (trimmed.startsWith('[{') && trimmed.endsWith('}]')) {
      try {
        final List<dynamic> decoded = jsonDecode(trimmed) as List<dynamic>;
        for (final dynamic item in decoded) {
          final Map<String, dynamic> map = (item as Map<String, dynamic>);
          final String name = map['event'] as String;
          final Map<String, Object?> params =
              (map['params'] as Map<String, dynamic>?)?.cast<String, Object?>() ?? <String, Object?>{};
          if (name == 'app.debugPort') _wsUri = params['wsUri'] as String?;
          _events.add(DaemonEvent(name, params));
        }
        return;
      } catch (_) {
        // Fall through - not actually a daemon event line, treat as text.
      }
    }
    _rawOutput.add(line);
  }

  /// Ends the session. Flutter's daemon protocol has a graceful
  /// `app.stop` request, but a SIGTERM is simpler and reliable enough here
  /// (equivalent to a user hitting Ctrl+C on `flutter run`) - the app
  /// keeps running on the device, this just ends the dev session.
  Future<void> stop() async {
    _stopped = true;
    _process.kill(ProcessSignal.sigterm);
    await _process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () {
      _process.kill(ProcessSignal.sigkill);
      return -1;
    });
  }
}
