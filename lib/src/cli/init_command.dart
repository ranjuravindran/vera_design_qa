import 'dart:io';

import 'package:path/path.dart' as p;

import '../export/diff_writer.dart';
import 'root_widget_wrapper.dart';
import 'setup_planner.dart';

/// `dart run design_qa:init` - the three-step setup's step 2. Thin
/// stdin/stdout wrapper around [SetupPlanner]; the companion app wraps the
/// same planner in a GUI instead. Every file write here is either additive
/// (`design_qa.yaml`, `pubspec.yaml`'s asset list) or gated behind an
/// explicit y/N after showing a real diff (the entry-point wrap) - see the
/// process writeup this package was built from for why main.dart
/// specifically never gets edited without one.
class InitCommand {
  const InitCommand({required this.projectRoot});
  final String projectRoot;

  Future<int> run() async {
    stdout.writeln('design_qa: init\n');

    final SetupPlanner planner = SetupPlanner(projectRoot);
    if (!planner.looksLikeFlutterProject) {
      stderr.writeln('No pubspec.yaml found at $projectRoot - run this from a Flutter project root.');
      return 1;
    }

    SetupPlan plan = await planner.plan();

    if (plan.entryPointCandidates.length > 1) {
      stdout.writeln('Found multiple entry points:');
      for (int i = 0; i < plan.entryPointCandidates.length; i++) {
        stdout.writeln('  [$i] ${p.relative(plan.entryPointCandidates[i].path, from: projectRoot)}');
      }
      final String? choice = _prompt('Which one should design_qa wrap? [0]: ');
      final int idx = int.tryParse(choice ?? '') ?? 0;
      plan = await planner.plan(
        entryPointPathOverride:
            plan.entryPointCandidates[idx.clamp(0, plan.entryPointCandidates.length - 1)].path,
      );
    }

    await _handleWrap(planner, plan);
    stdout.writeln();
    await _handleConfig(planner, plan);
    stdout.writeln();
    await _handleAsset(planner, plan);

    stdout.writeln('\nNext:');
    stdout.writeln('  flutter pub get');
    stdout.writeln('  flutter run --track-widget-creation');
    return 0;
  }

  Future<void> _handleWrap(SetupPlanner planner, SetupPlan plan) async {
    if (plan.wrapOutcome == null) {
      stdout.writeln(
        'Could not find a main() under lib/. Add this yourself:\n'
        '  runApp(DesignQA.wrap(child: /* your root widget */));',
      );
      return;
    }

    switch (plan.wrapOutcome!) {
      case WrapAlreadyDone():
        stdout.writeln('${plan.wrapTargetRelative}: already wrapped with DesignQA.wrap - nothing to do.');
      case WrapNeedsManualEdit(:final String reason, :final String snippet):
        stdout.writeln('${plan.wrapTargetRelative}: $reason\nAdd this yourself:\n  $snippet');
      case WrapApplied(:final String newSource):
        stdout.writeln(
          unifiedDiff(path: plan.wrapTargetRelative, before: plan.wrapSourceBefore!, after: newSource),
        );
        if (_confirm('Apply this change to ${plan.wrapTargetRelative}? [y/N] ')) {
          await planner.applyWrap(plan);
          stdout.writeln('Updated ${plan.wrapTargetRelative}.');
        } else {
          stdout.writeln('Skipped - ${plan.wrapTargetRelative} left unchanged.');
        }
    }
  }

  Future<void> _handleConfig(SetupPlanner planner, SetupPlan plan) async {
    await planner.applyConfig(plan);
    stdout.writeln(plan.configSummary);
  }

  Future<void> _handleAsset(SetupPlanner planner, SetupPlan plan) async {
    await planner.applyPubspecAsset(plan);
    stdout.writeln(
      plan.pubspecAssetUpdate == null
          ? 'pubspec.yaml: design_qa.yaml already registered as an asset.'
          : 'pubspec.yaml: registered design_qa.yaml as an asset.',
    );
  }

  String? _prompt(String message) {
    stdout.write(message);
    return stdin.readLineSync();
  }

  bool _confirm(String message) => _prompt(message)?.trim().toLowerCase() == 'y';
}
