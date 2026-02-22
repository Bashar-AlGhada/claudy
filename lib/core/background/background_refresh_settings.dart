import 'package:shared_preferences/shared_preferences.dart';

class BackgroundRefreshSettings {
  static const _keyEnabled = 'settings.backgroundRefresh.enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEnabled) ?? false;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
  }
}

