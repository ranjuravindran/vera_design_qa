import 'dart:io';

import 'package:design_qa/src/cli/init_command.dart';

/// `dart run design_qa:init` - see lib/src/cli/init_command.dart.
/// `dart run <package>:<name>` resolves to `bin/<name>.dart`, which is why
/// this is a separate entrypoint from export.dart rather than a
/// subcommand of one shared binary.
Future<void> main(List<String> arguments) async {
  exitCode = await InitCommand(projectRoot: Directory.current.path).run();
}
