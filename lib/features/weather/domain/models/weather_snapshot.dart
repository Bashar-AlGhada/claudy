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
        'uvIndex': current.uvIndex,
        'aqi': current.aqi,
        'visibilityKm': current.visibilityKm,
        'pressureHpa': current.pressureHpa,
        'sunrise': current.sunrise?.toIso8601String(),
        'sunset': current.sunset?.toIso8601String(),
        'windGustMps': current.windGustMps,
        'windDegrees': current.windDegrees,
        'description': current.description,
      },
      'hourly': [
        for (final h in hourly)
          {
            'time': h.time.toIso8601String(),
            'temperatureC': h.temperatureC,
            'precipProbabilityPercent': h.precipProbabilityPercent,
            'conditionCode': h.conditionCode,
            'windSpeedMps': h.windSpeedMps,
            'feelsLikeC': h.feelsLikeC,
            'uvIndex': h.uvIndex,
          },
      ],
      'daily': [
        for (final d in daily)
          {
            'date': d.date.toIso8601String(),
            'minTemperatureC': d.minTemperatureC,
            'maxTemperatureC': d.maxTemperatureC,
            'conditionCode': d.conditionCode,
            'uvIndex': d.uvIndex,
            'sunrise': d.sunrise?.toIso8601String(),
            'sunset': d.sunset?.toIso8601String(),
            'precipMm': d.precipMm,
            'precipProbabilityPercent': d.precipProbabilityPercent,
            'windSpeedMps': d.windSpeedMps,
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
    final uvIndex = raw['uvIndex'];
    final aqi = raw['aqi'];
    final visibilityKm = raw['visibilityKm'];
    final pressureHpa = raw['pressureHpa'];
    final sunrise = raw['sunrise'];
    final sunset = raw['sunset'];
    final windGustMps = raw['windGustMps'];
    final windDegrees = raw['windDegrees'];
    final description = raw['description'];

    if (temperatureC is! num) return null;
    if (feelsLikeC is! num) return null;
    if (humidityPercent is! num) return null;
    if (windSpeedMps is! num) return null;
    if (conditionCode is! num) return null;
    final observedAtDt = DateTime.tryParse(observedAt?.toString() ?? '');
    if (observedAtDt == null) return null;
    if (uvIndex is! num) return null;
    if (visibilityKm is! num) return null;
    if (pressureHpa is! num) return null;
    if (windGustMps is! num) return null;
    if (windDegrees is! num) return null;

    return CurrentWeather(
      temperatureC: temperatureC.toDouble(),
      feelsLikeC: feelsLikeC.toDouble(),
      humidityPercent: humidityPercent.toInt().clamp(0, 100),
      windSpeedMps: windSpeedMps.toDouble(),
      conditionCode: conditionCode.toInt(),
      observedAt: observedAtDt,
      uvIndex: uvIndex.toInt(),
      aqi: aqi is num ? aqi.toInt() : null,
      visibilityKm: visibilityKm.toDouble(),
      pressureHpa: pressureHpa.toDouble(),
      sunrise: DateTime.tryParse(sunrise?.toString() ?? ''),
      sunset: DateTime.tryParse(sunset?.toString() ?? ''),
      windGustMps: windGustMps.toDouble(),
      windDegrees: windDegrees.toInt(),
      description: description is String ? description : null,
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
      final windSpeedMps = item['windSpeedMps'];
      final feelsLikeC = item['feelsLikeC'];
      final uvIndex = item['uvIndex'];
      if (time == null) continue;
      if (temperatureC is! num) continue;
      if (precip is! num) continue;
      if (code is! num) continue;
      if (windSpeedMps is! num) continue;
      if (feelsLikeC is! num) continue;
      if (uvIndex is! num) continue;
      result.add(
        HourlyWeather(
          time: time,
          temperatureC: temperatureC.toDouble(),
          precipProbabilityPercent: precip.toInt().clamp(0, 100),
          conditionCode: code.toInt(),
          windSpeedMps: windSpeedMps.toDouble(),
          feelsLikeC: feelsLikeC.toDouble(),
          uvIndex: uvIndex.toInt(),
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
      final uvIndex = item['uvIndex'];
      final sunrise = item['sunrise'];
      final sunset = item['sunset'];
      final precipMm = item['precipMm'];
      final precipProbabilityPercent = item['precipProbabilityPercent'];
      final windSpeedMps = item['windSpeedMps'];
      if (date == null) continue;
      if (minTemperatureC is! num) continue;
      if (maxTemperatureC is! num) continue;
      if (code is! num) continue;
      if (uvIndex is! num) continue;
      if (precipMm is! num) continue;
      if (precipProbabilityPercent is! num) continue;
      if (windSpeedMps is! num) continue;
      result.add(
        DailyWeather(
          date: DateTime(date.year, date.month, date.day),
          minTemperatureC: minTemperatureC.toDouble(),
          maxTemperatureC: maxTemperatureC.toDouble(),
          conditionCode: code.toInt(),
          uvIndex: uvIndex.toInt(),
          sunrise: DateTime.tryParse(sunrise?.toString() ?? ''),
          sunset: DateTime.tryParse(sunset?.toString() ?? ''),
          precipMm: precipMm.toDouble(),
          precipProbabilityPercent: precipProbabilityPercent.toInt().clamp(0, 100),
          windSpeedMps: windSpeedMps.toDouble(),
        ),
      );
    }
    return result;
  }
}

