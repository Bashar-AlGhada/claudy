import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';

abstract class WeatherProvider {
  String get attributionName;

  Future<CurrentWeather> getCurrent(GeoCoordinate coordinate);

  Future<List<HourlyWeather>> getHourly(GeoCoordinate coordinate, {required int hours});

  Future<List<DailyWeather>> getDaily(GeoCoordinate coordinate, {required int days});
}

