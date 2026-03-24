class AppConfig {
  static const weatherProvider = String.fromEnvironment('WEATHER_PROVIDER', defaultValue: 'openmeteo');

  static const openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: '');
}
