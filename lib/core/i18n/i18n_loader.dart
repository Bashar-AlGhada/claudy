import 'dart:convert';

import 'package:claudy/core/i18n/i18n_store.dart';
import 'package:flutter/services.dart';

class I18nLoader {
  static Future<void> load() async {
    final en = await _loadLocale('en');
    final nl = await _loadLocale('nl');
    final ar = await _loadLocale('ar');

    I18nStore.setKeys({
      'en': en,
      'nl': nl,
      'ar': ar,
    });
  }

  static Future<Map<String, String>> _loadLocale(String locale) async {
    final raw = await rootBundle.loadString('assets/i18n/$locale.json');
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.map((key, value) {
      return MapEntry(key.toString(), value.toString());
    });
  }
}

