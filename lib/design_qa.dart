/// Debug-only visual overlay for fixing design fidelity issues on a running
/// Flutter app, with export to source-code patches.
///
/// The only symbol application code needs is [DesignQA.wrap] - see the
/// package README for setup (`dart run design_qa:init` does the wrapping
/// for you) and doc/design_qa_yaml_reference.md for the config file it
/// generates.
library;

export 'src/core/design_qa.dart' show DesignQA;
