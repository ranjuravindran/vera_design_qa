import 'package:flutter/material.dart';

import 'tokens.dart';

/// Deliberately off-spec, to demonstrate the design_qa fix loop end to end:
///
/// 1. `flutter run --track-widget-creation`, open the pill, hit inspect.
/// 2. Tap the card - its padding is 14 instead of [AppSpacing.md] (16), and
///    its color is a hardcoded near-miss of [AppColors.primary]. Token
///    linting flags both inline with a one-tap fix.
/// 3. Tap the heading - its `fontSize` is 20, two logical pixels off the
///    22 used on the home screen's equivalent heading.
/// 4. Drag values live, watch the screen update with no rebuild, then hit
///    export on the pill to get a patch + changelog in design_qa_out/.
class BrokenScreen extends StatelessWidget {
  const BrokenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broken screen')),
      body: Padding(
        // Should be AppSpacing.lg (24) - off by 8.
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'This heading is off-scale',
              // Home screen's equivalent heading is fontSize: 22.
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              // Should be AppSpacing.md (16) - off by 2.
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // A near-miss of AppColors.primary (0xFF2962FF).
                color: const Color(0xFF2A63FE),
                // Should be AppRadius.md (8).
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Wrong padding, near-miss color, wrong radius',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              // Should probably be spaceBetween or use a `spacing:` matching
              // the rest of the app's rhythm - left as `start` to show the
              // alignment control in the property panel.
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _Chip(color: AppColors.error),
                const SizedBox(width: 6),
                const _Chip(color: Color(0xFF9C27B0)), // not a token at all
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
