class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperatureC,
    required this.precipProbabilityPercent,
    required this.conditionCode,
  });

  final DateTime time;
  final double temperatureC;
  final int precipProbabilityPercent;
  final int conditionCode;
}

