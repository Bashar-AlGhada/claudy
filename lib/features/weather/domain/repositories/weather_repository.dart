import 'package:claudy/core/result/app_result.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';

abstract class WeatherRepository {
  Future<AppResult<WeatherReading>> getWeather(
    GeoCoordinate coordinate, {
    required int hours,
    required int days,
    bool forceRefresh = false,
  });
}
