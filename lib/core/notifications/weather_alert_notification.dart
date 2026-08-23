class WeatherAlertNotification {
  const WeatherAlertNotification({
    required this.id,
    required this.title,
    required this.body,
  });

  static const int rainSoonId = 1001;
  static const int extremeHeatId = 1002;

  final int id;
  final String title;
  final String body;
}

