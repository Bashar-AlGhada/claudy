import 'package:claudy/core/notifications/weather_alert_notification.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> requestPermissions();
  Future<void> showTestNotification();
  Future<void> showWeatherAlert(WeatherAlertNotification notification);
}
