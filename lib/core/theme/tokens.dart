import 'package:flutter/material.dart';

class Tokens {
  static const double cornerRadius = 18;
  static const Color seed = Color(0xFF4A7DFF);
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;
  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionMedium = Duration(milliseconds: 240);
  static const Duration motionSlow = Duration(milliseconds: 300);
  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;

  // Floating Navigation Bar
  static const double floatingNavBarHeight = 64.0;
  static const double floatingNavBarMargin = 16.0;
  static const double floatingNavBarBorderRadius = 32.0;
  static const double floatingNavBarElevation = 8.0;
  static const double floatingNavBarOpacity = 0.85;

  // Empty State Icons
  static const double emptyStateIconSize = 120.0;
  static const double emptyStateIconOpacity = 0.2;

  // Weather Animation Timings
  static const Duration weatherAnimationDuration = Duration(seconds: 10);
  static const Duration particleAnimationDuration = Duration(seconds: 3);
  static const Duration lightningFlashDuration = Duration(milliseconds: 150);

  // Glassmorphism/Transparency
  static const double glassOpacity = 0.1;
  static const double glassBlur = 10.0;
}
