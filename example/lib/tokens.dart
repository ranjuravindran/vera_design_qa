import 'package:flutter/material.dart';

/// Hand-rolled design tokens - the shape `dart run design_qa:init`'s token
/// scanner looks for (a class of `static const` Color/double fields).
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2962FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B1B1F);
  static const Color textSecondary = Color(0xFF5C5C66);
  static const Color error = Color(0xFFD32F2F);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 4;
  static const double md = 8;
  static const double lg = 16;
}
