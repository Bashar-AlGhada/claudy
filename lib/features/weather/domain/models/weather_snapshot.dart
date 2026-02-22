import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.coordinate,
    required this.providerName,
    required this.fetchedAt,
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final GeoCoordinate coordinate;
  final String providerName;
  final DateTime fetchedAt;
  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  Map<String, Object?> toJson() {
    return {
      'lat': coordinate.lat,
      'lon': coordinate.lon,
      'providerName': providerName,
      'fetchedAt': fetchedAt.toIso8601String(),
      'current': {
        'temperatureC': current.temperatureC,
        'feelsLikeC': current.feelsLikeC,
        'humidityPercent': current.humidityPercent,
        'windSpeedMps': current.windSpeedMps,
        'conditionCode': current.conditionCode,
        'observedAt': current.observedAt.toIso8601String(),
      },
      'hourly': [
        for (final h in hourly)
          {
            'time': h.time.toIso8601String(),
            'temperatureC': h.temperatureC,
            'precipProbabilityPercent': h.precipProbabilityPercent,
            'conditionCode': h.conditionCode,
          },
      ],
      'daily': [
        for (final d in daily)
          {
            'date': d.date.toIso8601String(),
            'minTemperatureC': d.minTemperatureC,
            'maxTemperatureC': d.maxTemperatureC,
            'conditionCode': d.conditionCode,
          },
      ],
    };
  }

  static WeatherSnapshot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final lat = raw['lat'];
    final lon = raw['lon'];
    final providerName = raw['providerName'];
    final fetchedAt = raw['fetchedAt'];
    final current = raw['current'];
    final hourly = raw['hourly'];
    final daily = raw['daily'];

    if (lat is! num || lon is! num) return null;
    if (providerName is! String || providerName.isEmpty) return null;
    final fetchedAtDt = DateTime.tryParse(fetchedAt?.toString() ?? '');
    if (fetchedAtDt == null) return null;

    final currentModel = _currentFromJson(current);
    if (currentModel == null) return null;

    final hourlyModels = _hourlyFromJson(hourly);
    final dailyModels = _dailyFromJson(daily);

    return WeatherSnapshot(
      coordinate: GeoCoordinate(lat: lat.toDouble(), lon: lon.toDouble()),
      providerName: providerName,
      fetchedAt: fetchedAtDt,
      current: currentModel,
      hourly: hourlyModels,
      daily: dailyModels,
    );
  }

  static CurrentWeather? _currentFromJson(Object? raw) {
    if (raw is! Map) return null;
    final temperatureC = raw['temperatureC'];
    final feelsLikeC = raw['feelsLikeC'];
    final humidityPercent = raw['humidityPercent'];
    final windSpeedMps = raw['windSpeedMps'];
    final conditionCode = raw['conditionCode'];
    final observedAt = raw['observedAt'];

    if (temperatureC is! num) return null;
    if (feelsLikeC is! num) return null;
    if (humidityPercent is! num) return null;
    if (windSpeedMps is! num) return null;
    if (conditionCode is! num) return null;
    final observedAtDt = DateTime.tryParse(observedAt?.toString() ?? '');
    if (observedAtDt == null) return null;

    return CurrentWeather(
      temperatureC: temperatureC.toDouble(),
      feelsLikeC: feelsLikeC.toDouble(),
      humidityPercent: humidityPercent.toInt().clamp(0, 100),
      windSpeedMps: windSpeedMps.toDouble(),
      conditionCode: conditionCode.toInt(),
      observedAt: observedAtDt,
    );
  }

  static List<HourlyWeather> _hourlyFromJson(Object? raw) {
    if (raw is! List) return const [];
    final result = <HourlyWeather>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final time = DateTime.tryParse(item['time']?.toString() ?? '');
      final temperatureC = item['temperatureC'];
      final precip = item['precipProbabilityPercent'];
      final code = item['conditionCode'];
      if (time == null) continue;
      if (temperatureC is! num) continue;
      if (precip is! num) continue;
      if (code is! num) continue;
      result.add(
        HourlyWeather(
          time: time,
          temperatureC: temperatureC.toDouble(),
          precipProbabilityPercent: precip.toInt().clamp(0, 100),
          conditionCode: code.toInt(),
        ),
      );
    }
    return result;
  }

  static List<DailyWeather> _dailyFromJson(Object? raw) {
    if (raw is! List) return const [];
    final result = <DailyWeather>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final date = DateTime.tryParse(item['date']?.toString() ?? '');
      final minTemperatureC = item['minTemperatureC'];
      final maxTemperatureC = item['maxTemperatureC'];
      final code = item['conditionCode'];
      if (date == null) continue;
      if (minTemperatureC is! num) continue;
      if (maxTemperatureC is! num) continue;
      if (code is! num) continue;
      result.add(
        DailyWeather(
          date: DateTime(date.year, date.month, date.day),
          minTemperatureC: minTemperatureC.toDouble(),
          maxTemperatureC: maxTemperatureC.toDouble(),
          conditionCode: code.toInt(),
        ),
      );
    }
    return result;
  }
}

