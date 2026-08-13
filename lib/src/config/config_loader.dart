import 'dart:io';

import 'package:yaml/yaml.dart';

import 'design_qa_config.dart';

/// Reads and parses `design_qa.yaml`. Missing file or missing sections all
/// degrade to empty/default values rather than throwing - the overlay must
/// still run (inspect + live edit + export) even with no config at all,
/// just without route jumping or token linting.
class ConfigLoader {
  const ConfigLoader();

  DesignQAConfig loadFromString(String yamlText) {
    final dynamic doc = loadYaml(yamlText);
    if (doc is! YamlMap) return DesignQAConfig.empty();
    return DesignQAConfig(
      tokens: _parseTokens(doc['tokens']),
      routes: _parseRoutes(doc['routes']),
      reference: _parseReference(doc['reference']),
      lint: _parseLint(doc['lint']),
    );
  }

  Future<DesignQAConfig> loadFromFile(String path) async {
    final File file = File(path);
    if (!await file.exists()) return DesignQAConfig.empty();
    return loadFromString(await file.readAsString());
  }

  TokenSet _parseTokens(dynamic node) {
    if (node is! YamlMap) return TokenSet.empty();
    return TokenSet(
      source: node['source'] as String?,
      colors: _parseColorMap(node['colors']),
      spacing: _parseNumMap(node['spacing']),
      radius: _parseNumMap(node['radius']),
      typography: _parseTypeScale(node['typography']),
    );
  }

  Map<String, int> _parseColorMap(dynamic node) {
    if (node is! YamlMap) return <String, int>{};
    final Map<String, int> out = <String, int>{};
    for (final MapEntry<dynamic, dynamic> e in node.entries) {
      final int? argb = _parseColor(e.value);
      if (argb != null) out[e.key.toString()] = argb;
    }
    return out;
  }

  int? _parseColor(dynamic value) {
    if (value is int) return value;
    if (value is! String) return null;
    String hex = value.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    return int.tryParse(hex, radix: 16);
  }

  Map<String, double> _parseNumMap(dynamic node) {
    if (node is! YamlMap) return <String, double>{};
    final Map<String, double> out = <String, double>{};
    for (final MapEntry<dynamic, dynamic> e in node.entries) {
      final num? n = e.value is num ? e.value as num : num.tryParse('${e.value}');
      if (n != null) out[e.key.toString()] = n.toDouble();
    }
    return out;
  }

  Map<String, TypeScaleToken> _parseTypeScale(dynamic node) {
    if (node is! YamlMap) return <String, TypeScaleToken>{};
    final Map<String, TypeScaleToken> out = <String, TypeScaleToken>{};
    for (final MapEntry<dynamic, dynamic> e in node.entries) {
      final dynamic v = e.value;
      if (v is! YamlMap) continue;
      out[e.key.toString()] = TypeScaleToken(
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 14,
        fontWeight: (v['fontWeight'] as num?)?.toInt() ?? 400,
        letterSpacing: (v['letterSpacing'] as num?)?.toDouble() ?? 0,
        lineHeight: (v['lineHeight'] as num?)?.toDouble() ?? 1.0,
      );
    }
    return out;
  }

  List<RouteEntry> _parseRoutes(dynamic node) {
    if (node is! YamlList) return <RouteEntry>[];
    final List<RouteEntry> out = <RouteEntry>[];
    for (final dynamic item in node) {
      if (item is YamlMap && item['name'] != null) {
        final dynamic mock = item['mockArgs'];
        out.add(
          RouteEntry(
            name: item['name'].toString(),
            mockArgs: mock is YamlMap
                ? mock.map((dynamic k, dynamic v) => MapEntry(k.toString(), v))
                : const <String, Object?>{},
          ),
        );
      } else if (item is String) {
        out.add(RouteEntry(name: item));
      }
    }
    return out;
  }

  ReferenceConfig _parseReference(dynamic node) {
    if (node is! YamlMap) return const ReferenceConfig();
    final String blendStr = (node['blend'] as String?) ?? 'difference';
    return ReferenceConfig(
      opacity: (node['opacity'] as num?)?.toDouble() ?? 0.5,
      blend: ReferenceBlend.values.firstWhere(
        (ReferenceBlend b) => b.name == blendStr,
        orElse: () => ReferenceBlend.difference,
      ),
    );
  }

  LintConfig _parseLint(dynamic node) {
    if (node is! YamlMap) return const LintConfig();
    return LintConfig(
      enabled: (node['enabled'] as bool?) ?? true,
      tolerance: (node['tolerance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
