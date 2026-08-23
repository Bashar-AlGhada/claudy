import 'package:claudy/core/config/api_key_store.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/i18n/locale_provider.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/core/notifications/notification_preferences.dart';
import 'package:claudy/core/notifications/notification_provider.dart';
import 'package:claudy/features/map/data/rainviewer_service.dart';
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
import 'package:claudy/core/background/background_refresh_settings.dart';
import 'package:claudy/features/weather/ui/background/weather_background.dart';

final backgroundDebugUnlockProvider =
    NotifierProvider<_DebugUnlockNotifier, int>(_DebugUnlockNotifier.new);

class _DebugUnlockNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void tap() => state = (state + 1).clamp(0, 5);

  void reset() => state = 0;
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider).asData?.value ?? const Locale('en');
    final theme = ref.watch(themeProvider).asData?.value;
    final location = ref.watch(locationProvider).asData?.value;
    final locationMode = location?.mode ?? LocationMode.precise;
    final notificationPrefs = ref.watch(notificationPreferencesProvider).asData?.value;
    final backgroundRefreshEnabled = ref.watch(backgroundRefreshEnabledProvider).asData?.value ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.navSettings.tr)),
      body: SafeArea(
        child: AppConstrained(
          padding: EdgeInsets.zero,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Tokens.space16),
            children: [
              const _OpenWeatherKeyCard(),
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
                  onChanged: notificationPrefs.enabled ? (enabled) => ref.read(notificationPreferencesProvider.notifier).setRainSoon(enabled) : null,
                ),
                SwitchListTile(
                  title: Text(LocaleKeys.settingsNotificationsExtremeHeat.tr),
                  value: notificationPrefs.extremeHeat,
                  onChanged: notificationPrefs.enabled
                      ? (enabled) => ref.read(notificationPreferencesProvider.notifier).setExtremeHeat(enabled)
                      : null,
                ),
                ListTile(
                  title: Text(LocaleKeys.settingsNotifications.tr),
                  trailing: FilledButton(
                    onPressed: () => ref.read(notificationServiceProvider).showTestNotification(),
                    child: Text(LocaleKeys.settingsTestNotification.tr),
                  ),
                ),
              ],
              ListTile(
                title: Text(LocaleKeys.settingsBackgroundRefresh.tr),
                subtitle: Text(
                  backgroundRefreshEnabled
                      ? LocaleKeys.settingsStatusEnabled.tr
                      : LocaleKeys.settingsStatusDisabled.tr,
                ),
                trailing: Wrap(
                  spacing: Tokens.space8,
                  children: [
                    OutlinedButton(
                      onPressed: backgroundRefreshEnabled
                          ? () async {
                              await BackgroundScheduler.disableRefresh();
                              ref.invalidate(backgroundRefreshEnabledProvider);
                              if (context.mounted) {
                                final message = BackgroundScheduler.isSupportedPlatform
                                    ? LocaleKeys.settingsDisable.tr
                                    : '${LocaleKeys.settingsDisable.tr} ${LocaleKeys.settingsPlatformUnsupported.tr}';
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                              }
                            }
                          : null,
                      child: Text(LocaleKeys.settingsDisable.tr),
                    ),
                    FilledButton(
                      onPressed: backgroundRefreshEnabled
                          ? null
                          : () async {
                              await BackgroundScheduler.scheduleRefresh(
                                frequency: (theme?.lowPowerMode ?? false) ? const Duration(hours: 6) : const Duration(hours: 3),
                              );
                              ref.invalidate(backgroundRefreshEnabledProvider);
                              if (context.mounted) {
                                final message = BackgroundScheduler.isSupportedPlatform
                                    ? LocaleKeys.settingsEnable.tr
                                    : '${LocaleKeys.settingsEnable.tr} ${LocaleKeys.settingsPlatformUnsupported.tr}';
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                              }
                            },
                      child: Text(LocaleKeys.settingsEnable.tr),
                    ),
                  ],
                ),
              ),
              ListTile(
                title: Text(LocaleKeys.settingsLocationMode.tr),
                trailing: DropdownButton<LocationMode>(
                  value: locationMode,
                  // Disabled while loading so a transient default is not
                  // presented as the user's actual choice.
                  onChanged: location == null
                      ? null
                      : (next) {
                          if (next == null) return;
                          ref.read(locationProvider.notifier).setMode(next);
                        },
                  items: [
                    DropdownMenuItem(value: LocationMode.precise, child: Text(LocaleKeys.locationModePrecise.tr)),
                    DropdownMenuItem(value: LocationMode.coarse, child: Text(LocaleKeys.locationModeCoarse.tr)),
                    DropdownMenuItem(value: LocationMode.manual, child: Text(LocaleKeys.locationModeManual.tr)),
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
                    DropdownMenuItem(value: const Locale('en'), child: Text(LocaleKeys.languageEnglish.tr)),
                    DropdownMenuItem(value: const Locale('nl'), child: Text(LocaleKeys.languageDutch.tr)),
                    DropdownMenuItem(value: const Locale('ar'), child: Text(LocaleKeys.languageArabic.tr)),
                  ],
                ),
              ),
              if (theme != null)
                SwitchListTile(
                  title: Text(LocaleKeys.settingsLowPower.tr),
                  value: theme.lowPowerMode,
                  onChanged: (enabled) => ref.read(themeProvider.notifier).setLowPowerMode(enabled),
                ),
              const SizedBox(height: Tokens.space8),
              const Divider(height: 1),
              const SizedBox(height: Tokens.space8),
              if (ref.watch(backgroundDebugUnlockProvider) >= 5)
                const _BackgroundPreviewCard(),
              if (ref.watch(backgroundDebugUnlockProvider) >= 5)
                const SizedBox(height: Tokens.space8),
              ListTile(
                title: Text(LocaleKeys.settingsDiagnostics.tr),
                onTap: () {
                  // Hidden: 5 taps on this row reveal the background preview.
                  ref.read(backgroundDebugUnlockProvider.notifier).tap();
                },
                trailing: FilledButton(
                  onPressed: () async {
                    final svc = DiagnosticsService();
                    final bundle = await svc.collect();
                    bundle['logs'] = {'recent': LogBuffer.snapshot()};
                    bundle['performance'] = {'frameTimings': FrameMonitor.metrics()};
                    try {
                      final file = await svc.exportToTemp(bundle);
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(LocaleKeys.diagnosticsExportSuccess.trParams({'path': file.path}))));
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(LocaleKeys.diagnosticsExportFailure.tr)));
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

