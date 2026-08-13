import 'package:flutter/material.dart';

/// Shown instead of crashing or silently no-op'ing when
/// `--track-widget-creation` is off - inspect mode has no source location
/// to key edits by without it, so this stays up until the app is relaunched
/// with the flag set.
class TrackingWarningBanner extends StatelessWidget {
  const TrackingWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFB71C1C),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 8, color: Colors.black38)],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Can't inspect or edit yet - relaunch this app through the Design QA "
                  'app (or add --track-widget-creation if you started it from a terminal).',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
