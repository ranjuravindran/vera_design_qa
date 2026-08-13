import 'package:flutter/material.dart';

import 'src/companion_controller.dart';
import 'src/screens/device_screen.dart';
import 'src/screens/error_screen.dart';
import 'src/screens/launching_screen.dart';
import 'src/screens/project_picker_screen.dart';
import 'src/screens/running_screen.dart';
import 'src/screens/setup_review_screen.dart';
import 'src/theme.dart';

void main() {
  runApp(const CompanionApp());
}

class CompanionApp extends StatefulWidget {
  const CompanionApp({super.key});

  @override
  State<CompanionApp> createState() => _CompanionAppState();
}

class _CompanionAppState extends State<CompanionApp> {
  final CompanionController _controller = CompanionController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design QA',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? _) => switch (_controller.stage) {
                Stage.pickProject => ProjectPickerScreen(controller: _controller),
                Stage.scanningSetup => const _Spinner('Looking at your app...'),
                Stage.reviewSetup => SetupReviewScreen(controller: _controller),
                Stage.applyingSetup => LaunchingScreen(controller: _controller),
                Stage.pickingDevice => DeviceScreen(controller: _controller),
                Stage.launching => LaunchingScreen(controller: _controller),
                Stage.running => RunningScreen(controller: _controller),
                Stage.error => ErrorScreen(controller: _controller),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }
}
