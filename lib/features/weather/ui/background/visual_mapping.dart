import 'package:claudy/features/weather/ui/background/weather_background.dart';

WeatherVisual mapOpenWeatherCode(int code, {bool isDaytime = true}) {
  if (code >= 200 && code <= 232) return WeatherVisual.thunder;
  if (code >= 300 && code <= 321) return WeatherVisual.rain;
  if (code >= 500 && code <= 531) return WeatherVisual.rain;
  if (code >= 600 && code <= 622) return WeatherVisual.snow;
  if (code == 800) {
    return isDaytime ? WeatherVisual.clear : WeatherVisual.clearNight;
  }
  if (code >= 801 && code <= 804) return WeatherVisual.clouds;
  if (code >= 701 && code <= 781) return WeatherVisual.fog;
  return WeatherVisual.clouds;
}

/// A moment counts as daytime when it falls inside [sunrise, sunset).
/// Unknown times default to daytime so existing visuals stay unchanged.
bool isDaytimeNow({
  required DateTime now,
  DateTime? sunrise,
  DateTime? sunset,
}) {
  if (sunrise == null || sunset == null) return true;
  return !now.isBefore(sunrise) && now.isBefore(sunset);
}
