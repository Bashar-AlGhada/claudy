import 'package:claudy/core/location/location_client.dart';
import 'package:claudy/core/location/location_client_provider.dart';
import 'package:claudy/features/map/ui/map_page.dart';
import 'package:claudy/features/weather/data/weather_repository_impl.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';
import 'package:claudy/features/weather/domain/repositories/weather_repository.dart';
import 'package:claudy/features/weather/ui/widgets/current_weather_card.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:claudy/core/result/app_result.dart';

void main() {
  testWidgets('Tap on map triggers preview card', (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.location.mode': 'manual',
      'settings.location.manualLat': 52.37,
      'settings.location.manualLon': 4.89,
    });

    final container = ProviderContainer(
      overrides: [
        weatherRepositoryProvider.overrideWithValue(_FakeWeatherRepository()),
        locationClientProvider.overrideWithValue(_NeverLocationClient()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: MapPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tapAt(const Offset(50, 200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CurrentWeatherCard), findsOneWidget);
  });
}

class _FakeWeatherRepository implements WeatherRepository {
  @override
  Future<AppResult<WeatherReading>> getWeather(GeoCoordinate coordinate, {required int hours, required int days, bool forceRefresh = false}) async {
    final now = DateTime(2026, 1, 1, 12);
    return Success(
      WeatherReading(
        snapshot: WeatherSnapshot(
          coordinate: coordinate,
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
        source: WeatherDataSource.network,
      ),
    );
  }
}

class _NeverLocationClient implements LocationClient {
  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.denied;

  @override
  Future<Position> getCurrentPosition({required LocationSettings settings}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isLocationServiceEnabled() async => false;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.denied;
}
