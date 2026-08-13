import 'dart:io';

import 'package:path/path.dart' as p;

import 'entry_point_finder.dart';
import 'pubspec_asset.dart';
import 'root_widget_wrapper.dart';
import 'route_scanner.dart';
import 'theme_scanner.dart';
import 'yaml_writer.dart';

/// Everything `dart run design_qa:init` would do to a project, computed but
/// not yet written to disk - the shared plan/apply split behind both the
/// CLI (`bin/init.dart`, gated on a stdin y/N) and the companion app's GUI
/// (gated on a button tap). Neither one re-implements the scanning/writing
/// logic; they only differ in how they ask for confirmation.
class SetupPlan {
  const SetupPlan({
    required this.projectRoot,
    required this.entryPointCandidates,
    required this.wrapTargetPath,
    required this.wrapSourceBefore,
    required this.wrapOutcome,
    required this.tokens,
    required this.routes,
    required this.configExists,
    required this.configWritePreview,
    required this.pubspecAssetUpdate,
  });

  final String projectRoot;

  /// Every `main()` design_qa found - more than one means the caller should
  /// ask which to wrap and re-plan with `entryPointPathOverride`.
  final List<EntryPointCandidate> entryPointCandidates;

  final String? wrapTargetPath;
  final String? wrapSourceBefore;
  final WrapOutcome? wrapOutcome;

  final ScannedTokens tokens;
  final List<String> routes;

  final bool configExists;

  /// New content for `design_qa.yaml`, or null if nothing needs to change
  /// (already up to date).
  final String? configWritePreview;

  /// New content for `pubspec.yaml`, or null if the asset is already
  /// registered.
  final String? pubspecAssetUpdate;

  String get wrapTargetRelative =>
      wrapTargetPath == null ? '' : p.relative(wrapTargetPath!, from: projectRoot);

  /// One-line, human-readable summary of what will happen to
  /// `design_qa.yaml` - shared copy between the CLI and the companion app.
  String get configSummary {
    if (!configExists) {
      return tokens.isEmpty
          ? 'Will create design_qa.yaml (no token source found automatically).'
          : 'Will create design_qa.yaml, pre-filled from ${tokens.source}.';
    }
    return configWritePreview == null
        ? 'design_qa.yaml is up to date.'
        : 'Will add newly discovered route(s) to design_qa.yaml.';
  }
}

class SetupPlanner {
  const SetupPlanner(this.projectRoot);
  final String projectRoot;

  bool get looksLikeFlutterProject => File(p.join(projectRoot, 'pubspec.yaml')).existsSync();

  Future<List<EntryPointCandidate>> findEntryPoints() => EntryPointFinder(projectRoot).find();

  /// Computes the full plan. Pass [entryPointPathOverride] (one of a prior
  /// [SetupPlan.entryPointCandidates]) once the caller has resolved which
  /// `main()` to target, when there was more than one.
  Future<SetupPlan> plan({String? entryPointPathOverride}) async {
    final List<EntryPointCandidate> candidates = await findEntryPoints();

    String? wrapTargetPath;
    String? wrapSourceBefore;
    WrapOutcome? wrapOutcome;
    if (candidates.isNotEmpty) {
      wrapTargetPath = entryPointPathOverride ?? candidates.first.path;
      wrapSourceBefore = await File(wrapTargetPath).readAsString();
      wrapOutcome = const RootWidgetWrapper().wrap(wrapSourceBefore);
    }

    final ScannedTokens tokens = await ThemeScanner(projectRoot).scan();
    final List<String> routes = await RouteScanner(projectRoot).scan();

    final File configFile = File(p.join(projectRoot, 'design_qa.yaml'));
    final bool configExists = configFile.existsSync();
    final String? configPreview = configExists
        ? const YamlWriter().mergeRoutes(await configFile.readAsString(), routes)
        : const YamlWriter().generateFresh(tokens: tokens, routes: routes);

    final File pubspecFile = File(p.join(projectRoot, 'pubspec.yaml'));
    final String? assetUpdate =
        const PubspecAssetRegistrar().ensureRegistered(await pubspecFile.readAsString());

    return SetupPlan(
      projectRoot: projectRoot,
      entryPointCandidates: candidates,
      wrapTargetPath: wrapTargetPath,
      wrapSourceBefore: wrapSourceBefore,
      wrapOutcome: wrapOutcome,
      tokens: tokens,
      routes: routes,
      configExists: configExists,
      configWritePreview: configPreview,
      pubspecAssetUpdate: assetUpdate,
    );
  }

  Future<void> applyWrap(SetupPlan plan) async {
    final WrapOutcome? outcome = plan.wrapOutcome;
    if (outcome is! WrapApplied || plan.wrapTargetPath == null) return;
    await File(plan.wrapTargetPath!).writeAsString(outcome.newSource);
  }

  Future<void> applyConfig(SetupPlan plan) async {
    if (plan.configWritePreview == null) return;
    await File(p.join(projectRoot, 'design_qa.yaml')).writeAsString(plan.configWritePreview!);
  }

  Future<void> applyPubspecAsset(SetupPlan plan) async {
    if (plan.pubspecAssetUpdate == null) return;
    await File(p.join(projectRoot, 'pubspec.yaml')).writeAsString(plan.pubspecAssetUpdate!);
  }
}
