import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../companion_controller.dart';
import '../theme.dart';
import '../widgets/icon_badge.dart';

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

  Future<void> _clearRecent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentKey);
    setState(() => _recent = <String>[]);
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
              child: SvgPicture.asset('assets/icon/app_icon.svg', width: 84, height: 84),
            ),
            const SizedBox(height: 16),
            Text(
              'Design QA',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.brandTitle,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pick the folder for the app you want to review — the one with pubspec.yaml in it.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSubtle, height: 1.4),
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
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Text('Recent', style: TextStyle(fontSize: 12, color: AppColors.textSubtle)),
                  ),
                  GestureDetector(
                    onTap: _clearRecent,
                    child: const Text(
                      'Clear All',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final String path in _recent)
                Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  color: AppColors.surfaceCanvas,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      await _remember(path);
                      if (!mounted) return;
                      await widget.controller.pickProject(path);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: <Widget>[
                          const IconBadge(icon: Icons.folder_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  path.split('/').last,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDefault,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(path, style: const TextStyle(fontSize: 10, color: AppColors.textSubtle)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
