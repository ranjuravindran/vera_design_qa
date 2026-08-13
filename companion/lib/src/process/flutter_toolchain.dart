import 'dart:io';

/// Finds the `flutter` executable to shell out to, and the full `PATH` it
/// (and everything it in turn shells out to - CocoaPods, adb, ...) needs.
///
/// A GUI app launched from Finder/Dock does not inherit the `PATH` a
/// terminal session builds from `.zshrc`/`.zprofile` - only a real login
/// shell sources those, and even that isn't the whole story here: on this
/// machine neither Flutter's own bin directory nor CocoaPods' turned out
/// to be on the login shell's `PATH` either (confirmed directly, not
/// assumed - see `_gemBinDirs`). So every directory this ends up needing
/// gets assembled explicitly rather than trusted to already be there, and
/// every subprocess this app spawns uses [environment] instead of the
/// default inherited one.
class FlutterToolchain {
  const FlutterToolchain._(this.flutterPath, this.environment);

  final String flutterPath;

  /// Full environment (this process's own, with `PATH` expanded) to pass
  /// to every subprocess this app spawns.
  final Map<String, String> environment;

  static const List<String> _fallbackCandidates = <String>[
    '~/development/flutter/bin/flutter',
    '/usr/local/bin/flutter',
    '/opt/homebrew/bin/flutter',
  ];

  static Future<FlutterToolchain?> locate() async {
    final String? shellPath = await _loginShellPath();
    final List<String> pathDirs = <String>[if (shellPath != null) ...shellPath.split(':')];

    String? flutterPath = shellPath == null ? null : _findOnPath('flutter', shellPath);
    flutterPath ??= _firstExistingFallback();
    if (flutterPath == null) return null;

    final String flutterDir = File(flutterPath).parent.path;
    if (!pathDirs.contains(flutterDir)) pathDirs.add(flutterDir);

    for (final String gemBin in await _gemBinDirs()) {
      if (!pathDirs.contains(gemBin)) pathDirs.add(gemBin);
    }

    final Map<String, String> env = <String, String>{
      ...Platform.environment,
      'PATH': pathDirs.join(':'),
    };
    return FlutterToolchain._(flutterPath, env);
  }

  static Future<String?> _loginShellPath() async {
    try {
      final ProcessResult result = await Process.run('/bin/zsh', <String>['-l', '-c', 'echo \$PATH']);
      final String path = (result.stdout as String).trim();
      return result.exitCode == 0 && path.isNotEmpty ? path : null;
    } catch (_) {
      return null;
    }
  }

  /// Both plausible locations for gem-installed executables (CocoaPods'
  /// `pod`, chiefly): `Gem.bindir` (correct for a system-wide install) and
  /// `Gem.user_dir/bin` (where `gem install --user-install` actually puts
  /// things - what happens whenever `sudo gem install` wasn't used, and
  /// the one that's actually right on this machine; `Gem.bindir` alone
  /// reports the wrong directory here). Returns whichever of the two
  /// actually exist.
  static Future<List<String>> _gemBinDirs() async {
    const String script = 'puts Gem.bindir; puts File.join(Gem.user_dir, %q(bin))';
    try {
      final ProcessResult result =
          await Process.run('/bin/zsh', <String>['-l', '-c', "ruby -e '$script' 2>/dev/null"]);
      if (result.exitCode != 0) return const <String>[];
      return (result.stdout as String)
          .split('\n')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty && Directory(s).existsSync())
          .toList();
    } catch (_) {
      return const <String>[];
    }
  }

  static String? _findOnPath(String executable, String pathEnv) {
    for (final String dir in pathEnv.split(':')) {
      if (dir.isEmpty) continue;
      final File candidate = File('$dir/$executable');
      if (candidate.existsSync()) return candidate.path;
    }
    return null;
  }

  static String? _firstExistingFallback() {
    for (final String candidate in _fallbackCandidates) {
      final String expanded = _expandHome(candidate);
      if (File(expanded).existsSync()) return expanded;
    }
    return null;
  }

  static String _expandHome(String path) {
    if (!path.startsWith('~')) return path;
    final String? home = Platform.environment['HOME'];
    if (home == null) return path;
    return path.replaceFirst('~', home);
  }
}