class _OpenWeatherKeyCard extends ConsumerStatefulWidget {
  const _OpenWeatherKeyCard();

  @override
  ConsumerState<_OpenWeatherKeyCard> createState() => _OpenWeatherKeyCardState();
}

class _OpenWeatherKeyCardState extends ConsumerState<_OpenWeatherKeyCard> {
  final _controller = TextEditingController();
  bool _obscured = true;
  bool _busy = false;
  bool _hasStoredKey = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _refreshStored();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _refreshStored() async {
    final hasKey = await ref.read(apiKeyStoreProvider).hasUserKey();
    if (!mounted) return;
    setState(() => _hasStoredKey = hasKey);
  }

  void _invalidateDependents() {
    ref.invalidate(openWeatherApiKeyProvider);
    // Drops cached layer probes/zoom caps so the map re-evaluates the new key.
    ref.invalidate(rainViewerProvider);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final store = ref.read(apiKeyStoreProvider);
      final result = await store.validate(key);
      if (!mounted) return;
      switch (result) {
        case ApiKeyValidation.valid:
          await store.save(key);
          _controller.clear();
          _invalidateDependents();
          await _refreshStored();
          _show(LocaleKeys.settingsOpenweatherSaved.tr);
        case ApiKeyValidation.invalid:
          _show(LocaleKeys.settingsOpenweatherInvalid.tr);
        case ApiKeyValidation.networkError:
          _show(LocaleKeys.weatherOffline.tr);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    if (_busy || !_hasStoredKey) return;
    setState(() => _busy = true);
    try {
      await ref.read(apiKeyStoreProvider).clear();
      _invalidateDependents();
      await _refreshStored();
      if (!mounted) return;
      _show(LocaleKeys.settingsOpenweatherRemoved.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolved = ref.watch(openWeatherApiKeyProvider).asData?.value ?? '';
    final subtitle = _hasStoredKey
        ? '${LocaleKeys.settingsOpenweatherStored.tr} (\u2022\u2022\u2022\u2022)'
        : resolved.isNotEmpty
            ? LocaleKeys.settingsOpenweatherBuildIn.tr
            : LocaleKeys.settingsOpenweatherHint.tr;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key_outlined, size: 20),
                const SizedBox(width: Tokens.space8),
                Expanded(
                  child: Text(
                    LocaleKeys.settingsOpenweatherTitle.tr,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.space4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: Tokens.space8),
            TextField(
              controller: _controller,
              obscureText: _obscured,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                hintText: LocaleKeys.settingsOpenweatherHint.tr,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
            ),
            const SizedBox(height: Tokens.space8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: (_busy || _controller.text.trim().isEmpty) ? null : _save,
                  icon: _busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 16),
                  label: Text(
                    _busy
                        ? LocaleKeys.settingsOpenweatherChecking.tr
                        : LocaleKeys.settingsOpenweatherSave.tr,
                  ),
                ),
                if (_hasStoredKey)
                  OutlinedButton(
                    onPressed: _busy ? null : _clear,
                    child: Text(LocaleKeys.settingsOpenweatherClear.tr),
                  ),
              ],
            ),
            const SizedBox(height: Tokens.space4),
            Text(
              LocaleKeys.settingsOpenweatherGetKey.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundPreviewCard extends ConsumerWidget {
  const _BackgroundPreviewCard();

  static const _scenarios = <(String, BackgroundScenario)>[
    ('Auto', BackgroundScenario.auto),
    ('Clear day', BackgroundScenario.clearDay),
    ('Clear night', BackgroundScenario.clearNight),
    ('Clouds day', BackgroundScenario.cloudsDay),
    ('Clouds night', BackgroundScenario.cloudsNight),
    ('Rain day', BackgroundScenario.rainDay),
    ('Rain night', BackgroundScenario.rainNight),
    ('Snow', BackgroundScenario.snowDay),
    ('Fog', BackgroundScenario.fogDay),
    ('Thunder', BackgroundScenario.thunder),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(backgroundPreviewProvider);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report_outlined, size: 18),
                const SizedBox(width: Tokens.space8),
                Text(
                  'Background preview',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: Tokens.space8),
            SizedBox(
              height: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Tokens.cornerRadius),
                child: WeatherBackground(
                  lowPower: false,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: Tokens.space8),
            Wrap(
              spacing: Tokens.space8,
              runSpacing: Tokens.space4,
              children: [
                for (final (label, scenario) in _scenarios)
                  ChoiceChip(
                    label: Text(label),
                    selected: active == scenario,
                    onSelected: (_) => ref
                        .read(backgroundPreviewProvider.notifier)
                        .set(scenario),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
