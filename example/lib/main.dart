// ignore: depend_on_referenced_packages
import 'package:design_qa/design_qa.dart'; // dev-only, see pubspec.yaml
import 'package:flutter/material.dart';

import 'broken_screen.dart';
import 'tokens.dart';

void main() {
  runApp(DesignQA.wrap(child: const ExampleApp()));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'design_qa example',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: AppColors.primary),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const HomeScreen(),
        '/broken': (BuildContext context) => const BrokenScreen(),
        '/profile': (BuildContext context) => const ProfileScreen(),
      },
    );
  }
}

/// A normal, correctly-built screen - every value here comes from
/// [AppColors]/[AppSpacing]/[AppRadius], so token linting has nothing to
/// flag. Compare against broken_screen.dart, which deliberately drifts
/// from these tokens to demonstrate the fix loop.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('design_qa example')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.md,
          children: <Widget>[
            const Text(
              'This screen is clean',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const Text(
              'Tap the pill, hit inspect, then select something on the broken '
              'screen to see the fix loop.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Text('Container using tokens', style: TextStyle(color: Colors.white)),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/broken'),
              child: const Text('Open the broken screen'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed(
                '/profile',
                arguments: <String, Object?>{'userId': 'demo-user-1'},
              ),
              child: const Text('Open profile (needs an argument)'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<Object?, Object?>? args =
        ModalRoute.of(context)?.settings.arguments as Map<Object?, Object?>?;
    final String userId = (args?['userId'] as String?) ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('userId: $userId'),
      ),
    );
  }
}
