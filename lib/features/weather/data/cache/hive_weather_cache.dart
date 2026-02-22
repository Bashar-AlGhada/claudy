import 'package:claudy/features/weather/data/cache/weather_cache.dart';
import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';
import 'package:hive/hive.dart';

class HiveWeatherCache implements WeatherCache {
  HiveWeatherCache({required Box box}) : _box = box;

  final Box _box;

  static const boxName = 'weather_cache_v1';
  static const schemaVersion = 1;

  @override
  Future<WeatherSnapshot?> read(String key) async {
    final raw = _box.get(key);
    if (raw is! Map) return null;
    if (raw['v'] != schemaVersion) return null;
    return WeatherSnapshot.fromJson(raw['data']);
  }

  @override
  Future<void> write(String key, WeatherSnapshot snapshot) async {
    await _box.put(key, {'v': schemaVersion, 'data': snapshot.toJson()});
  }

  @override
  Future<void> delete(String key) async {
    await _box.delete(key);
  }
}

