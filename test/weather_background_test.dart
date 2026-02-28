import 'package:flutter_test/flutter_test.dart';
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
}
