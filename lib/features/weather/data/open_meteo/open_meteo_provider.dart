import 'package:claudy/core/errors/app_exception.dart';
import 'package:claudy/core/http/dio_client.dart';
import 'package:claudy/features/weather/data/weather_provider.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final openMeteoProvider = Provider<WeatherProvider>((ref) {
  final dio = ref.watch(dioProvider);
  return OpenMeteoProvider(dio: dio);
});

class OpenMeteoProvider implements WeatherProvider {
  OpenMeteoProvider({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  String get attributionName => 'Open-Meteo';

  @override
  Future<CurrentWeather> getCurrent(GeoCoordinate coordinate) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': coordinate.lat,
        'longitude': coordinate.lon,
        'current':
            'temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code',
        'timezone': 'auto',
      },
    );

    final body = response.data;
    if (body == null) {
      throw const MappingException('Empty Open-Meteo current response');
    }

    final current = body['current'];
    if (current is! Map) {
      throw const MappingException('Invalid Open-Meteo current payload');
    }

    final observedAt = DateTime.tryParse(current['time']?.toString() ?? '');
    final temperature = _numToDouble(current['temperature_2m']);
    final feelsLike = _numToDouble(current['apparent_temperature']);
    final humidity = _numToInt(current['relative_humidity_2m']);
    final windSpeed = _numToDouble(current['wind_speed_10m']);
    final weatherCode = _numToInt(current['weather_code']);

    if (observedAt == null) {
      throw const MappingException('Invalid Open-Meteo current.time');
    }

    return CurrentWeather(
      temperatureC: temperature,
      feelsLikeC: feelsLike,
      humidityPercent: humidity.clamp(0, 100),
      windSpeedMps: windSpeed,
      conditionCode: _toOpenWeatherConditionCode(weatherCode),
      observedAt: observedAt,
    );
  }

  @override
  Future<List<HourlyWeather>> getHourly(GeoCoordinate coordinate, {required int hours}) async {
    if (hours <= 0) return const [];

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': coordinate.lat,
        'longitude': coordinate.lon,
        'hourly': 'temperature_2m,precipitation_probability,weather_code',
        'forecast_hours': hours,
        'timezone': 'auto',
      },
    );

    final body = response.data;
    if (body == null) {
      throw const MappingException('Empty Open-Meteo hourly response');
    }

    final hourly = body['hourly'];
    if (hourly is! Map) {
      throw const MappingException('Invalid Open-Meteo hourly payload');
    }

    final times = hourly['time'];
    final temperatures = hourly['temperature_2m'];
    final precip = hourly['precipitation_probability'];
    final codes = hourly['weather_code'];

    if (times is! List || temperatures is! List || precip is! List || codes is! List) {
      throw const MappingException('Invalid Open-Meteo hourly arrays');
    }

    final count = [times.length, temperatures.length, precip.length, codes.length]
        .reduce((a, b) => a < b ? a : b);
    final result = <HourlyWeather>[];
    for (var i = 0; i < count; i++) {
      final time = DateTime.tryParse(times[i]?.toString() ?? '');
      if (time == null) continue;
      final temperature = _safeNumToDouble(temperatures[i]);
      final precipPercent = _safeNumToInt(precip[i]);
      final weatherCode = _safeNumToInt(codes[i]);
      if (temperature == null || precipPercent == null || weatherCode == null) {
        continue;
      }
      result.add(
        HourlyWeather(
          time: time,
          temperatureC: temperature,
          precipProbabilityPercent: precipPercent.clamp(0, 100),
          conditionCode: _toOpenWeatherConditionCode(weatherCode),
        ),
      );
      if (result.length >= hours) break;
    }
    return result;
  }

  @override
  Future<List<DailyWeather>> getDaily(GeoCoordinate coordinate, {required int days}) async {
    if (days <= 0) return const [];

    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': coordinate.lat,
        'longitude': coordinate.lon,
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'forecast_days': days,
        'timezone': 'auto',
      },
    );

    final body = response.data;
    if (body == null) {
      throw const MappingException('Empty Open-Meteo daily response');
    }

    final daily = body['daily'];
    if (daily is! Map) {
      throw const MappingException('Invalid Open-Meteo daily payload');
    }

    final times = daily['time'];
    final minTemp = daily['temperature_2m_min'];
    final maxTemp = daily['temperature_2m_max'];
    final codes = daily['weather_code'];

    if (times is! List || minTemp is! List || maxTemp is! List || codes is! List) {
      throw const MappingException('Invalid Open-Meteo daily arrays');
    }

    final count = [times.length, minTemp.length, maxTemp.length, codes.length]
        .reduce((a, b) => a < b ? a : b);
    final result = <DailyWeather>[];
    for (var i = 0; i < count; i++) {
      final date = DateTime.tryParse(times[i]?.toString() ?? '');
      if (date == null) continue;
      final low = _safeNumToDouble(minTemp[i]);
      final high = _safeNumToDouble(maxTemp[i]);
      final weatherCode = _safeNumToInt(codes[i]);
      if (low == null || high == null || weatherCode == null) continue;

      result.add(
        DailyWeather(
          date: DateTime(date.year, date.month, date.day),
          minTemperatureC: low,
          maxTemperatureC: high,
          conditionCode: _toOpenWeatherConditionCode(weatherCode),
        ),
      );
      if (result.length >= days) break;
    }
    return result;
  }

  double _numToDouble(Object? value) {
    if (value is num) return value.toDouble();
    throw const MappingException('Expected number');
  }

  int _numToInt(Object? value) {
    if (value is num) return value.toInt();
    throw const MappingException('Expected int');
  }

  double? _safeNumToDouble(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  int? _safeNumToInt(Object? value) {
    if (value is num) return value.toInt();
    return null;
  }

  int _toOpenWeatherConditionCode(int code) {
    switch (code) {
      case 0:
        return 800;
      case 1:
      case 2:
        return 801;
      case 3:
        return 804;
      case 45:
      case 48:
        return 741;
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 300;
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 500;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 600;
      case 95:
        return 201;
      case 96:
      case 99:
        return 202;
      default:
        return 804;
    }
  }
}
