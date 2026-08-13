/// Programmatic surface for building tools on top of design_qa - the
/// companion desktop app, or anything else that wants to drive setup and
/// export without shelling out to the CLI and scraping text output.
///
/// Everything here is plain Dart (no Flutter), same as `bin/init.dart` and
/// `bin/export.dart` - see edit_value.dart for why that separation matters.
library;

export 'src/cli/setup_planner.dart' show SetupPlan, SetupPlanner;
export 'src/cli/entry_point_finder.dart' show EntryPointCandidate;
export 'src/cli/root_widget_wrapper.dart' show WrapOutcome, WrapApplied, WrapAlreadyDone, WrapNeedsManualEdit;
export 'src/cli/theme_scanner.dart' show ScannedTokens;
export 'src/core/edit_key.dart' show EditKey;
export 'src/core/edit_record.dart' show EditRecord;
export 'src/core/edit_value.dart';
export 'src/export/export_pipeline.dart' show ExportResult, exportToDisk;
