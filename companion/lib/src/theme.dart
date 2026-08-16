import 'package:flutter/material.dart';

/// Icon-derived decorative colors (outer ring, pencil, etc.) predate the
/// Vera rebrand and are kept as-is for the launching-screen progress ring -
/// same policy the Aug 2026 design-system pass already established for
/// this palette.
class AppColors {
  AppColors._();

  static const Color blue = Color(0xFF5B8FD8); // outer ring
  static const Color lightBlue = Color(0xFFB5CFF2); // inner circle
  static const Color orange = Color(0xFFF58805); // pencil tip
  static const Color cream = Color(0xFFFFEFC7); // pencil wood
  static const Color indigo = Color(0xFF32397E); // inner triangle
  static const Color ink = Color(0xFF20244A); // pencil silhouette

  static const Color accent = Color(0xFF009DFF);
  static const Color textDefault = Color(0xFF14162E);
  static const Color textSubtle = Color(0xFF495064);
  static const Color textMuted = Color(0xFF99A1B8);
  static const Color surfaceCanvas = Color(0xFFF1F3F8);
  static const Color blueTint = Color(0xFFEEF5FD);
  static const Color greenTint = Color(0xFFE9F7EA);
  static const Color critical = Color(0xFFAB0202);
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
      style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
  );
}
