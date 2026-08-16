import 'package:flutter/material.dart';

import '../companion_controller.dart';
import '../process/device_discovery.dart';
import '../theme.dart';
import '../widgets/icon_badge.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.controller});
  final CompanionController controller;

  @override
  Widget build(BuildContext context) {
    final List<DeviceInfo> devices = controller.devices;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Connect your phone',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDefault),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  "Plug your Android phone in with a USB cable. If this is the first time, "
                  "you'll need to turn on one setting.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSubtle, height: 1.4),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _UsbDebuggingInstructions(),
            const SizedBox(height: 20),
            if (devices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(height: 12),
                      Text('Looking for your phone...', style: TextStyle(fontSize: 13, color: AppColors.textSubtle)),
                    ],
                  ),
                ),
              )
            else ...<Widget>[
              const Text('Found:', style: TextStyle(fontSize: 12, color: AppColors.textSubtle)),
              const SizedBox(height: 6),
              for (final DeviceInfo device in devices)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: AppColors.surfaceCanvas,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        IconBadge(icon: _iconFor(device)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                device.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDefault,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                device.emulator ? 'Virtual device' : 'Connected device',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSubtle),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () => controller.launchOn(device),
                          child: const Text('Use this'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(DeviceInfo device) {
    if (device.targetPlatform.startsWith('android')) return Icons.phone_android;
    if (device.targetPlatform.startsWith('ios')) return Icons.phone_iphone;
    if (device.targetPlatform.startsWith('darwin') || device.targetPlatform.startsWith('macos')) {
      return Icons.laptop_mac;
    }
    return Icons.devices_other;
  }
}

class _UsbDebuggingInstructions extends StatelessWidget {
  const _UsbDebuggingInstructions();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.blueTint,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              'Turning on that setting (only needed once):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDefault),
            ),
            SizedBox(height: 8),
            _Step(number: 1, text: 'On your phone: Settings → About phone'),
            _Step(number: 2, text: 'Tap "Build number" 7 times in a row'),
            _Step(number: 3, text: 'Go back → Developer options → turn on "USB debugging"'),
            _Step(number: 4, text: 'Plug the phone in and tap "Allow" on the popup that appears'),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 18,
            child: Text('$number.', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textDefault),
            ),
          ),
        ],
      ),
    );
  }
}
