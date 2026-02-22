import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:flutter/material.dart';

enum ThemePresetId {
  aurora,
  minimal,
  solar,
  midnight,
  highContrast,
}

class ThemePreset {
  const ThemePreset({
    required this.id,
    required this.labelKey,
    required this.seed,
    required this.brightness,
  });

  final ThemePresetId id;
  final String labelKey;
  final Color seed;
  final Brightness brightness;
}

class ThemePresets {
  static const all = <ThemePreset>[
    ThemePreset(
      id: ThemePresetId.aurora,
      labelKey: LocaleKeys.themePresetAurora,
      seed: Color(0xFF4A7DFF),
      brightness: Brightness.dark,
    ),
    ThemePreset(
      id: ThemePresetId.minimal,
      labelKey: LocaleKeys.themePresetMinimal,
      seed: Color(0xFF9BA1A6),
      brightness: Brightness.light,
    ),
    ThemePreset(
      id: ThemePresetId.solar,
      labelKey: LocaleKeys.themePresetSolar,
      seed: Color(0xFFFFB000),
      brightness: Brightness.light,
    ),
    ThemePreset(
      id: ThemePresetId.midnight,
      labelKey: LocaleKeys.themePresetMidnight,
      seed: Color(0xFF141A2D),
      brightness: Brightness.dark,
    ),
    ThemePreset(
      id: ThemePresetId.highContrast,
      labelKey: LocaleKeys.themePresetHighContrast,
      seed: Color(0xFF000000),
      brightness: Brightness.dark,
    ),
  ];

  static ThemePreset byId(ThemePresetId id) {
    return all.firstWhere((p) => p.id == id);
  }
}

