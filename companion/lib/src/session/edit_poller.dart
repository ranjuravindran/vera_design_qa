import 'package:design_qa/companion_api.dart';
import 'package:vm_service/vm_service.dart';

import 'vm_connection.dart';

/// Polls the running app for its current edit session. Simple
/// request/response polling (not a persistent stream) since edits are rare
/// human-paced events (a designer tapping and dragging), not high-frequency
/// data - a fixed interval from the UI is all this needs.
class EditPoller {
  const EditPoller(this._connection);
  final VmConnection _connection;

  Future<List<EditRecord>> poll() async {
    final Response response = await _connection.service.callServiceExtension(
      'ext.design_qa.session',
      isolateId: _connection.isolateId,
    );
    final List<dynamic> raw = (response.json?['edits'] as List<dynamic>?) ?? <dynamic>[];
    return raw.map((dynamic e) => EditRecord.fromJson((e as Map).cast<String, Object?>())).toList();
  }
}
