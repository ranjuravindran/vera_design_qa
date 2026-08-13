import 'dart:io';

import 'package:args/args.dart';
import 'package:design_qa/src/cli/export_command.dart';

/// `dart run design_qa:export --vm-service-uri=<uri>` - the host-side half
/// of exporting from an Android emulator or physical device, which has no
/// filesystem access to the host project at all. See
/// lib/src/export/exporter.dart for the full explanation and
/// lib/src/cli/export_command.dart for the VM service bridge itself.
Future<void> main(List<String> arguments) async {
  final ArgParser parser = ArgParser()..addOption('vm-service-uri');
  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln('Usage: dart run design_qa:export --vm-service-uri=<uri>');
    exitCode = 64;
    return;
  }

  final String? uri = results['vm-service-uri'] as String?;
  if (uri == null) {
    stderr.writeln('Usage: dart run design_qa:export --vm-service-uri=<uri>');
    stderr.writeln("(the URI 'flutter run' printed when it started your app)");
    exitCode = 64;
    return;
  }
  exitCode = await ExportCommand(projectRoot: Directory.current.path, vmServiceUri: uri).run();
}
