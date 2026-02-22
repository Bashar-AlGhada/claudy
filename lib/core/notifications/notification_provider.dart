import 'package:claudy/core/notifications/local_notification_service.dart';
import 'package:claudy/core/notifications/noop_notification_service.dart';
import 'package:claudy/core/notifications/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  if (kIsWeb) return NoopNotificationService();
  return LocalNotificationService();
});

