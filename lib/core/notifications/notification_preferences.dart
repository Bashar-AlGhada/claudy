import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeatherAlertType { rainSoon, extremeHeat }

class NotificationPreferences {
  const NotificationPreferences({
    required this.enabled,
    required this.rainSoon,
    required this.extremeHeat,
    required this.lastSentEpochMsByType,
  });

  final bool enabled;
  final bool rainSoon;
  final bool extremeHeat;
  final Map<WeatherAlertType, int> lastSentEpochMsByType;

  bool isEnabledFor(WeatherAlertType type) {
    if (!enabled) return false;
    return switch (type) {
      WeatherAlertType.rainSoon => rainSoon,
      WeatherAlertType.extremeHeat => extremeHeat,
    };
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  NotificationPreferencesNotifier.new,
);

class NotificationPreferencesNotifier extends AsyncNotifier<NotificationPreferences> {
  static const _keyEnabled = 'settings.notifications.enabled';
  static const _keyRainSoon = 'settings.notifications.rainSoon';
  static const _keyExtremeHeat = 'settings.notifications.extremeHeat';
  static const _keyLastSentRainSoon = 'settings.notifications.lastSent.rainSoon';
  static const _keyLastSentExtremeHeat = 'settings.notifications.lastSent.extremeHeat';

  @override
  Future<NotificationPreferences> build() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final rainSoon = prefs.getBool(_keyRainSoon) ?? false;
    final extremeHeat = prefs.getBool(_keyExtremeHeat) ?? false;
    final lastRainSoon = prefs.getInt(_keyLastSentRainSoon);
    final lastExtremeHeat = prefs.getInt(_keyLastSentExtremeHeat);
    return NotificationPreferences(
      enabled: enabled,
      rainSoon: rainSoon,
      extremeHeat: extremeHeat,
      lastSentEpochMsByType: {
        if (lastRainSoon != null) WeatherAlertType.rainSoon: lastRainSoon,
        if (lastExtremeHeat != null) WeatherAlertType.extremeHeat: lastExtremeHeat,
      },
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    state = AsyncData(await build());
  }

  Future<void> setRainSoon(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRainSoon, enabled);
    state = AsyncData(await build());
  }

  Future<void> setExtremeHeat(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExtremeHeat, enabled);
    state = AsyncData(await build());
  }

  Future<void> markSent(WeatherAlertType type, DateTime sentAt) async {
    final prefs = await SharedPreferences.getInstance();
    final epoch = sentAt.millisecondsSinceEpoch;
    switch (type) {
      case WeatherAlertType.rainSoon:
        await prefs.setInt(_keyLastSentRainSoon, epoch);
        break;
      case WeatherAlertType.extremeHeat:
        await prefs.setInt(_keyLastSentExtremeHeat, epoch);
        break;
    }
    state = AsyncData(await build());
  }
}

