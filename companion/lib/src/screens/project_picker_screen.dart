import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../companion_controller.dart';

const String _recentKey = 'recent_projects';

class ProjectPickerScreen extends StatefulWidget {
  const ProjectPickerScreen({super.key, required this.controller});
  final CompanionController controller;

  @override
  State<ProjectPickerScreen> createState() => _ProjectPickerScreenState();
}

class _ProjectPickerScreenState extends State<ProjectPickerScreen> {
  List<String> _recent = <String>[];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _recent = prefs.getStringList(_recentKey) ?? <String>[]);
  }

  Future<void> _remember(String path) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> updated = <String>[path, ..._recent.where((String p) => p != path)].take(5).toList();
    await prefs.setStringList(_recentKey, updated);
  }

  Future<void> _choose() async {
    final String? path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: "Choose your app's folder",
    );
    if (path == null) return;
    await _remember(path);
    if (!mounted) return;
    await widget.controller.pickProject(path);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/icon/app_icon.png', width: 84, height: 84, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            const Text(
              'Design QA',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pick the folder for the app you want to review — the one with pubspec.yaml in it.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _choose,
              icon: const Icon(Icons.folder_open),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Choose app folder'),
              ),
            ),
            if (_recent.isNotEmpty) ...<Widget>[
              const SizedBox(height: 28),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Recent', style: TextStyle(fontSize: 12, color: Colors.black45)),
              ),
              const SizedBox(height: 6),
              for (final String path in _recent)
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.folder_outlined, size: 18),
                    title: Text(path.split('/').last, style: const TextStyle(fontSize: 13)),
                    subtitle: Text(path, style: const TextStyle(fontSize: 11)),
                    onTap: () async {
                      await _remember(path);
                      if (!mounted) return;
                      await widget.controller.pickProject(path);
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
