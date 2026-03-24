import 'package:claudy/core/config/app_config.dart';
import 'package:claudy/features/weather/data/open_meteo/open_meteo_provider.dart';
import 'package:claudy/features/weather/data/openweather/openweather_provider.dart';
import 'package:claudy/features/weather/data/weather_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeWeatherProvider = Provider<WeatherProvider>((ref) {
  return switch (AppConfig.weatherProvider) {
    'openmeteo' => ref.watch(openMeteoProvider),
    'openweather' => ref.watch(openWeatherProvider),
    _ => ref.watch(openMeteoProvider),
  };
});

