import 'dart:async';
import 'dart:io';

import 'package:design_qa/companion_api.dart';
import 'package:flutter/foundation.dart';

import 'process/daemon_event.dart';
import 'process/device_discovery.dart';
import 'process/flutter_run_session.dart';
import 'process/flutter_toolchain.dart';
import 'session/edit_poller.dart';
import 'session/vm_connection.dart';

enum Stage {
  pickProject,
  scanningSetup,
  reviewSetup,
  applyingSetup,
  pickingDevice,
  launching,
  running,
  error,
}

/// Drives the whole companion flow. One controller, one linear state
/// machine - the UI just renders whatever `stage` currently is. Wraps
/// design_qa's plain-Dart setup/export logic (`companion_api.dart`) with
/// process orchestration (`flutter run --machine`, device discovery, VM
/// service polling) so none of that shows up as terminal output to the
/// person using the app.
class CompanionController extends ChangeNotifier {
  Stage stage = Stage.pickProject;
  String? projectRoot;
  String errorMessage = '';
  String errorDetail = '';

  FlutterToolchain? _toolchain;
  SetupPlanner? _planner;
  SetupPlan? plan;

  List<DeviceInfo> devices = <DeviceInfo>[];
  DeviceInfo? selectedDevice;
  Timer? _deviceTimer;

  List<String> progressMessages = <String>[];
  FlutterRunSession? _session;
  final List<String> _rawLog = <String>[];
  String get rawLog => _rawLog.join('\n');

  VmConnection? _vmConnection;
  Timer? _pollTimer;
  List<EditRecord> edits = <EditRecord>[];

  ExportResult? lastExport;

  Future<void> pickProject(String path) async {
    projectRoot = path;
    stage = Stage.scanningSetup;
    errorMessage = '';
    notifyListeners();

    _toolchain ??= await FlutterToolchain.locate();
    if (_toolchain == null) {
      _fail(
        "Couldn't find Flutter on this Mac.",
        'Make sure Flutter is installed and try again.',
      );
      return;
    }

    _planner = SetupPlanner(path);
    if (!_planner!.looksLikeFlutterProject) {
      _fail(
        "That doesn't look like a Flutter app folder.",
        'Pick the folder that directly contains pubspec.yaml.',
      );
      return;
    }

    plan = await _planner!.plan();
    stage = Stage.reviewSetup;
    notifyListeners();
  }

  Future<void> pickEntryPoint(String path) async {
    if (_planner == null) return;
    plan = await _planner!.plan(entryPointPathOverride: path);
    notifyListeners();
  }

  Future<void> applySetupAndContinue({required bool applyWrap}) async {
    if (_planner == null || plan == null || _toolchain == null) return;
    stage = Stage.applyingSetup;
    progressMessages = <String>['Setting things up...'];
    notifyListeners();

    if (applyWrap) await _planner!.applyWrap(plan!);
    await _planner!.applyConfig(plan!);
    await _planner!.applyPubspecAsset(plan!);

    progressMessages = <String>['Getting your app ready (this can take a minute)...'];
    notifyListeners();
    final ProcessResult pubGet = await Process.run(
      _toolchain!.flutterPath,
      <String>['pub', 'get'],
      workingDirectory: projectRoot,
      environment: _toolchain!.environment,
    );
    if (pubGet.exitCode != 0) {
      _fail("Couldn't get your app's packages ready.", '${pubGet.stdout}\n${pubGet.stderr}');
      return;
    }

    stage = Stage.pickingDevice;
    notifyListeners();
    _startDevicePolling();
  }

  void _startDevicePolling() {
    _deviceTimer?.cancel();
    unawaited(_refreshDevices());
    _deviceTimer = Timer.periodic(const Duration(seconds: 2), (_) => _refreshDevices());
  }

  Future<void> _refreshDevices() async {
    if (_toolchain == null) return;
    final List<DeviceInfo> found =
        await DeviceDiscovery(_toolchain!.flutterPath, environment: _toolchain!.environment).list();
    devices = found;
    notifyListeners();
  }

