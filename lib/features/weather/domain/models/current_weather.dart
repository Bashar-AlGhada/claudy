class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidityPercent,
    required this.windSpeedMps,
    required this.conditionCode,
    required this.observedAt,
  });

  final double temperatureC;
  final double feelsLikeC;
  final int humidityPercent;
  final double windSpeedMps;
  final int conditionCode;
  final DateTime observedAt;
}

