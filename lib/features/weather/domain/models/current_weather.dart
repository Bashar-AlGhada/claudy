class CurrentWeather {
  const CurrentWeather({
    required this.temperatureC,
    required this.feelsLikeC,
    required this.humidityPercent,
    required this.windSpeedMps,
    required this.conditionCode,
    required this.observedAt,
    required this.uvIndex,
    this.aqi,
    required this.visibilityKm,
    required this.pressureHpa,
    this.sunrise,
    this.sunset,
    required this.windGustMps,
    required this.windDegrees,
    this.description,
  });

  final double temperatureC;
  final double feelsLikeC;
  final int humidityPercent;
  final double windSpeedMps;
  final int conditionCode;
  final DateTime observedAt;
  final int uvIndex;
  final int? aqi;
  final double visibilityKm;
  final double pressureHpa;
  final DateTime? sunrise;
  final DateTime? sunset;
  final double windGustMps;
  final int windDegrees;
  final String? description;
}

