import 'package:design_qa/companion_api.dart';
import 'package:flutter/material.dart';

import '../companion_controller.dart';
import '../theme.dart';
import '../widgets/icon_badge.dart';

class RunningScreen extends StatelessWidget {
  const RunningScreen({super.key, required this.controller});
  final CompanionController controller;

  @override
  Widget build(BuildContext context) {
    final List<EditRecord> edits = controller.edits;
    final ExportResult? lastExport = controller.lastExport;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Running on ${controller.selectedDevice?.name ?? "your device"}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDefault),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'On your phone: tap the floating dot, then Inspect, then tap anything you want to fix.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSubtle, height: 1.4),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: controller.stopSession,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.critical,
                    side: const BorderSide(color: AppColors.critical),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Stop'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              edits.isEmpty ? 'No changes yet' : '${edits.length} change${edits.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDefault),
            ),
            const SizedBox(height: 8),
            if (edits.isEmpty)
              Card(
                color: AppColors.surfaceCanvas,
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Changes you make on your phone will show up here.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSubtle),
                    ),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    for (final EditRecord e in edits.reversed)
                      Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        color: AppColors.surfaceCanvas,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: <Widget>[
                              const IconBadge(icon: Icons.edit_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text(
                                      _friendlyDescription(e),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDefault,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${e.key.file.split('/').last}, line ${e.key.line}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSubtle),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: edits.isEmpty ? null : controller.saveChanges,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Save my changes'),
              ),
            ),
            if (lastExport != null) ...<Widget>[
              const SizedBox(height: 12),
              _SavedSummary(result: lastExport),
            ],
          ],
        ),
      ),
    );
  }

  String _friendlyDescription(EditRecord e) {
    final String property = switch (e.key.property) {
      'padding' => 'padding',
      'margin' => 'margin',
      'color' => 'color',
      'borderRadius' => 'corner roundness',
      'width' => 'width',
      'height' => 'height',
      'fontSize' => 'text size',
      'fontWeight' => 'text weight',
      'letterSpacing' => 'letter spacing',
      'lineHeight' => 'line height',
      'spacing' => 'spacing between items',
      'mainAxisAlignment' => 'alignment',
      'crossAxisAlignment' => 'alignment',
      _ => e.key.property,
    };
    return '${e.widgetType} $property changed';
  }
}

class _SavedSummary extends StatelessWidget {
  const _SavedSummary({required this.result});
  final ExportResult result;

  @override
  Widget build(BuildContext context) {
    final bool ok = result.filesWritten.isNotEmpty;
    return Card(
      color: ok ? AppColors.greenTint : Colors.orange.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Icon(ok ? Icons.check_circle_outline : Icons.info_outline, size: 18, color: ok ? Colors.green : Colors.orange),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                ok
                    ? 'Saved to design_qa_out in your app folder — ${result.editedFileCount} file'
                        '${result.editedFileCount == 1 ? '' : 's'} changed. Hand that folder to whoever '
                        'is building the app (or paste it to Claude Code and ask it to apply the changes).'
                    : "Couldn't save automatically. ${result.notes.isNotEmpty ? result.notes.first : ''}",
                style: const TextStyle(fontSize: 10, height: 1.4, color: AppColors.textDefault),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
