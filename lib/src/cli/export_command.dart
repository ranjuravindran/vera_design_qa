import 'dart:io';

import 'package:collection/collection.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import '../core/edit_key.dart';
import '../core/edit_record.dart';
import '../export/export_pipeline.dart';

/// Host-side half of exporting from a device with no filesystem access of
/// its own (an Android emulator or physical device - see
/// lib/src/export/exporter.dart for why this exists at all). Connects to
/// the already-running app over the same VM service protocol DevTools
/// uses, reads back the edit session via the `ext.design_qa.session`
/// extension `DesignQA.wrap` registers at startup, and then runs the exact
/// same read/patch/diff/write pipeline the in-app path uses - the only
/// difference is which machine's disk it's writing to.
class ExportCommand {
  const ExportCommand({required this.projectRoot, required this.vmServiceUri});
  final String projectRoot;
  final String vmServiceUri;

  Future<int> run() async {
    final Uri wsUri = _toWebSocket(Uri.parse(vmServiceUri));
    stdout.writeln('Connecting to $wsUri ...');
    final VmService service = await vmServiceConnectUri(wsUri.toString());

    try {
      final VM vm = await service.getVM();
      final IsolateRef? isolateRef = vm.isolates?.firstOrNull;
      if (isolateRef?.id == null) {
        stderr.writeln('No running isolate found at that VM service URI.');
        return 1;
      }

      final Response response = await service.callServiceExtension(
        'ext.design_qa.session',
        isolateId: isolateRef!.id,
      );
      final List<dynamic> rawEdits = (response.json?['edits'] as List<dynamic>?) ?? <dynamic>[];
      if (rawEdits.isEmpty) {
        stdout.writeln('No edits recorded in the running app yet.');
        return 0;
      }

      final Map<EditKey, EditRecord> edits = <EditKey, EditRecord>{
        for (final EditRecord r in rawEdits.map((dynamic e) => EditRecord.fromJson((e as Map).cast<String, Object?>())))
          r.key: r,
      };

      final ExportResult result = await exportToDisk(projectRoot: projectRoot, edits: edits);
      for (final String note in result.notes) {
        stdout.writeln('note: $note');
      }
      if (result.filesWritten.isEmpty) {
        stdout.writeln('Nothing was written.');
      } else {
        stdout.writeln('Wrote:');
        for (final String f in result.filesWritten) {
          stdout.writeln('  $f');
        }
      }
      return 0;
    } finally {
      await service.dispose();
    }
  }

  Uri _toWebSocket(Uri httpUri) {
    if (httpUri.scheme == 'ws' || httpUri.scheme == 'wss') return httpUri;
    final String scheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    final String path = httpUri.path.endsWith('/') ? '${httpUri.path}ws' : '${httpUri.path}/ws';
    return httpUri.replace(scheme: scheme, path: path);
  }
}
