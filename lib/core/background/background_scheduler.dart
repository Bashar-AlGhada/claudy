import 'package:claudy/core/background/background_refresh_settings.dart';
import 'package:claudy/core/background/background_refresh_worker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

class BackgroundScheduler {
  static const _refreshTask = 'claudy.refreshWeather';

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<void> initialize() async {
    if (!isSupportedPlatform) return;
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> scheduleRefresh({required Duration frequency}) async {
    await BackgroundRefreshSettings.setEnabled(true);
    if (!isSupportedPlatform) return;
    final normalizedFrequency = frequency < const Duration(minutes: 15) ? const Duration(minutes: 15) : frequency;
    await Workmanager().registerPeriodicTask(
      _refreshTask,
      _refreshTask,
      frequency: normalizedFrequency,
      initialDelay: normalizedFrequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }

  static Future<void> disableRefresh() async {
    await BackgroundRefreshSettings.setEnabled(false);
    if (!isSupportedPlatform) return;
    await Workmanager().cancelByUniqueName(_refreshTask);
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final enabled = await BackgroundRefreshSettings.isEnabled();
    if (!enabled) return Future.value(true);
    return BackgroundRefreshWorker.run();
  });
}
