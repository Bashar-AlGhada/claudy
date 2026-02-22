import 'package:claudy/core/notifications/notification_preferences.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';

class WeatherAlertEvaluator {
  static WeatherAlertType? evaluate(
    WeatherReading reading,
    NotificationPreferences preferences,
    DateTime now,
  ) {
    if (!preferences.enabled) return null;
    if (reading.source != WeatherDataSource.network || reading.isStale) return null;

    if (_rainSoon(reading, now) && preferences.isEnabledFor(WeatherAlertType.rainSoon)) {
      return WeatherAlertType.rainSoon;
    }

    if (_extremeHeat(reading) && preferences.isEnabledFor(WeatherAlertType.extremeHeat)) {
      return WeatherAlertType.extremeHeat;
    }

    return null;
  }

  static bool _rainSoon(WeatherReading reading, DateTime now) {
    final upcoming = reading.snapshot.hourly.where((h) {
      final delta = h.time.difference(now);
      return !delta.isNegative && delta <= const Duration(hours: 3);
    });

    final willRainSoon = upcoming.any((h) => h.precipProbabilityPercent >= 60);
    return willRainSoon;
  }

  static bool _extremeHeat(WeatherReading reading) {
    return reading.snapshot.current.temperatureC >= 32;
  }
}
