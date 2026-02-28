import 'package:claudy/core/theme/app_theme.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/core/theme/theme_preset.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider =
    AsyncNotifierProvider<ThemeNotifier, AppTheme>(ThemeNotifier.new);

class ThemeNotifier extends AsyncNotifier<AppTheme> {
  static const _keyLowPower = 'settings.lowPower';
  static const _keyPreset = 'settings.themePreset';

  @override
  Future<AppTheme> build() async {
    final prefs = await SharedPreferences.getInstance();
    final lowPower = prefs.getBool(_keyLowPower) ?? false;
    final presetId = _readPreset(prefs.getString(_keyPreset));
    final preset = ThemePresets.byId(presetId);

    final baseScheme = presetId == ThemePresetId.highContrast
        ? (preset.brightness == Brightness.dark
            ? const ColorScheme.highContrastDark()
            : const ColorScheme.highContrastLight())
        : ColorScheme.fromSeed(
            seedColor: preset.seed,
            brightness: preset.brightness,
          );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      dividerTheme: const DividerThemeData(space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.cornerRadius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tokens.cornerRadius),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: Tokens.space16),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.cornerRadius),
        ),
      ),
    );

    final adjusted = lowPower
        ? base.copyWith(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
          )
        : base;

    return AppTheme(
      presetId: presetId,
      lowPowerMode: lowPower,
      materialThemeData: adjusted,
    );
  }

  Future<void> setLowPowerMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLowPower, enabled);
    state = AsyncData(await build());
  }

  Future<void> setPreset(ThemePresetId presetId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPreset, presetId.name);
    state = AsyncData(await build());
  }

  ThemePresetId _readPreset(String? raw) {
    return ThemePresetId.values.firstWhere(
      (v) => v.name == raw,
      orElse: () => ThemePresetId.aurora,
    );
  }
}
