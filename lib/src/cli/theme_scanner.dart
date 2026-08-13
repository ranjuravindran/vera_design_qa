import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

import '../analyzer_support/constructor_call.dart';

class ScannedTokens {
  const ScannedTokens({
    required this.source,
    required this.colors,
    required this.spacing,
    required this.radius,
  });

  final String? source;
  final Map<String, String> colors; // name -> '#AARRGGBB'
  final Map<String, double> spacing;
  final Map<String, double> radius;

  bool get isEmpty => colors.isEmpty && spacing.isEmpty && radius.isEmpty;
}

/// Best-effort discovery of an existing design-token source, for
/// pre-filling `design_qa.yaml` on `init`.
///
/// Recognizes one common, concrete pattern: a top-level class made of
/// `static const` `Color`/`double`/`int` fields (`class AppColors { static
/// const primary = Color(0xFFxxxxxx); }`, `class AppSpacing { static const
/// md = 16.0; }`) - the shape most hand-rolled Flutter design systems
/// actually use. `ThemeData`/`ColorScheme.fromSeed`-based theming and
/// external JSON/YAML token files aren't auto-detected yet; both still work
/// fine with design_qa, they just need their tokens added to the generated
/// YAML by hand. See doc/design_qa_yaml_reference.md.
class ThemeScanner {
  const ThemeScanner(this.projectRoot);
  final String projectRoot;

  Future<ScannedTokens> scan() async {
    final Directory libDir = Directory(p.join(projectRoot, 'lib'));
    if (!await libDir.exists()) return _empty();

    final Map<String, String> colors = <String, String>{};
    final Map<String, double> spacing = <String, double>{};
    final Map<String, double> radius = <String, double>{};
    String? source;

    await for (final FileSystemEntity entity in libDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final String content = await entity.readAsString();
      if (!_looksRelevant(content)) continue;

      final ParseStringResult parsed = parseString(content: content, throwIfDiagnostics: false);
      for (final CompilationUnitMember decl in parsed.unit.declarations) {
        if (decl is! ClassDeclaration) continue;
        if (!_looksLikeTokenClass(decl.namePart.typeName.lexeme)) continue;
        bool foundAny = false;
        for (final ClassMember member in decl.body.members) {
          if (member is! FieldDeclaration || !member.isStatic) continue;
          for (final VariableDeclaration v in member.fields.variables) {
            final Expression? init = v.initializer;
            if (init == null) continue;
            final String? colorHex = _asColorHex(init);
            final double? number = _asNumber(init);
            if (colorHex != null) {
              colors[v.name.lexeme] = colorHex;
              foundAny = true;
            } else if (number != null) {
              (v.name.lexeme.toLowerCase().contains('radius') ? radius : spacing)[v.name.lexeme] = number;
              foundAny = true;
            }
          }
        }
        if (foundAny) source ??= p.relative(entity.path, from: projectRoot);
      }
    }

    return ScannedTokens(source: source, colors: colors, spacing: spacing, radius: radius);
  }

  ScannedTokens _empty() =>
      const ScannedTokens(source: null, colors: <String, String>{}, spacing: <String, double>{}, radius: <String, double>{});

  bool _looksRelevant(String content) =>
      content.contains('Color') || content.contains('EdgeInsets') || content.contains('static const');

  bool _looksLikeTokenClass(String name) {
    final String lower = name.toLowerCase();
    return lower.contains('color') ||
        lower.contains('palette') ||
        lower.contains('token') ||
        lower.contains('spacing') ||
        lower.contains('radius') ||
        lower.contains('theme');
  }

  String? _asColorHex(Expression expr) {
    final ConstructorCall? call = ConstructorCall.from(expr);
    if (call == null || call.typeName != 'Color') return null;
    if (call.arguments.arguments.length != 1) return null;
    final Expression arg = call.arguments.arguments.single;
    if (arg is! IntegerLiteral || arg.value == null) return null;
    final String hex = arg.value!.toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(hex.length - 8).toUpperCase()}';
  }

  double? _asNumber(Expression expr) {
    if (expr is IntegerLiteral) return expr.value?.toDouble();
    if (expr is DoubleLiteral) return expr.value;
    if (expr is PrefixExpression && expr.operator.lexeme == '-') {
      final double? inner = _asNumber(expr.operand);
      return inner == null ? null : -inner;
    }
    return null;
  }
}
