class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.minTemperatureC,
    required this.maxTemperatureC,
    required this.conditionCode,
  });

  final DateTime date;
  final double minTemperatureC;
  final double maxTemperatureC;
  final int conditionCode;
}

