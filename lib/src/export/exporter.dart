import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/edit_record.dart';
import '../core/edit_session.dart';
import 'export_pipeline.dart';

export 'export_pipeline.dart' show ExportResult, exportToDisk;

/// In-app entry point for the pill's export button.
///
/// Reading source files and writing `design_qa_out/` only works when this
/// process can see the project's own filesystem - true for `flutter run -d
/// macos`, never true for an Android emulator or physical device (no
/// access to the host machine's disk at all, full stop). On a platform
/// where the direct write fails, this registers a VM service extension and
/// tells the designer to run `dart run design_qa:export
/// --vm-service-uri=URI` from their terminal instead - the same protocol
/// DevTools itself uses to reach an app on any device. See bin/export.dart
/// and README.md.
class Exporter {
  const Exporter();

  static bool _extensionRegistered = false;

  static void registerVmServiceExtension() {
    if (_extensionRegistered || !kDebugMode) return;
    _extensionRegistered = true;
    developer.registerExtension(
      'ext.design_qa.session',
      (String method, Map<String, String> params) async {
        return developer.ServiceExtensionResponse.result(jsonEncode(sessionToJson()));
      },
    );
  }

  static Map<String, Object?> sessionToJson() => <String, Object?>{
        'edits': <Map<String, Object?>>[for (final EditRecord r in EditSession.instance.edits.values) r.toJson()],
      };

  Future<ExportResult> export() async {
    registerVmServiceExtension();
    if (EditSession.instance.isEmpty) {
      return const ExportResult(filesWritten: <String>[], notes: <String>[]);
    }
    try {
      return await exportToDisk(projectRoot: Directory.current.path, edits: EditSession.instance.edits);
    } on FileSystemException {
      debugPrint(
        'design_qa: no host filesystem access from this process (this is normal on an Android '
        "emulator or physical device). Run 'dart run design_qa:export --vm-service-uri=<uri>' from "
        "your terminal - use the URI 'flutter run' printed on startup - to write the patch on your "
        'machine instead.',
      );
      return const ExportResult(
        filesWritten: <String>[],
        notes: <String>[
          "No local filesystem access - run 'dart run design_qa:export --vm-service-uri=<uri>' instead.",
        ],
      );
    }
  }
}
