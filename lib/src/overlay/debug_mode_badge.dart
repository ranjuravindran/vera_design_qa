import 'package:flutter/material.dart';

import '../core/design_qa_controller.dart';
import '../core/design_qa_scope.dart';

/// Small persistent label identifying the overlay and the app it's
/// attached to - "Vera - Debug Mode: `<App Name>`". Pinned to the top
/// right so it never collides with [TrackingWarningBanner] (top left, full
/// width, and only shown conditionally) or the route jumper (also top
/// left). Shows without the app name suffix if the title probe in
/// design_qa_overlay.dart hasn't found the wrapped app's MaterialApp yet.
class DebugModeBadge extends StatelessWidget {
  const DebugModeBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final DesignQAController controller = DesignQAScope.of(context);
    final String? appName = controller.appName;
    final String label = appName == null ? 'Vera - Debug Mode' : 'Vera - Debug Mode: $appName';

    return Positioned(
      top: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 8, color: Colors.black38)],
            ),
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
