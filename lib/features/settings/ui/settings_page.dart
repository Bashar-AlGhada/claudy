import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/i18n/locale_provider.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/core/notifications/notification_preferences.dart';
import 'package:claudy/core/notifications/notification_provider.dart';
import 'package:claudy/core/routing/app_routes.dart';
import 'package:claudy/core/theme/theme_provider.dart';
import 'package:claudy/core/diagnostics/diagnostics_service.dart';
import 'package:claudy/core/logging/log_buffer.dart';
import 'package:claudy/core/perf/frame_monitor.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/core/ui/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:claudy/core/background/background_scheduler.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).valueOrNull ?? const Locale('en');
    final theme = ref.watch(themeProvider).valueOrNull;
    final location = ref.watch(locationProvider).valueOrNull;
    final locationMode = location?.mode ?? LocationMode.precise;
    final notificationPrefs = ref.watch(notificationPreferencesProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.navSettings.tr)),
      body: SafeArea(
        child: AppConstrained(
          padding: EdgeInsets.zero,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Tokens.space16),
            children: [
              if (theme != null)
                ListTile(
                  title: Text(LocaleKeys.settingsTheme.tr),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.settingsTheme),
                ),
            if (notificationPrefs != null) ...[
              SwitchListTile(
                title: Text(LocaleKeys.settingsNotificationsEnabled.tr),
                value: notificationPrefs.enabled,
                onChanged: (enabled) async {
                  if (enabled) {
                    await ref.read(notificationServiceProvider).requestPermissions();
                  }
                  await ref.read(notificationPreferencesProvider.notifier).setEnabled(enabled);
                },
              ),
              SwitchListTile(
                title: Text(LocaleKeys.settingsNotificationsRainSoon.tr),
                value: notificationPrefs.rainSoon,
                onChanged: notificationPrefs.enabled
                    ? (enabled) => ref
                        .read(notificationPreferencesProvider.notifier)
                        .setRainSoon(enabled)
                    : null,
              ),
              SwitchListTile(
                title: Text(LocaleKeys.settingsNotificationsExtremeHeat.tr),
                value: notificationPrefs.extremeHeat,
                onChanged: notificationPrefs.enabled
                    ? (enabled) => ref
                        .read(notificationPreferencesProvider.notifier)
                        .setExtremeHeat(enabled)
                    : null,
              ),
              ListTile(
                title: Text(LocaleKeys.settingsNotifications.tr),
                trailing: FilledButton(
                  onPressed: () => ref
                      .read(notificationServiceProvider)
                      .showTestNotification(),
                  child: Text(LocaleKeys.settingsTestNotification.tr),
                ),
              ),
            ],
            ListTile(
              title: Text(LocaleKeys.settingsBackgroundRefresh.tr),
              trailing: Wrap(
                spacing: Tokens.space8,
                children: [
                  OutlinedButton(
                    onPressed: () => BackgroundScheduler.disableRefresh(),
                    child: Text(LocaleKeys.settingsDisable.tr),
                  ),
                  FilledButton(
                    onPressed: () => BackgroundScheduler.scheduleRefresh(
                      frequency: (theme?.lowPowerMode ?? false)
                          ? const Duration(hours: 6)
                          : const Duration(hours: 3),
                    ),
                    child: Text(LocaleKeys.settingsEnable.tr),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(LocaleKeys.settingsLocationMode.tr),
              trailing: DropdownButton<LocationMode>(
                value: locationMode,
                onChanged: (next) {
                  if (next == null) return;
                  ref.read(locationProvider.notifier).setMode(next);
                },
                items: [
                  DropdownMenuItem(
                    value: LocationMode.precise,
                    child: Text(LocaleKeys.locationModePrecise.tr),
                  ),
                  DropdownMenuItem(
                    value: LocationMode.coarse,
                    child: Text(LocaleKeys.locationModeCoarse.tr),
                  ),
                  DropdownMenuItem(
                    value: LocationMode.manual,
                    child: Text(LocaleKeys.locationModeManual.tr),
                  ),
                ],
              ),
            ),
            ListTile(
              title: Text(LocaleKeys.settingsLanguage.tr),
              trailing: DropdownButton<Locale>(
                value: locale,
                onChanged: (next) {
                  if (next == null) return;
                  ref.read(localeProvider.notifier).setLocale(next);
                },
                items: [
                  DropdownMenuItem(
                    value: const Locale('en'),
                    child: Text(LocaleKeys.languageEnglish.tr),
                  ),
                  DropdownMenuItem(
                    value: const Locale('nl'),
                    child: Text(LocaleKeys.languageDutch.tr),
                  ),
                  DropdownMenuItem(
                    value: const Locale('ar'),
                    child: Text(LocaleKeys.languageArabic.tr),
                  ),
                ],
              ),
            ),
            if (theme != null)
              SwitchListTile(
                title: Text(LocaleKeys.settingsLowPower.tr),
                value: theme.lowPowerMode,
                onChanged: (enabled) =>
                    ref.read(themeProvider.notifier).setLowPowerMode(enabled),
              ),
            const SizedBox(height: Tokens.space8),
            const Divider(height: 1),
            const SizedBox(height: Tokens.space8),
            ListTile(
              title: Text(LocaleKeys.settingsDiagnostics.tr),
              trailing: FilledButton(
                onPressed: () async {
                  final svc = DiagnosticsService();
                  final bundle = await svc.collect();
                  bundle['logs'] = {'recent': LogBuffer.snapshot()};
                  bundle['performance'] = {'frameTimings': FrameMonitor.metrics()};
                  try {
                    final file = await svc.exportToTemp(bundle);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(LocaleKeys.diagnosticsExportSuccess.trParams({'path': file.path}))),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(LocaleKeys.diagnosticsExportFailure.tr)),
                      );
                    }
                  }
                },
                child: Text(LocaleKeys.settingsExportDiagnostics.tr),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
