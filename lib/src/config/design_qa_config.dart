import 'package:collection/collection.dart';

/// In-memory model of `design_qa.yaml`. See doc/design_qa_yaml_reference.md
/// for every key and its default.
class DesignQAConfig {
  const DesignQAConfig({
    required this.tokens,
    required this.routes,
    required this.reference,
    required this.lint,
  });

  factory DesignQAConfig.empty() => DesignQAConfig(
        tokens: TokenSet.empty(),
        routes: const <RouteEntry>[],
        reference: const ReferenceConfig(),
        lint: const LintConfig(),
      );

  final TokenSet tokens;
  final List<RouteEntry> routes;
  final ReferenceConfig reference;
  final LintConfig lint;
}

class TokenSet {
  const TokenSet({
    required this.source,
    required this.colors,
    required this.spacing,
    required this.radius,
    required this.typography,
  });

  factory TokenSet.empty() => const TokenSet(
        source: null,
        colors: <String, int>{},
        spacing: <String, double>{},
        radius: <String, double>{},
        typography: <String, TypeScaleToken>{},
      );

  /// File design_qa:init discovered these from, purely informational.
  final String? source;

  /// name -> ARGB int (0xAARRGGBB)
  final Map<String, int> colors;

  /// name -> logical pixels
  final Map<String, double> spacing;
  final Map<String, double> radius;
  final Map<String, TypeScaleToken> typography;

  bool get isEmpty =>
      colors.isEmpty && spacing.isEmpty && radius.isEmpty && typography.isEmpty;

  /// Nearest spacing token to [value], or null if none is within [tolerance].
  MapEntry<String, double>? nearestSpacing(double value, {double tolerance = 0}) =>
      _nearest(spacing, value, tolerance);

  MapEntry<String, double>? nearestRadius(double value, {double tolerance = 0}) =>
      _nearest(radius, value, tolerance);

  MapEntry<String, double>? _nearest(
    Map<String, double> table,
    double value,
    double tolerance,
  ) {
    if (table.isEmpty) return null;
    final MapEntry<String, double> closest =
        table.entries.sorted((a, b) => (a.value - value).abs().compareTo((b.value - value).abs())).first;
    if ((closest.value - value).abs() <= tolerance) return null; // already a match, nothing to flag
    return closest;
  }

  bool hasExactColor(int argb) => colors.values.contains(argb);

  /// Nearest token color by channel distance, for the "16 -> spacing.md"
  /// style one-tap lint fix applied to color too. Returns null once the
  /// palette is empty - there's nothing to suggest.
  MapEntry<String, int>? nearestColor(int argb) {
    if (colors.isEmpty) return null;
    int distance(int a, int b) {
      final int da = ((a >> 24) & 0xFF) - ((b >> 24) & 0xFF);
      final int dr = ((a >> 16) & 0xFF) - ((b >> 16) & 0xFF);
      final int dg = ((a >> 8) & 0xFF) - ((b >> 8) & 0xFF);
      final int db = (a & 0xFF) - (b & 0xFF);
      return da * da + dr * dr + dg * dg + db * db;
    }

    return colors.entries.reduce(
      (MapEntry<String, int> a, MapEntry<String, int> b) =>
          distance(a.value, argb) <= distance(b.value, argb) ? a : b,
    );
  }
}

class TypeScaleToken {
  const TypeScaleToken({
    required this.fontSize,
    required this.fontWeight,
    required this.letterSpacing,
    required this.lineHeight,
  });

  final double fontSize;
  final int fontWeight; // 100-900
  final double letterSpacing;
  final double lineHeight;
}

class RouteEntry {
  const RouteEntry({required this.name, this.mockArgs = const <String, Object?>{}});

  final String name;
  final Map<String, Object?> mockArgs;
}

class ReferenceConfig {
  const ReferenceConfig({this.opacity = 0.5, this.blend = ReferenceBlend.difference});

  final double opacity;
  final ReferenceBlend blend;
}

enum ReferenceBlend { off, opacity, difference }

class LintConfig {
  const LintConfig({this.enabled = true, this.tolerance = 0.0});

  final bool enabled;
  final double tolerance;
}
