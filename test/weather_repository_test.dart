import 'package:claudy/core/errors/app_failure.dart';
import 'package:claudy/core/time/clock.dart';
import 'package:claudy/core/time/clock_provider.dart';
import 'package:claudy/features/weather/data/cache/weather_cache.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_provider.dart';
import 'package:claudy/features/weather/data/weather_provider.dart';
import 'package:claudy/features/weather/data/weather_provider_selector.dart';
import 'package:claudy/features/weather/data/weather_repository_impl.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:claudy/core/http/interceptors/rate_limit_interceptor.dart';

void main() {
  test('Returns fresh cache without hitting network', () async {
    final now = DateTime(2026, 1, 1, 12);
    final cache = _FakeCache();
    final provider = _FakeWeatherProvider();
    final coordinate = const GeoCoordinate(lat: 1, lon: 2);

    await cache.write(
      'weather:${provider.attributionName}:1.0,2.0',
      _snapshot(coordinate, now: now, provider: provider.attributionName),
    );

    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(_FixedClock(now)),
        weatherCacheProvider.overrideWith((ref) async => cache),
        activeWeatherProvider.overrideWithValue(provider),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(weatherRepositoryProvider);
    final result = await repo.getWeather(coordinate, hours: 16, days: 5);

    result.fold(
      (failure) => fail('Expected success, got $failure'),
      (reading) {
        expect(reading.source, isNotNull);
        expect(reading.isStale, isFalse);
      },
    );
    expect(provider.calls, 0);
  });

  test('Returns stale cache when network fails', () async {
    final now = DateTime(2026, 1, 1, 12);
    final cache = _FakeCache();
    final provider = _FakeWeatherProvider()..error = Exception('fail');
    final coordinate = const GeoCoordinate(lat: 1, lon: 2);

    await cache.write(
      'weather:${provider.attributionName}:1.0,2.0',
      _snapshot(
        coordinate,
        now: now.subtract(const Duration(hours: 2)),
        provider: provider.attributionName,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(_FixedClock(now)),
        weatherCacheProvider.overrideWith((ref) async => cache),
        activeWeatherProvider.overrideWithValue(provider),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(weatherRepositoryProvider);
    final result = await repo.getWeather(coordinate, hours: 16, days: 5);

    result.fold(
      (failure) => fail('Expected success with stale cache, got $failure'),
      (reading) => expect(reading.isStale, isTrue),
    );
    expect(provider.calls, greaterThan(0));
  });

  test('Returns failure when no cache and network fails', () async {
    final now = DateTime(2026, 1, 1, 12);
    final cache = _FakeCache();
    final provider = _FakeWeatherProvider()..error = Exception('fail');
    final coordinate = const GeoCoordinate(lat: 1, lon: 2);

    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(_FixedClock(now)),
        weatherCacheProvider.overrideWith((ref) async => cache),
        activeWeatherProvider.overrideWithValue(provider),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(weatherRepositoryProvider);
    final result = await repo.getWeather(coordinate, hours: 16, days: 5);

    result.fold(
      (failure) => expect(failure, isA<UnknownFailure>()),
      (_) => fail('Expected failure'),
    );
  });

  test('Returns stale cache when rate limited', () async {
    final now = DateTime(2026, 1, 1, 12);
    final cache = _FakeCache();
    final provider = _FakeWeatherProvider()..error = RateLimitActiveException(const Duration(minutes: 2));
    final coordinate = const GeoCoordinate(lat: 1, lon: 2);

    await cache.write(
      'weather:${provider.attributionName}:1.0,2.0',
      _snapshot(
        coordinate,
        now: now.subtract(const Duration(hours: 2)),
        provider: provider.attributionName,
      ),
    );

    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(_FixedClock(now)),
        weatherCacheProvider.overrideWith((ref) async => cache),
        activeWeatherProvider.overrideWithValue(provider),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(weatherRepositoryProvider);
    final result = await repo.getWeather(coordinate, hours: 16, days: 5);
    result.fold(
      (failure) => fail('Expected stale cache success, got $failure'),
      (reading) => expect(reading.isStale, isTrue),
    );
  });

  test('Returns rate limit failure when no cache', () async {
    final now = DateTime(2026, 1, 1, 12);
    final cache = _FakeCache();
    final provider = _FakeWeatherProvider()..error = RateLimitActiveException(const Duration(minutes: 2));
    final coordinate = const GeoCoordinate(lat: 1, lon: 2);

    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(_FixedClock(now)),
        weatherCacheProvider.overrideWith((ref) async => cache),
        activeWeatherProvider.overrideWithValue(provider),
      ],
    );
    addTearDown(container.dispose);

    final repo = container.read(weatherRepositoryProvider);
    final result = await repo.getWeather(coordinate, hours: 16, days: 5);
    result.fold(
      (failure) => expect(failure, isA<RateLimitFailure>()),
      (_) => fail('Expected failure'),
    );
  });
}

WeatherSnapshot _snapshot(
  GeoCoordinate coordinate, {
  required DateTime now,
  required String provider,
}) {
  return WeatherSnapshot(
    coordinate: coordinate,
    providerName: provider,
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
  );
}

class _FixedClock implements Clock {
  _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

class _FakeCache implements WeatherCache {
  final _store = <String, WeatherSnapshot>{};

  @override
  Future<void> delete(String key) async => _store.remove(key);

  @override
  Future<WeatherSnapshot?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, WeatherSnapshot snapshot) async {
    _store[key] = snapshot;
  }
}

class _FakeWeatherProvider implements WeatherProvider {
  int calls = 0;
  Object? error;

  @override
  String get attributionName => 'Fake';

  @override
  Future<CurrentWeather> getCurrent(GeoCoordinate coordinate) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    final now = DateTime(2026, 1, 1, 12);
    return CurrentWeather(
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
    );
  }

  @override
  Future<List<DailyWeather>> getDaily(GeoCoordinate coordinate, {required int days}) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    final now = DateTime(2026, 1, 1);
    return [
      DailyWeather(
        date: now,
        minTemperatureC: 8,
        maxTemperatureC: 12,
        conditionCode: 800,
        uvIndex: 3,
        precipMm: 0,
        precipProbabilityPercent: 0,
        windSpeedMps: 1.5,
      ),
    ];
  }

  @override
  Future<List<HourlyWeather>> getHourly(GeoCoordinate coordinate, {required int hours}) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    final now = DateTime(2026, 1, 1, 12);
    return [
      HourlyWeather(
        time: now,
        temperatureC: 10,
        precipProbabilityPercent: 0,
        conditionCode: 800,
        windSpeedMps: 1.2,
        feelsLikeC: 9,
        uvIndex: 2,
      ),
    ];
  }
}
