import 'package:flutter/material.dart';

/// The one dark theme for all of design_qa's own chrome (pill, panel,
/// dialogs, dropdowns, sliders) - applied once at the root of the overlay
/// tree in [DesignQAOverlay] rather than left to fall back to Flutter's
/// default. Without this, every Material widget that reads `Theme.of` here
/// (AlertDialog, Slider, DropdownButton, TextField...) would render with
/// Flutter's default *light* theme, since this chrome is a sibling of the
/// app's own MaterialApp, not a descendant of it - nothing to inherit a
/// theme from. That mismatch was most visible in the color picker dialog,
/// which opened as a plain white popup over an otherwise all-dark tool.
ThemeData buildDesignQAChromeTheme() {
  const Color surface = Color(0xFF1E1E1E);
  const Color surfaceRaised = Color(0xFF2A2A2A);
  const Color accent = Color(0xFF2962FF);

  final ColorScheme scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: Brightness.dark,
    primary: accent,
    surface: surface,
    onSurface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    canvasColor: surfaceRaised,
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceRaised,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
      contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.white70),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(backgroundColor: accent, foregroundColor: Colors.white),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      thumbColor: Colors.white,
      inactiveTrackColor: Colors.white24,
      overlayColor: accent.withValues(alpha: 0.16),
      trackHeight: 3,
    ),
    // Figma's own fields are close to borderless at rest - a quiet fill,
    // nothing else - and only pick up a visible ring on focus. A border
    // outlining every single field regardless of state reads as far
    // busier once a panel has a dozen of them stacked, which is the
    // normal case here. The transparent-side border (rather than
    // InputBorder.none) keeps the exact same width reserved at rest, so
    // focusing a field doesn't nudge its neighbors.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF141414),
      hintStyle: const TextStyle(color: Colors.white38),
      labelStyle: const TextStyle(color: Colors.white60),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: accent, width: 1.5),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll<Color>(surfaceRaised)),
    ),
    popupMenuTheme: PopupMenuThemeData(color: surfaceRaised),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(6)),
      textStyle: const TextStyle(color: Colors.white, fontSize: 11),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    dividerColor: Colors.white12,
  );
}
