import 'package:flutter/material.dart';

import '../companion_controller.dart';
import '../theme.dart';

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
              width: 48,
              height: 48,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              messages.isEmpty ? 'Building your app...' : messages.last,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDefault),
            ),
            const SizedBox(height: 8),
            const Text(
              'First time takes a minute or two.',
              style: TextStyle(fontSize: 12, color: AppColors.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}
