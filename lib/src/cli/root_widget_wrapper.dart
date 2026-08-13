import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:collection/collection.dart';

sealed class WrapOutcome {
  const WrapOutcome();
}

class WrapAlreadyDone extends WrapOutcome {
  const WrapAlreadyDone();
}

class WrapApplied extends WrapOutcome {
  const WrapApplied(this.newSource);
  final String newSource;
}

/// `runApp(...)` couldn't be found/wrapped unambiguously - never guess at
/// unfamiliar control flow (conditional bootstrapping, `runZonedGuarded`,
/// multiple `runApp` calls, a parse failure). [snippet] is what the
/// developer can paste in by hand instead.
class WrapNeedsManualEdit extends WrapOutcome {
  const WrapNeedsManualEdit(this.reason, this.snippet);
  final String reason;
  final String snippet;
}

/// Wraps whatever is already passed to `runApp` with `DesignQA.wrap(child:
/// ...)`, touching nothing else - it never looks inside the existing
/// expression, so it can't misunderstand `ProviderScope`, `EasyLocalization`,
/// or any other wrapper already there.
class RootWidgetWrapper {
  const RootWidgetWrapper();

  WrapOutcome wrap(String source) {
    final ParseStringResult parsed = parseString(content: source, throwIfDiagnostics: false);

    FunctionDeclaration? main;
    for (final CompilationUnitMember member in parsed.unit.declarations) {
      if (member is FunctionDeclaration && member.name.lexeme == 'main') {
        main = member;
        break;
      }
    }
    if (main == null) {
      return const WrapNeedsManualEdit(
        'No top-level main() found in this file.',
        'runApp(DesignQA.wrap(child: /* your root widget */));',
      );
    }

    final List<MethodInvocation> runAppCalls = <MethodInvocation>[];
    main.accept(
      _Visitor((MethodInvocation node) {
        if (node.methodName.name == 'runApp') runAppCalls.add(node);
      }),
    );

    if (runAppCalls.isEmpty) {
      return const WrapNeedsManualEdit(
        'No runApp(...) call found in main() - this project may bootstrap indirectly '
        '(runZonedGuarded, an async initializer, a custom bootstrap function, ...).',
        'runApp(DesignQA.wrap(child: /* your root widget */));',
      );
    }
    if (runAppCalls.length > 1) {
      return WrapNeedsManualEdit(
        'Found ${runAppCalls.length} runApp(...) calls in main() - not obvious which one is the '
        'real entry point.',
        'Wrap the one that actually runs: runApp(DesignQA.wrap(child: /* your root widget */));',
      );
    }

    final MethodInvocation call = runAppCalls.single;
    if (call.argumentList.arguments.length != 1) {
      return const WrapNeedsManualEdit(
        'runApp(...) call has an unexpected argument shape.',
        'runApp(DesignQA.wrap(child: /* your root widget */));',
      );
    }
    final Expression arg = call.argumentList.arguments.single;

    if (arg is MethodInvocation &&
        arg.methodName.name == 'wrap' &&
        arg.target?.toSource() == 'DesignQA') {
      return const WrapAlreadyDone();
    }

    final String original = arg.toSource();
    final String replacement = 'DesignQA.wrap(child: $original)';
    String newSource = source.replaceRange(arg.offset, arg.end, replacement);
    newSource = _ensureImport(newSource);
    return WrapApplied(newSource);
  }

  String _ensureImport(String source) {
    const String import = "import 'package:design_qa/design_qa.dart';";
    if (source.contains(import)) return source;

    final ParseStringResult parsed = parseString(content: source, throwIfDiagnostics: false);
    final List<ImportDirective> imports =
        parsed.unit.directives.whereType<ImportDirective>().toList();
    if (imports.isEmpty) {
      // No imports at all - insert after the library directive, if any,
      // else at the very top of the file.
      final LibraryDirective? lib =
          parsed.unit.directives.whereType<LibraryDirective>().firstOrNull;
      final int offset = lib != null ? lib.end : 0;
      return source.replaceRange(offset, offset, '${lib != null ? '\n' : ''}$import\n');
    }
    final ImportDirective last = imports.last;
    return source.replaceRange(last.end, last.end, '\n$import');
  }
}

class _Visitor extends RecursiveAstVisitor<void> {
  _Visitor(this.onCall);
  final void Function(MethodInvocation) onCall;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    onCall(node);
    super.visitMethodInvocation(node);
  }
}
