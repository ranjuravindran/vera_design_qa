import 'package:flutter/material.dart';

/// Sampled directly from `assets/icon/app_icon.png` (dominant colors by
/// pixel count, not eyeballed) so the app's theme actually matches its own
/// icon rather than an arbitrary Material blue.
class AppColors {
  AppColors._();

  static const Color blue = Color(0xFF5B8FD8); // outer ring
  static const Color lightBlue = Color(0xFFB5CFF2); // inner circle
  static const Color orange = Color(0xFFF58805); // pencil tip
  static const Color cream = Color(0xFFFFEFC7); // pencil wood
  static const Color indigo = Color(0xFF32397E); // inner triangle
  static const Color ink = Color(0xFF20244A); // pencil silhouette
}

ThemeData buildAppTheme() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.light,
    primary: AppColors.blue,
    secondary: AppColors.orange,
    tertiary: AppColors.indigo,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Colors.white,
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white),
    ),
  );
}
