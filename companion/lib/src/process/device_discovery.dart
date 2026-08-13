import 'dart:convert';
import 'dart:io';

class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.name,
    required this.isSupported,
    required this.emulator,
    required this.targetPlatform,
  });

  final String id;
  final String name;
  final bool isSupported;
  final bool emulator;
  final String targetPlatform;

  bool get isAndroidPhysicalDevice => targetPlatform.startsWith('android') && !emulator;

  static DeviceInfo fromJson(Map<String, dynamic> json) => DeviceInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        isSupported: json['isSupported'] as bool? ?? true,
        emulator: json['emulator'] as bool? ?? false,
        targetPlatform: json['targetPlatform'] as String? ?? '',
      );
}

/// Wraps `flutter devices --machine` - a one-shot JSON query, unlike the
/// long-lived daemon session in flutter_run_session.dart.
class DeviceDiscovery {
  const DeviceDiscovery(this.flutterPath, {this.environment});
  final String flutterPath;
  final Map<String, String>? environment;

  Future<List<DeviceInfo>> list() async {
    final ProcessResult result = await Process.run(
      flutterPath,
      <String>['devices', '--machine'],
      environment: environment,
    );
    if (result.exitCode != 0) return const <DeviceInfo>[];
    try {
      final List<dynamic> decoded = jsonDecode(result.stdout as String) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map(DeviceInfo.fromJson)
          .where((DeviceInfo d) => d.isSupported)
          .toList();
    } catch (_) {
      return const <DeviceInfo>[];
    }
  }
}
