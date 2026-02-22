import 'package:claudy/features/weather/data/cache/hive_weather_cache.dart';
import 'package:claudy/features/weather/data/cache/weather_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final weatherCacheProvider = FutureProvider<WeatherCache>((ref) async {
  final box = await Hive.openBox(HiveWeatherCache.boxName);
  return HiveWeatherCache(box: box);
});

