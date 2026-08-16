import 'package:flutter/material.dart';

/// A small icon sat inside a light rounded-square badge - the Figma design
/// update applies this consistently to every list-row leading icon (recent
/// projects, found devices, edit history) instead of a bare icon.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.size = 32, this.iconSize = 12});

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: iconSize, color: Colors.black.withValues(alpha: 0.6)),
    );
  }
}
