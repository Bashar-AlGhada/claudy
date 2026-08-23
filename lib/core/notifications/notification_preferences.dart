import 'package:claudy/core/logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum WeatherAlertType { rainSoon, extremeHeat }

class NotificationPreferences {
  const NotificationPreferences({required this.enabled, required this.rainSoon, required this.extremeHeat, required this.lastSentEpochMsByType});

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

final notificationPreferencesProvider = AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
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
      lastSentEpochMsByType: {WeatherAlertType.rainSoon: ?lastRainSoon, WeatherAlertType.extremeHeat: ?lastExtremeHeat},
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await _writeBool(_keyEnabled, enabled);
    _update((p) => _copy(p, enabled: enabled));
  }

  Future<void> setRainSoon(bool enabled) async {
    await _writeBool(_keyRainSoon, enabled);
    _update((p) => _copy(p, rainSoon: enabled));
  }

  Future<void> setExtremeHeat(bool enabled) async {
    await _writeBool(_keyExtremeHeat, enabled);
    _update((p) => _copy(p, extremeHeat: enabled));
  }

  Future<void> markSent(WeatherAlertType type, DateTime sentAt) async {
    final prefs = await SharedPreferences.getInstance();
    final epoch = sentAt.millisecondsSinceEpoch;
    final key = switch (type) {
      WeatherAlertType.rainSoon => _keyLastSentRainSoon,
      WeatherAlertType.extremeHeat => _keyLastSentExtremeHeat,
    };
    await prefs.setInt(key, epoch);
    _update(
      (p) => _copy(
        p,
        lastSentEpochMsByType: {...p.lastSentEpochMsByType, type: epoch},
      ),
    );
  }

  static Future<void> _writeBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _update(NotificationPreferences Function(NotificationPreferences) transform) {
    final current = state.value;
    if (current == null) {
      AppLogger.warn('Notification preference patch dropped; state not ready');
      return;
    }
    state = AsyncData(transform(current));
  }

  static NotificationPreferences _copy(
    NotificationPreferences p, {
    bool? enabled,
    bool? rainSoon,
    bool? extremeHeat,
    Map<WeatherAlertType, int>? lastSentEpochMsByType,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? p.enabled,
      rainSoon: rainSoon ?? p.rainSoon,
      extremeHeat: extremeHeat ?? p.extremeHeat,
      lastSentEpochMsByType:
          lastSentEpochMsByType ?? p.lastSentEpochMsByType,
    );
  }
}
