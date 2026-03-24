import 'package:claudy/core/notifications/notification_preferences.dart';
import 'package:claudy/core/notifications/weather_alert_evaluator.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rain soon alert triggers when hourly precip is high', () {
    final now = DateTime(2026, 2, 21, 12, 0);
    final reading = WeatherReading(
      snapshot: WeatherSnapshot(
        coordinate: const GeoCoordinate(lat: 1, lon: 2),
        providerName: 'Fake',
        fetchedAt: now,
        current: CurrentWeather(
          temperatureC: 10,
          feelsLikeC: 10,
          humidityPercent: 50,
          windSpeedMps: 2,
          conditionCode: 800,
          observedAt: now,
          uvIndex: 2,
          visibilityKm: 10,
          pressureHpa: 1012,
          windGustMps: 3,
          windDegrees: 180,
        ),
        hourly: [
          HourlyWeather(
            time: now.add(const Duration(hours: 1)),
            temperatureC: 10,
            precipProbabilityPercent: 70,
            conditionCode: 500,
            windSpeedMps: 2,
            feelsLikeC: 10,
            uvIndex: 1,
          ),
        ],
        daily: [
          DailyWeather(
            date: DateTime(2026, 2, 21),
            minTemperatureC: 8,
            maxTemperatureC: 12,
            conditionCode: 800,
            uvIndex: 4,
            precipMm: 1,
            precipProbabilityPercent: 70,
            windSpeedMps: 2,
          ),
        ],
      ),
      isStale: false,
      source: WeatherDataSource.network,
    );

    const prefs = NotificationPreferences(
      enabled: true,
      rainSoon: true,
      extremeHeat: false,
      lastSentEpochMsByType: {},
    );

    final type = WeatherAlertEvaluator.evaluate(reading, prefs, now);
    expect(type, WeatherAlertType.rainSoon);
  });

  test('Extreme heat alert triggers when current temperature is high', () {
    final now = DateTime(2026, 2, 21, 12, 0);
    final reading = WeatherReading(
      snapshot: WeatherSnapshot(
        coordinate: const GeoCoordinate(lat: 1, lon: 2),
        providerName: 'Fake',
        fetchedAt: now,
        current: CurrentWeather(
          temperatureC: 35,
          feelsLikeC: 35,
          humidityPercent: 40,
          windSpeedMps: 2,
          conditionCode: 800,
          observedAt: now,
          uvIndex: 9,
          visibilityKm: 10,
          pressureHpa: 1010,
          windGustMps: 4,
          windDegrees: 160,
        ),
        hourly: const [],
        daily: const [],
      ),
      isStale: false,
      source: WeatherDataSource.network,
    );

    const prefs = NotificationPreferences(
      enabled: true,
      rainSoon: false,
      extremeHeat: true,
      lastSentEpochMsByType: {},
    );

    final type = WeatherAlertEvaluator.evaluate(reading, prefs, now);
    expect(type, WeatherAlertType.extremeHeat);
  });
}
