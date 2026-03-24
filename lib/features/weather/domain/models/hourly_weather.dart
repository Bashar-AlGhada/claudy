class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperatureC,
    required this.precipProbabilityPercent,
    required this.conditionCode,
    required this.windSpeedMps,
    required this.feelsLikeC,
    required this.uvIndex,
  });

  final DateTime time;
  final double temperatureC;
  final int precipProbabilityPercent;
  final int conditionCode;
  final double windSpeedMps;
  final double feelsLikeC;
  final int uvIndex;
}

