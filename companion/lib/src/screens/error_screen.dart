import 'package:flutter/material.dart';

import '../companion_controller.dart';
import '../theme.dart';

class ErrorScreen extends StatefulWidget {
  const ErrorScreen({super.key, required this.controller});
  final CompanionController controller;

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Align(
              alignment: Alignment.center,
              child: Icon(Icons.error_outline, color: Colors.redAccent, size: 72),
            ),
            const SizedBox(height: 14),
            Text(
              widget.controller.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDefault),
            ),
            if (widget.controller.errorDetail.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _showDetail = !_showDetail),
                child: Text(_showDetail ? 'Hide details' : 'Show details'),
              ),
              if (_showDetail)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(color: AppColors.blueTint, borderRadius: BorderRadius.circular(12)),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.controller.errorDetail,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textDefault),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: widget.controller.reset, child: const Text('Start over')),
          ],
        ),
      ),
    );
  }
}
