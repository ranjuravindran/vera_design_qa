import 'package:design_qa/companion_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../companion_controller.dart';
import '../theme.dart';

class SetupReviewScreen extends StatefulWidget {
  const SetupReviewScreen({super.key, required this.controller});
  final CompanionController controller;

  @override
  State<SetupReviewScreen> createState() => _SetupReviewScreenState();
}

class _SetupReviewScreenState extends State<SetupReviewScreen> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final SetupPlan? plan = widget.controller.plan;
    if (plan == null) return const Center(child: CircularProgressIndicator());

    final WrapOutcome? outcome = plan.wrapOutcome;
    final bool blocked = outcome is WrapNeedsManualEdit || outcome == null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Ready to set up',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDefault),
                ),
                const SizedBox(height: 4),
                Text(
                  plan.projectRoot.split('/').last,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSubtle),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (plan.entryPointCandidates.length > 1) _EntryPointPicker(controller: widget.controller, plan: plan),

            _StepCard(
              leading: Icon(
                blocked ? Icons.error_outline : Icons.check_circle_outline,
                color: blocked ? Colors.orange : Colors.green,
                size: 16,
              ),
              title: switch (outcome) {
                WrapAlreadyDone() => 'Review tool is already turned on.',
                WrapApplied() => "I'll add one line to your app so the review tool can turn on.",
                WrapNeedsManualEdit() => "I can't safely add that line automatically.",
                null => 'No startup file found to set up.',
              },
              trailing: outcome is WrapApplied
                  ? TextButton(
                      onPressed: () => setState(() => _showDetail = !_showDetail),
                      child: Text(_showDetail ? 'Hide the change' : 'See the exact change'),
                    )
                  : null,
              detail: switch (outcome) {
                WrapApplied() when _showDetail => plan.wrapTargetRelative,
                WrapNeedsManualEdit(:final String reason, :final String snippet) =>
                  '$reason\n\nAdd this yourself:\n$snippet',
                _ => null,
              },
            ),
            if (outcome is WrapApplied && _showDetail) _DiffPreview(before: plan.wrapSourceBefore!, after: outcome.newSource),

            const SizedBox(height: 10),
            _StepCard(
              leading: SvgPicture.asset('assets/icons/settings_dots.svg', width: 16, height: 16),
              title: plan.configSummary,
            ),
            const SizedBox(height: 10),
            _StepCard(
              leading: SvgPicture.asset('assets/icons/sync.svg', width: 16, height: 16),
              title: plan.pubspecAssetUpdate == null
                  ? 'Your app is already registered correctly.'
                  : "I'll register one file so it works on a real phone.",
            ),

            const SizedBox(height: 28),
            if (blocked)
              const Text(
                "This app can't turn on the review tool automatically. Add the line above yourself, "
                "then reopen this app.",
                style: TextStyle(fontSize: 13, color: AppColors.textSubtle),
              )
            else
              FilledButton(
                onPressed: () => widget.controller.applySetupAndContinue(applyWrap: outcome is WrapApplied),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('Continue'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EntryPointPicker extends StatelessWidget {
  const _EntryPointPicker({required this.controller, required this.plan});
  final CompanionController controller;
  final SetupPlan plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: plan.wrapTargetPath,
        decoration: const InputDecoration(labelText: 'Which part of the app should I set up?'),
        items: <DropdownMenuItem<String>>[
          for (final EntryPointCandidate c in plan.entryPointCandidates)
            DropdownMenuItem<String>(value: c.path, child: Text(c.path.split('/').last)),
        ],
        onChanged: (String? path) {
          if (path != null) controller.pickEntryPoint(path);
        },
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.leading,
    required this.title,
    this.trailing,
    this.detail,
  });

  final Widget leading;
  final String title;
  final Widget? trailing;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceCanvas,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textDefault)),
                  if (detail != null && detail!.isNotEmpty && trailing == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        detail!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSubtle, fontFamily: 'monospace'),
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A plain-language before/after instead of a raw unified diff, for anyone
/// curious enough to tap "See the exact change" without needing to read
/// code.
class _DiffPreview extends StatelessWidget {
  const _DiffPreview({required this.before, required this.after});
  final String before;
  final String after;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('New version of your startup file:', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 6),
            SelectableText(after, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', height: 1.5)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Copy'),
                onPressed: () => Clipboard.setData(ClipboardData(text: after)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
