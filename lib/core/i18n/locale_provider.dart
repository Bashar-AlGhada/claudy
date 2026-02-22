import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeProvider =
    AsyncNotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends AsyncNotifier<Locale> {
  static const _key = 'settings.locale';

  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const Locale('en');
    final parts = raw.split('-');
    if (parts.isEmpty || parts.first.isEmpty) return const Locale('en');
    if (parts.length == 1) return Locale(parts.first);
    return Locale(parts.first, parts[1]);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    final value =
        locale.countryCode == null ? locale.languageCode : '${locale.languageCode}-${locale.countryCode}';
    await prefs.setString(_key, value);
    state = AsyncData(locale);
  }
}

