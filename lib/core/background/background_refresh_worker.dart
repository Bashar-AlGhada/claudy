import 'package:claudy/core/background/background_refresh_settings.dart';
import 'package:claudy/core/i18n/i18n_loader.dart';
import 'package:claudy/core/i18n/i18n_store.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/location/location_storage.dart';
import 'package:claudy/core/logging/app_logger.dart';
import 'package:claudy/core/notifications/notification_preferences.dart';
import 'package:claudy/core/notifications/notification_provider.dart';
import 'package:claudy/core/notifications/weather_alert_evaluator.dart';
import 'package:claudy/core/notifications/weather_alert_notification.dart';
import 'package:claudy/features/weather/data/weather_repository_impl.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundRefreshWorker {
  static Future<bool> run() async {
    if (kIsWeb) return true;
    WidgetsFlutterBinding.ensureInitialized();

    final enabled = await BackgroundRefreshSettings.isEnabled();
    if (!enabled) return true;

    final prefs = await SharedPreferences.getInstance();
    final coordinate = LocationStorage.readLastKnown(prefs);
    if (coordinate == null) return true;

    try {
      await Hive.initFlutter();
    } catch (e, st) {
      AppLogger.warn('Background refresh: Hive init failed', error: e, stackTrace: st);
      return true;
    }

    final container = ProviderContainer();
    try {
      final repo = container.read(weatherRepositoryProvider);
      final result = await repo.getWeather(
        coordinate,
        hours: 16,
        days: 5,
        forceRefresh: true,
      );

      await result.fold(
        (failure) async {
          AppLogger.warn('Background refresh failed: ${failure.runtimeType}');
        },
        (reading) async {
          AppLogger.info('Background refresh success');
          await _maybeNotify(container, reading);
        },
      );
    } catch (e, st) {
      AppLogger.warn('Background refresh exception', error: e, stackTrace: st);
    } finally {
      container.dispose();
    }

    return true;
  }

  static Future<void> _maybeNotify(ProviderContainer container, WeatherReading reading) async {
    final prefs = await container.read(notificationPreferencesProvider.future);
    final now = DateTime.now();

    final type = WeatherAlertEvaluator.evaluate(reading, prefs, now);
    if (type == null) return;

    final lastSent = prefs.lastSentEpochMsByType[type];
    if (lastSent != null) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastSent);
      if (now.difference(last) < const Duration(hours: 6)) return;
    }

    await _ensureI18nReady();
    final locale = await _readStoredLocale();
    Get.updateLocale(locale);

    final notification = switch (type) {
      WeatherAlertType.rainSoon => WeatherAlertNotification(
          id: 1001,
          title: LocaleKeys.notificationsRainSoonTitle.tr,
          body: LocaleKeys.notificationsRainSoonBody.tr,
        ),
      WeatherAlertType.extremeHeat => WeatherAlertNotification(
          id: 1002,
          title: LocaleKeys.notificationsExtremeHeatTitle.tr,
          body: LocaleKeys.notificationsExtremeHeatBody.tr,
        ),
    };

    final service = container.read(notificationServiceProvider);
    await service.initialize();
    await service.showWeatherAlert(notification);
    await container.read(notificationPreferencesProvider.notifier).markSent(type, now);
  }

  static Future<void> _ensureI18nReady() async {
    try {
      if ((I18nStore.keys['en'] ?? const {}).isEmpty) {
        await I18nLoader.load();
        Get.addTranslations(I18nStore.keys);
      }
    } catch (e, st) {
      AppLogger.warn('Background refresh: i18n init failed', error: e, stackTrace: st);
    }
  }

  static Future<Locale> _readStoredLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('settings.locale');
    if (raw == null || raw.isEmpty) return const Locale('en');
    final parts = raw.split('-');
    if (parts.isEmpty || parts.first.isEmpty) return const Locale('en');
    if (parts.length == 1) return Locale(parts.first);
    return Locale(parts.first, parts[1]);
  }
}
