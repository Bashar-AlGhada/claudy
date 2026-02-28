import 'package:claudy/core/i18n/i18n_loader.dart';
import 'package:claudy/core/i18n/i18n_store.dart';
import 'package:claudy/core/background/background_scheduler.dart';
import 'package:claudy/core/notifications/notification_provider.dart';
import 'package:claudy/core/perf/frame_monitor.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await I18nLoader.load();
    Get.addTranslations(I18nStore.keys);
    await BackgroundScheduler.initialize();
    final container = ProviderContainer();
    await container.read(notificationServiceProvider).initialize();
    container.dispose();
    FrameMonitor.start();
  }
}
