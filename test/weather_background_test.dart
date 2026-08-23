import 'package:flutter_test/flutter_test.dart';
import 'package:claudy/features/weather/data/open_meteo/open_meteo_provider.dart';
import 'package:claudy/features/weather/ui/background/weather_background.dart';
import 'package:claudy/features/weather/ui/background/visual_mapping.dart';

void main() {
  test('maps OpenWeather codes to WeatherVisual', () {
    expect(mapOpenWeatherCode(800), WeatherVisual.clear);
    expect(mapOpenWeatherCode(801), WeatherVisual.clouds);
    expect(mapOpenWeatherCode(500), WeatherVisual.rain);
    expect(mapOpenWeatherCode(600), WeatherVisual.snow);
    expect(mapOpenWeatherCode(711), WeatherVisual.fog);
    expect(mapOpenWeatherCode(201), WeatherVisual.thunder);
    expect(mapOpenWeatherCode(9999), WeatherVisual.clouds);
  });

  test('maps WMO codes into the OpenWeather space', () {
    // Clear and mainly-clear both read as clear so a visually bright sky
    // is not painted with full cloud puffs.
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(0), 800);
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(1), 800);
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(2), 801);
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(3), 804);
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(45), 741);
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(61), 500);
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(71), 600);
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(95), 201);
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(96), 202);
    expect(OpenMeteoProvider.toOpenWeatherConditionCode(999), 804);
  });

  test('clear codes switch to night visual after sunset', () {
    expect(mapOpenWeatherCode(800, isDaytime: false), WeatherVisual.clearNight);
    expect(mapOpenWeatherCode(800, isDaytime: true), WeatherVisual.clear);
    // Precipitation/cloud visuals are shared between day and night.
    expect(mapOpenWeatherCode(801, isDaytime: false), WeatherVisual.clouds);
  });

  test('isDaytimeNow brackets the day by sunrise and sunset', () {
    DateTime at(int hour, int minute) => DateTime(2026, 1, 10, hour, minute);
    const sunriseAt = 8, sunsetAt = 17;

    expect(
      isDaytimeNow(now: at(12, 0), sunrise: at(sunriseAt, 30), sunset: at(sunsetAt, 0)),
      isTrue,
    );
    expect(
      isDaytimeNow(now: at(21, 0), sunrise: at(sunriseAt, 30), sunset: at(sunsetAt, 0)),
      isFalse,
    );
    expect(isDaytimeNow(now: at(3, 0)), isTrue, reason: 'unknown times default to daytime');
    expect(
      isDaytimeNow(now: at(sunriseAt, 30), sunrise: at(sunriseAt, 30), sunset: at(sunsetAt, 0)),
      isTrue,
      reason: 'sunrise itself counts as daytime',
    );
  });
}
