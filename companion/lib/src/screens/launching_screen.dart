import 'package:flutter/material.dart';

import '../companion_controller.dart';

class LaunchingScreen extends StatelessWidget {
  const LaunchingScreen({super.key, required this.controller});
  final CompanionController controller;

  @override
  Widget build(BuildContext context) {
    final List<String> messages = controller.progressMessages;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 20),
            Text(
              messages.isEmpty ? 'Starting...' : messages.last,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'First time takes a minute or two.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
