import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';

abstract class WeatherCache {
  Future<WeatherSnapshot?> read(String key);
  Future<void> write(String key, WeatherSnapshot snapshot);
  Future<void> delete(String key);
}

