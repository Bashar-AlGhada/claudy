class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.minTemperatureC,
    required this.maxTemperatureC,
    required this.conditionCode,
    required this.uvIndex,
    this.sunrise,
    this.sunset,
    required this.precipMm,
    required this.precipProbabilityPercent,
    required this.windSpeedMps,
  });

  final DateTime date;
  final double minTemperatureC;
  final double maxTemperatureC;
  final int conditionCode;
  final int uvIndex;
  final DateTime? sunrise;
  final DateTime? sunset;
  final double precipMm;
  final int precipProbabilityPercent;
  final double windSpeedMps;
}

