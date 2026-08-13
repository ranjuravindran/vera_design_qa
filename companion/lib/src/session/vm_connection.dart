import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// Connects to the running app's VM service (the same one `flutter run`
/// itself uses for hot reload) and resolves its main isolate, needed to
/// call the `ext.design_qa.session` extension `DesignQA.wrap` registers at
/// startup. See design_qa's `lib/src/export/exporter.dart` for the other
/// end of this bridge.
class VmConnection {
  const VmConnection(this.service, this.isolateId);

  final VmService service;
  final String isolateId;

  static Future<VmConnection> connect(String wsUri) async {
    final VmService service = await vmServiceConnectUri(wsUri);
    final VM vm = await service.getVM();
    final IsolateRef isolate = vm.isolates!.first;
    return VmConnection(service, isolate.id!);
  }

  Future<void> dispose() => service.dispose();
}
