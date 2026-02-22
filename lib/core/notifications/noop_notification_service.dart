import 'package:claudy/core/notifications/notification_service.dart';
import 'package:claudy/core/notifications/weather_alert_notification.dart';

class NoopNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> requestPermissions() async {}

  @override
  Future<void> showTestNotification() async {}

  @override
  Future<void> showWeatherAlert(WeatherAlertNotification notification) async {}
}
