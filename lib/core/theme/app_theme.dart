import 'package:claudy/core/theme/theme_preset.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme({
    required this.presetId,
    required this.lowPowerMode,
    required this.materialThemeData,
  });

  final ThemePresetId presetId;
  final bool lowPowerMode;
  final ThemeData materialThemeData;
}
