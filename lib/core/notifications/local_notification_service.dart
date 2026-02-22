import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/notifications/notification_service.dart';
import 'package:claudy/core/notifications/weather_alert_notification.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  @override
  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> showTestNotification() async {
    if (kIsWeb) return;
    await requestPermissions();
    await showWeatherAlert(
      WeatherAlertNotification(
        id: 0,
        title: LocaleKeys.appTitle.tr,
        body: LocaleKeys.notificationsEnabled.tr,
      ),
    );
  }

  @override
  Future<void> showWeatherAlert(WeatherAlertNotification notification) async {
    if (kIsWeb) return;

    final androidDetails = AndroidNotificationDetails(
      'claudy_weather_alerts',
      LocaleKeys.notificationsChannelAlerts.tr,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(notification.id, notification.title, notification.body, details);
  }
}
