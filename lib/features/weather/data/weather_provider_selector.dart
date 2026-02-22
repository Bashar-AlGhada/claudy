import 'package:claudy/core/config/app_config.dart';
import 'package:claudy/features/weather/data/openweather/openweather_provider.dart';
import 'package:claudy/features/weather/data/weather_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeWeatherProvider = Provider<WeatherProvider>((ref) {
  return switch (AppConfig.weatherProvider) {
    'openweather' => ref.watch(openWeatherProvider),
    _ => ref.watch(openWeatherProvider),
  };
});