  Future<void> launchOn(DeviceInfo device) async {
    if (_toolchain == null || projectRoot == null) return;
    // A double-click (or any repeat tap before the screen has swapped away)
    // must not start a second `flutter run` against the same project - two
    // concurrent builds fight over the same Xcode build database and both
    // fail. This check runs before any `await`, so it sees the stage the
    // *first* call already set synchronously below, even if both calls
    // land in the same event-loop turn.
    if (stage == Stage.launching || stage == Stage.running) return;

    _deviceTimer?.cancel();
    selectedDevice = device;
    stage = Stage.launching;
    progressMessages = <String>['Starting your app on ${device.name}...'];
    _rawLog.clear();
    notifyListeners();

    _session = await FlutterRunSession.start(
      flutterExecutable: _toolchain!.flutterPath,
      projectRoot: projectRoot!,
      deviceId: device.id,
      environment: _toolchain!.environment,
    );
    _session!.events.listen(_handleDaemonEvent);
    _session!.rawOutput.listen((String line) {
      _rawLog.add(line);
      if (_rawLog.length > 400) _rawLog.removeAt(0);
    });
  }

  void _handleDaemonEvent(DaemonEvent event) {
    switch (event.name) {
      case 'app.progress':
        final bool finished = event['finished'] as bool? ?? false;
        final String? message = event['message'] as String?;
        if (!finished && message != null) {
          progressMessages = <String>[...progressMessages, message];
          notifyListeners();
        }
      case 'app.debugPort':
        progressMessages = <String>[...progressMessages, 'Connecting the review tool...'];
        notifyListeners();
      case 'app.started':
        unawaited(_onAppStarted());
      case 'process.exit':
        if (stage != Stage.running) {
          final bool isPhysicalDevice = selectedDevice?.emulator == false &&
              selectedDevice!.targetPlatform.startsWith('android');
          _fail(
            'Your app stopped before it finished starting.',
            '${isPhysicalDevice ? 'Check that your phone is still plugged in and unlocked, then try again.' : 'See the details below for what went wrong.'}\n\n$rawLog',
          );
        }
    }
  }

  Future<void> _onAppStarted() async {
    stage = Stage.running;
    notifyListeners();
    final String? wsUri = _session!.vmServiceWsUri;
    if (wsUri == null) return;
    _vmConnection = await VmConnection.connect(wsUri);
    _pollTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) => _pollEdits());
  }

  Future<void> _pollEdits() async {
    final VmConnection? connection = _vmConnection;
    if (connection == null) return;
    try {
      final List<EditRecord> result = await EditPoller(connection).poll();
      edits = result;
      notifyListeners();
    } catch (_) {
      // Transient - the app may be mid hot-reload. Retry next tick.
    }
  }

  Future<void> saveChanges() async {
    if (projectRoot == null) return;
    final Map<EditKey, EditRecord> byKey = <EditKey, EditRecord>{
      for (final EditRecord e in edits) e.key: e,
    };
    lastExport = await exportToDisk(projectRoot: projectRoot!, edits: byKey);
    notifyListeners();
  }

  Future<void> stopSession() async {
    _pollTimer?.cancel();
    await _vmConnection?.dispose();
    _vmConnection = null;
    await _session?.stop();
    _session = null;
    edits = <EditRecord>[];
    lastExport = null;
    stage = Stage.pickingDevice;
    notifyListeners();
    _startDevicePolling();
  }

  void _fail(String message, String detail) {
    errorMessage = message;
    errorDetail = detail;
    stage = Stage.error;
    notifyListeners();
  }

  void reset() {
    _deviceTimer?.cancel();
    _pollTimer?.cancel();
    unawaited(_vmConnection?.dispose());
    unawaited(_session?.stop());
    _session = null;
    _vmConnection = null;
    projectRoot = null;
    plan = null;
    devices = <DeviceInfo>[];
    selectedDevice = null;
    edits = <EditRecord>[];
    lastExport = null;
    stage = Stage.pickProject;
    notifyListeners();
  }

  @override
  void dispose() {
    _deviceTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
