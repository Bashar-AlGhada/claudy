import 'dart:io';

import 'package:claudy/core/i18n/i18n_loader.dart';
import 'package:claudy/core/i18n/i18n_store.dart';
import 'package:claudy/core/background/background_scheduler.dart';
import 'package:claudy/core/logging/app_logger.dart';
import 'package:claudy/core/notifications/notification_provider.dart';
import 'package:claudy/core/perf/frame_monitor.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class AppBootstrap {
  static Future<void> initialize() async {
    await _ensureHiveDirectory();
    await Hive.initFlutter();
    await I18nLoader.load();
    Get.addTranslations(I18nStore.keys);
    await BackgroundScheduler.initialize();
    final container = ProviderContainer();
    await container.read(notificationServiceProvider).initialize();
    container.dispose();
    FrameMonitor.start();
  }

  static Future<void> _ensureHiveDirectory() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      await Directory(dir.path).create(recursive: true);
    } catch (e, s) {
      // Redirected/unavailable documents directories would otherwise crash
      // Hive's lock-file creation; log and let the app run without cache.
      AppLogger.warn('Could not prepare documents directory', error: e, stackTrace: s);
    }
  }
}
