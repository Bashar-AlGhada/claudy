import 'package:claudy/core/location/location_client.dart';
import 'package:claudy/core/http/interceptors/rate_limit_interceptor.dart';
import 'package:claudy/core/result/app_result.dart';
import 'package:claudy/features/search/domain/models/place.dart';
import 'package:claudy/features/search/domain/repositories/place_search_repository.dart';
import 'package:claudy/features/weather/data/weather_provider.dart';
import 'package:claudy/features/weather/data/cache/weather_cache.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class FakeLocationClient implements LocationClient {
  FakeLocationClient({required this.serviceEnabled, required this.permission, required this.position});

  bool serviceEnabled;
  LocationPermission permission;
  Position position;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;

  @override
  Future<Position> getCurrentPosition({required LocationSettings settings}) async {
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw Exception('Permission denied');
    }
    return position;
  }
}

class InMemoryWeatherCache implements WeatherCache {
  final Map<String, WeatherSnapshot> _store = {};

  void clear() {
    _store.clear();
  }

  @override
  Future<WeatherSnapshot?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, WeatherSnapshot snapshot) async {
    _store[key] = snapshot;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }
}

enum FakeWeatherMode { online, offline, rateLimited }

class FakeWeatherProvider implements WeatherProvider {
  FakeWeatherProvider({required this.now});

  DateTime now;
  FakeWeatherMode mode = FakeWeatherMode.online;

  @override
  String get attributionName => 'FakeWeather';

  @override
  Future<CurrentWeather> getCurrent(GeoCoordinate coordinate) async {
    _maybeThrow();
    return CurrentWeather(
      temperatureC: 21,
      feelsLikeC: 20,
      humidityPercent: 55,
      windSpeedMps: 3.2,
      conditionCode: 800,
      observedAt: now,
      uvIndex: 4,
      visibilityKm: 10,
      pressureHpa: 1013,
      windGustMps: 4.1,
      windDegrees: 180,
    );
  }

  @override
  Future<List<HourlyWeather>> getHourly(GeoCoordinate coordinate, {required int hours}) async {
    _maybeThrow();
    return List.generate(hours, (i) {
      return HourlyWeather(
        time: now.add(Duration(hours: i)),
        temperatureC: 20 + (i % 3),
        precipProbabilityPercent: i == 1 ? 70 : 10,
        conditionCode: 500,
        windSpeedMps: 3,
        feelsLikeC: 20 + (i % 3),
        uvIndex: i < 6 ? 3 : 0,
      );
    });
  }

  @override
  Future<List<DailyWeather>> getDaily(GeoCoordinate coordinate, {required int days}) async {
    _maybeThrow();
    return List.generate(days, (i) {
      final date = DateTime(now.year, now.month, now.day).add(Duration(days: i));
      return DailyWeather(
        date: date,
        minTemperatureC: 15,
        maxTemperatureC: 24,
        conditionCode: 800,
        uvIndex: 5,
        precipMm: 0,
        precipProbabilityPercent: 10,
        windSpeedMps: 3,
      );
    });
  }

  void _maybeThrow() {
    switch (mode) {
      case FakeWeatherMode.online:
        return;
      case FakeWeatherMode.offline:
        throw DioException(
          requestOptions: RequestOptions(path: '/fake'),
          type: DioExceptionType.connectionError,
          error: Exception('Offline'),
        );
      case FakeWeatherMode.rateLimited:
        throw const RateLimitActiveException(Duration(minutes: 2));
    }
  }
}

class FakePlaceSearchRepository implements PlaceSearchRepository {
  FakePlaceSearchRepository({required this.results});

  final List<Place> results;

  @override
  Future<AppResult<List<Place>>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return const Success([]);
    return Success(results);
  }
}
