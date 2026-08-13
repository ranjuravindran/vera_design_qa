import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

import '../analyzer_support/constructor_call.dart';

/// Finds named routes two ways: a `MaterialApp(routes: {...})` map literal
/// (or `CupertinoApp`'s), and any `GoRoute(path: '...')` call project-wide
/// (covers nested/sub-routes without needing to understand GoRouter's
/// route tree shape - a flat list is all the route jumper needs).
/// `onGenerateRoute`/`redirect`-built routes aren't discoverable statically
/// and are skipped - add those to `design_qa.yaml` by hand.
class RouteScanner {
  const RouteScanner(this.projectRoot);
  final String projectRoot;

  Future<List<String>> scan() async {
    final Directory libDir = Directory(p.join(projectRoot, 'lib'));
    if (!await libDir.exists()) return const <String>[];

    final Set<String> routes = <String>{};
    await for (final FileSystemEntity entity in libDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final String content = await entity.readAsString();
      if (!content.contains('routes') && !content.contains('GoRoute')) continue;

      final ParseStringResult parsed = parseString(content: content, throwIfDiagnostics: false);
      parsed.unit.accept(ConstructorCallVisitor((ConstructorCall call) => _visit(call, routes)));
    }
    final List<String> sorted = routes.toList()..sort();
    return sorted;
  }

  void _visit(ConstructorCall call, Set<String> routes) {
    if (call.typeName == 'MaterialApp' || call.typeName == 'CupertinoApp') {
      for (final Expression arg in call.arguments.arguments) {
        if (arg is NamedExpression && arg.name.label.name == 'routes' && arg.expression is SetOrMapLiteral) {
          for (final CollectionElement el in (arg.expression as SetOrMapLiteral).elements) {
            if (el is MapLiteralEntry) {
              final String? key = _stringLiteralValue(el.key);
              if (key != null) routes.add(key);
            }
          }
        }
      }
    } else if (call.typeName == 'GoRoute') {
      for (final Expression arg in call.arguments.arguments) {
        if (arg is NamedExpression && arg.name.label.name == 'path') {
          final String? path = _stringLiteralValue(arg.expression);
          if (path != null) routes.add(path);
        }
      }
    }
  }

  String? _stringLiteralValue(Expression expr) => expr is SimpleStringLiteral ? expr.value : null;
}
