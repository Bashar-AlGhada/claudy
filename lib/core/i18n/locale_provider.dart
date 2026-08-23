import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends AsyncNotifier<Locale> {
  static const storageKey = 'settings.locale';

  /// Parses a persisted "language" or "language-COUNTRY" string.
  /// Returns null for null/blank input.
  static Locale? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.first.isEmpty) return null;
    if (parts.length == 1) return Locale(parts.first);
    return Locale(parts.first, parts[1]);
  }

  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    return tryParse(prefs.getString(storageKey)) ?? const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    final value =
        locale.countryCode == null ? locale.languageCode : '${locale.languageCode}-${locale.countryCode}';
    await prefs.setString(storageKey, value);
    state = AsyncData(locale);
  }
}

