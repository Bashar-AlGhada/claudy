import 'package:claudy/app/app.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';
import 'package:claudy/features/weather/ui/background/sun_animation.dart';
import 'package:claudy/features/weather/providers/weather_reading_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Low power disables animated background', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.lowPower': true,
      'settings.location.mode': 'manual',
      'settings.location.manualLat': 52.37,
      'settings.location.manualLon': 4.89,
    });

    await tester.pumpWidget(
      App(
        overrides: [
          weatherReadingProvider.overrideWith(_TestWeatherReadingNotifier.new),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AnimatedContainer), findsOneWidget);
    expect(find.byType(SunAnimation), findsNothing);
  });

  testWidgets('Normal mode uses animated background', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.lowPower': false,
      'settings.location.mode': 'manual',
      'settings.location.manualLat': 52.37,
      'settings.location.manualLon': 4.89,
    });

    await tester.pumpWidget(
      App(
        overrides: [
          weatherReadingProvider.overrideWith(_TestWeatherReadingNotifier.new),
        ],
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AnimatedContainer), findsOneWidget);
    expect(find.byType(SunAnimation), findsOneWidget);
  });
}

WeatherReading _reading() {
  final now = DateTime(2026, 1, 1, 12);
  return WeatherReading(
    snapshot: WeatherSnapshot(
      coordinate: const GeoCoordinate(lat: 52.37, lon: 4.89),
      providerName: 'Test',
      fetchedAt: now,
      current: CurrentWeather(
        temperatureC: 10,
        feelsLikeC: 9,
        humidityPercent: 50,
        windSpeedMps: 1.2,
        conditionCode: 800,
        observedAt: now,
        uvIndex: 2,
        visibilityKm: 10,
        pressureHpa: 1012,
        windGustMps: 1.8,
        windDegrees: 180,
      ),
      hourly: [
        HourlyWeather(
          time: now,
          temperatureC: 10,
          precipProbabilityPercent: 0,
          conditionCode: 800,
          windSpeedMps: 1.2,
          feelsLikeC: 9,
          uvIndex: 2,
        ),
      ],
      daily: [
        DailyWeather(
          date: DateTime(now.year, now.month, now.day),
          minTemperatureC: 8,
          maxTemperatureC: 12,
          conditionCode: 800,
          uvIndex: 3,
          precipMm: 0,
          precipProbabilityPercent: 0,
          windSpeedMps: 1.5,
        ),
      ],
    ),
    isStale: false,
    source: WeatherDataSource.cache,
  );
}

class _TestWeatherReadingNotifier extends WeatherReadingNotifier {
  @override
  Future<WeatherReading?> build() async => _reading();
}
