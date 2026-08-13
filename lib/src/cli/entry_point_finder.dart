import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

class EntryPointCandidate {
  const EntryPointCandidate(this.path);
  final String path;
}

/// Finds every top-level `main()` function under `lib/`. `lib/main.dart` is
/// checked first since it's the overwhelmingly common case and skips
/// scanning the whole tree; multi-flavor projects (`main_dev.dart`,
/// `main_prod.dart`, ...) fall through to a full scan so `init` can ask
/// which one to wrap instead of guessing.
class EntryPointFinder {
  const EntryPointFinder(this.projectRoot);
  final String projectRoot;

  Future<List<EntryPointCandidate>> find() async {
    final File defaultEntry = File(p.join(projectRoot, 'lib', 'main.dart'));
    if (await defaultEntry.exists() && await _hasTopLevelMain(defaultEntry)) {
      return <EntryPointCandidate>[EntryPointCandidate(defaultEntry.path)];
    }

    final Directory libDir = Directory(p.join(projectRoot, 'lib'));
    if (!await libDir.exists()) return const <EntryPointCandidate>[];

    final List<EntryPointCandidate> candidates = <EntryPointCandidate>[];
    await for (final FileSystemEntity entity in libDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (await _hasTopLevelMain(entity)) candidates.add(EntryPointCandidate(entity.path));
    }
    return candidates;
  }

  Future<bool> _hasTopLevelMain(File file) async {
    final String content = await file.readAsString();
    final ParseStringResult parsed = parseString(content: content, throwIfDiagnostics: false);
    for (final CompilationUnitMember member in parsed.unit.declarations) {
      if (member is FunctionDeclaration && member.name.lexeme == 'main') return true;
    }
    return false;
  }
}
