import 'dart:io';

import '../core/edit_key.dart';
import '../core/edit_record.dart';
import 'changelog_writer.dart';
import 'diff_writer.dart';
import 'source_patcher.dart';

class ExportResult {
  const ExportResult({required this.filesWritten, required this.notes});
  final List<String> filesWritten;
  final List<String> notes;
  int get editedFileCount => filesWritten.where((String f) => f.endsWith('.patch')).length;
}

/// Read/patch/diff/write, given real edit records and a real project root
/// this process can see on disk. Pure Dart - shared by the in-app export
/// path (`lib/src/export/exporter.dart`, macOS desktop) and the host-side
/// `dart run design_qa:export` CLI (`bin/export.dart`), the only path that
/// works from an Android emulator or physical device, which has no access
/// to the host filesystem at all. See exporter.dart for why the split.
Future<ExportResult> exportToDisk({
  required String projectRoot,
  required Map<EditKey, EditRecord> edits,
}) async {
  if (edits.isEmpty) return const ExportResult(filesWritten: <String>[], notes: <String>[]);

  final Map<String, List<EditRecord>> byFile = <String, List<EditRecord>>{};
  for (final EditRecord r in edits.values) {
    byFile.putIfAbsent(r.key.file, () => <EditRecord>[]).add(r);
  }

  final Directory outDir = Directory('$projectRoot/design_qa_out');
  await outDir.create(recursive: true);

  const SourcePatcher patcher = SourcePatcher();
  final List<String> filesWritten = <String>[];
  final List<String> notes = <String>[];

  for (final MapEntry<String, List<EditRecord>> entry in byFile.entries) {
    final File source = File(entry.key);
    if (!source.existsSync()) {
      notes.add('${entry.key}: file no longer exists - skipped.');
      continue;
    }
    final String original = await source.readAsString();
    final PatchOutcome outcome = patcher.patch(original, entry.value);
    notes.addAll(outcome.notes);
    if (outcome.editCount == 0) continue;

    final String relative =
        entry.key.startsWith(projectRoot) ? entry.key.substring(projectRoot.length + 1) : entry.key;
    final String diff = unifiedDiff(path: relative, before: original, after: outcome.patchedSource);
    final String patchFileName = relative.replaceAll('/', '_').replaceAll(r'\', '_');
    final File patchFile = File('${outDir.path}/$patchFileName.patch');
    await patchFile.writeAsString(diff);
    filesWritten.add(patchFile.path);
  }

  final File changelog = File('${outDir.path}/CHANGELOG.md');
  await changelog.writeAsString(buildChangelog(byFile, projectRoot: projectRoot));
  filesWritten.add(changelog.path);

  return ExportResult(filesWritten: filesWritten, notes: notes);
}
