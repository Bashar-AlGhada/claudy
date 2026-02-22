import 'package:claudy/core/errors/app_failure.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/core/routing/app_routes.dart';
import 'package:claudy/core/theme/theme_provider.dart';
import 'package:claudy/features/weather/providers/weather_reading_provider.dart';
import 'package:claudy/features/weather/ui/widgets/current_weather_card.dart';
import 'package:claudy/features/weather/ui/widgets/daily_forecast_list.dart';
import 'package:claudy/features/weather/ui/widgets/hourly_forecast_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class WeatherHomePage extends ConsumerWidget {
  const WeatherHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final reading = ref.watch(weatherReadingProvider);
    final lowPower = ref.watch(themeProvider).valueOrNull?.lowPowerMode ?? false;

    final content = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(weatherReadingProvider);
        await ref.read(weatherReadingProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          if (location.valueOrNull?.isPermissionDenied == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _InlineMessage(
                message: LocaleKeys.weatherLocationDenied.tr,
                actionLabel: LocaleKeys.weatherEnableLocation.tr,
                onAction: () =>
                    ref.read(locationProvider.notifier).requestPermissionAndRefresh(),
                secondaryActionLabel: LocaleKeys.weatherChooseLocation.tr,
                onSecondaryAction: () => context.go(AppRoutes.search),
              ),
            ),
          const SizedBox(height: 12),
          reading.when(
            data: (value) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Semantics(
                      button: true,
                      label: LocaleKeys.weatherDetails.tr,
                      child: GestureDetector(
                        onTap: () => context.push(AppRoutes.detailsFor('current')),
                        child: CurrentWeatherCard(
                          weather: value.snapshot.current,
                          isStale: value.isStale,
                          providerName: value.snapshot.providerName,
                          fetchedAt: value.snapshot.fetchedAt,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  HourlyForecastList(items: value.snapshot.hourly),
                  const SizedBox(height: 12),
                  DailyForecastList(items: value.snapshot.daily),
                ],
              );
            },
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ErrorCard(
                error: e,
                onRetry: () => ref.invalidate(weatherReadingProvider),
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.navWeather.tr)),
      body: SafeArea(
        child: lowPower
            ? Container(
                color: Theme.of(context).colorScheme.surface,
                child: content,
              )
            : AnimatedContainer(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
                child: content,
              ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          const SizedBox(width: 12),
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            OutlinedButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel!),
            ),
            const SizedBox(width: 8),
          ],
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      RateLimitFailure() => LocaleKeys.weatherRateLimited.tr,
      ValidationFailure() => LocaleKeys.weatherMissingApiKey.tr,
      NetworkFailure() => LocaleKeys.weatherOffline.tr,
      _ => LocaleKeys.weatherError.tr,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(LocaleKeys.weatherRetry.tr)),
        ],
      ),
    );
  }
}
