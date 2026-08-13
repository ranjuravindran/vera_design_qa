import 'package:yaml/yaml.dart';

/// Registers `design_qa.yaml` as a Flutter asset.
///
/// Necessary because the overlay loads it via `rootBundle.loadString` at
/// runtime so the same code path works on Android/iOS devices and
/// emulators, which have no access to the host project directory at all -
/// only bundled assets travel with the app. A plain `dart:io` read only
/// ever works on desktop.
///
/// Edits the raw text rather than round-tripping the whole pubspec through
/// a YAML serializer, which would risk reformatting or dropping comments in
/// a file far more sensitive to mangle than design_qa.yaml itself.
class PubspecAssetRegistrar {
  const PubspecAssetRegistrar();

  static const String _assetLine = 'design_qa.yaml';

  /// Returns null if the asset is already registered (nothing to change).
  String? ensureRegistered(String pubspecYaml) {
    final dynamic doc = loadYaml(pubspecYaml);
    if (doc is YamlMap) {
      final dynamic flutter = doc['flutter'];
      if (flutter is YamlMap) {
        final dynamic assets = flutter['assets'];
        if (assets is YamlList && assets.any((dynamic a) => a.toString() == _assetLine)) {
          return null;
        }
      }
    }

    final List<String> lines = pubspecYaml.split('\n');
    final int flutterIdx = lines.indexWhere((String l) => RegExp(r'^flutter:\s*$').hasMatch(l));

    if (flutterIdx == -1) {
      final String sep = pubspecYaml.endsWith('\n') ? '' : '\n';
      return '$pubspecYaml$sep\nflutter:\n  assets:\n    - $_assetLine\n';
    }

    final int assetsIdx = lines.indexWhere(
      (String l) => RegExp(r'^\s{2}assets:\s*$').hasMatch(l),
      flutterIdx + 1,
    );
    if (assetsIdx == -1 || _blockEndsBefore(lines, flutterIdx, assetsIdx)) {
      lines.insert(flutterIdx + 1, '  assets:\n    - $_assetLine');
      return lines.join('\n');
    }

    lines.insert(assetsIdx + 1, '    - $_assetLine');
    return lines.join('\n');
  }

  /// True if the `flutter:` block ends before reaching an `assets:` match
  /// found further down the file (i.e. that match belongs to a different,
  /// unrelated top-level key, not this `flutter:` block).
  bool _blockEndsBefore(List<String> lines, int flutterIdx, int candidateAssetsIdx) {
    for (int i = flutterIdx + 1; i < candidateAssetsIdx; i++) {
      final String line = lines[i];
      if (line.trim().isEmpty) continue;
      if (!line.startsWith(' ')) return true; // back to top-level, flutter: block ended
    }
    return false;
  }
}
