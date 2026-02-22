import 'dart:math' as math;

import 'package:claudy/core/config/app_config.dart';
import 'package:claudy/core/errors/app_exception.dart';
import 'package:claudy/core/http/dio_client.dart';
import 'package:claudy/features/weather/data/weather_provider.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final openWeatherProvider = Provider<WeatherProvider>((ref) {
  final dio = ref.watch(dioProvider);
  return OpenWeatherProvider(dio: dio);
});

class OpenWeatherProvider implements WeatherProvider {
  OpenWeatherProvider({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  String get attributionName => 'OpenWeather';

  @override
  Future<CurrentWeather> getCurrent(GeoCoordinate coordinate) async {
    _ensureApiKeyConfigured();
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.openweathermap.org/data/2.5/weather',
      queryParameters: {
        'lat': coordinate.lat,
        'lon': coordinate.lon,
        'appid': AppConfig.openWeatherApiKey,
        'units': 'metric',
      },
    );

    final body = response.data;
    if (body == null) {
      throw const MappingException('Empty OpenWeather current response');
    }

    final main = body['main'];
    final wind = body['wind'];
    final weatherList = body['weather'];
    final dt = body['dt'];
    final tz = body['timezone'];

    if (main is! Map) throw const MappingException('Invalid "main"');
    if (wind is! Map) throw const MappingException('Invalid "wind"');
    if (weatherList is! List || weatherList.isEmpty) {
      throw const MappingException('Invalid "weather"');
    }
    if (dt is! num) throw const MappingException('Invalid "dt"');
    if (tz is! num) throw const MappingException('Invalid "timezone"');

    final temp = _numToDouble(main['temp']);
    final feelsLike = _numToDouble(main['feels_like']);
    final humidity = _numToInt(main['humidity']);
    final windSpeed = _numToDouble(wind['speed']);
    final first = weatherList.first;
    if (first is! Map) throw const MappingException('Invalid weather[0]');
    final code = _numToInt(first['id']);

    return CurrentWeather(
      temperatureC: temp,
      feelsLikeC: feelsLike,
      humidityPercent: humidity.clamp(0, 100),
      windSpeedMps: math.max(0, windSpeed),
      conditionCode: code,
      observedAt: _unixSecondsToLocal(dt.toInt(), tz.toInt()),
    );
  }

  @override
  Future<List<HourlyWeather>> getHourly(
    GeoCoordinate coordinate, {
    required int hours,
  }) async {
    _ensureApiKeyConfigured();
    if (hours <= 0) return [];

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.openweathermap.org/data/2.5/forecast',
      queryParameters: {
        'lat': coordinate.lat,
        'lon': coordinate.lon,
        'appid': AppConfig.openWeatherApiKey,
        'units': 'metric',
      },
    );

    final body = response.data;
    if (body == null) throw const MappingException('Empty OpenWeather forecast response');

    final list = body['list'];
    final city = body['city'];
    if (list is! List) throw const MappingException('Invalid "list"');
    if (city is! Map) throw const MappingException('Invalid "city"');
    final tz = city['timezone'];
    if (tz is! num) throw const MappingException('Invalid city.timezone');
    final tzSeconds = tz.toInt();

    final items = <HourlyWeather>[];
    for (final item in list) {
      if (items.length >= hours) break;
      if (item is! Map) continue;
      final dt = item['dt'];
      final main = item['main'];
      final pop = item['pop'];
      final weather = item['weather'];

      if (dt is! num || main is! Map) continue;
      if (weather is! List || weather.isEmpty || weather.first is! Map) continue;

      final time = _unixSecondsToLocal(dt.toInt(), tzSeconds);
      final temp = _numToDouble(main['temp']);
      final code = _numToInt((weather.first as Map)['id']);
      final popPercent = ((pop is num ? pop.toDouble() : 0) * 100).round().clamp(0, 100);

      items.add(
        HourlyWeather(
          time: time,
          temperatureC: temp,
          precipProbabilityPercent: popPercent,
          conditionCode: code,
        ),
      );
    }

    return items;
  }

  @override
  Future<List<DailyWeather>> getDaily(
    GeoCoordinate coordinate, {
    required int days,
  }) async {
    if (days <= 0) return [];
    final hourly = await getHourly(coordinate, hours: math.min(days * 8, 40));
    if (hourly.isEmpty) return [];

    final byDate = <DateTime, List<HourlyWeather>>{};
    for (final h in hourly) {
      final date = DateTime(h.time.year, h.time.month, h.time.day);
      (byDate[date] ??= []).add(h);
    }

    final sortedDates = byDate.keys.toList()..sort();
    final result = <DailyWeather>[];
    for (final date in sortedDates) {
      if (result.length >= days) break;
      final list = byDate[date]!;
      double minT = list.first.temperatureC;
      double maxT = list.first.temperatureC;
      for (final h in list) {
        minT = math.min(minT, h.temperatureC);
        maxT = math.max(maxT, h.temperatureC);
      }
      final code = list[(list.length / 2).floor()].conditionCode;

      result.add(
        DailyWeather(
          date: date,
          minTemperatureC: minT,
          maxTemperatureC: maxT,
          conditionCode: code,
        ),
      );
    }

    return result;
  }

  void _ensureApiKeyConfigured() {
    if (AppConfig.openWeatherApiKey.isEmpty) {
      throw const ConfigurationException('Missing OpenWeather API key');
    }
  }

  double _numToDouble(Object? value) {
    if (value is num) return value.toDouble();
    throw const MappingException('Expected number');
  }

  int _numToInt(Object? value) {
    if (value is num) return value.toInt();
    throw const MappingException('Expected int');
  }

  DateTime _unixSecondsToLocal(int seconds, int timezoneOffsetSeconds) {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true)
        .add(Duration(seconds: timezoneOffsetSeconds));
  }
}
