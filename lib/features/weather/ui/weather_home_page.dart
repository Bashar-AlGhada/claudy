import 'package:claudy/core/errors/app_failure.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/core/location/location_state.dart';
import 'package:claudy/core/routing/app_routes.dart';
import 'package:claudy/core/theme/theme_provider.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/core/ui/app_layout.dart';
import 'package:claudy/core/ui/app_skeleton.dart';
import 'package:claudy/core/ui/app_states.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:claudy/features/weather/providers/weather_reading_provider.dart';
import 'package:claudy/features/weather/ui/background/weather_background.dart';
import 'package:claudy/features/weather/ui/widgets/air_quality_card.dart';
import 'package:claudy/features/weather/ui/widgets/current_weather_card.dart';
import 'package:claudy/features/weather/ui/widgets/daily_forecast_table.dart';
import 'package:claudy/features/weather/ui/widgets/hourly_forecast_list.dart';
import 'package:claudy/features/weather/ui/widgets/location_header.dart';
import 'package:claudy/features/weather/ui/widgets/sunrise_sunset_card.dart';
import 'package:claudy/features/weather/ui/widgets/weather_metrics_grid.dart';
import 'package:claudy/features/weather/ui/widgets/wind_compass.dart';
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
    final lowPower =
        ref.watch(themeProvider).asData?.value.lowPowerMode ?? false;

    final locationData = location.asData?.value;
    final locationName = _buildLocationName(locationData);
    final regionName = _buildLocationRegion(locationData);
    final isCurrentLocation = _isCurrentLocation(locationData?.mode);

    final content = AppConstrained(
      padding: EdgeInsets.zero,
      child: RefreshIndicator(
        onRefresh: () async {
          await ref.read(weatherReadingProvider.notifier).refresh();
        },
        child: ListView(
          key: const PageStorageKey('weather_home_list'),
          padding: const EdgeInsets.only(
            top: Tokens.space16,
            bottom: Tokens.space24,
          ),
          children: [
            if (locationData?.isPermissionDenied == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
                child: _InlineMessage(
                  message: LocaleKeys.weatherLocationDenied.tr,
                  actionLabel: LocaleKeys.weatherEnableLocation.tr,
                  onAction: () => ref
                      .read(locationProvider.notifier)
                      .requestPermissionAndRefresh(),
                  secondaryActionLabel: LocaleKeys.weatherChooseLocation.tr,
                  onSecondaryAction: () => context.go(AppRoutes.search),
                ),
              ),
            const SizedBox(height: Tokens.space12),
            if (reading.asData?.value != null) ...[
              if (reading.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space16),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              _WeatherContent(
                value: reading.asData!.value!,
                locationName: locationName,
                regionName: regionName,
                isCurrentLocation: isCurrentLocation,
                onRefreshLocation: () => ref
                    .read(locationProvider.notifier)
                    .requestPermissionAndRefresh(),
                onOpenDetails: () =>
                    context.push(AppRoutes.detailsFor('current')),
              ),
            ] else
              reading.when(
                data: (value) {
                  if (value == null) {
                    return AppEmptyState(
                      icon: Icons.place_outlined,
                      title: LocaleKeys.weatherNoLocation.tr,
                      body: LocaleKeys.weatherChooseLocation.tr,
                      actionLabel: LocaleKeys.weatherChooseLocation.tr,
                      onAction: () => context.go(AppRoutes.search),
                    );
                  }
                  return _WeatherContent(
                    value: value,
                    locationName: locationName,
                    regionName: regionName,
                    isCurrentLocation: isCurrentLocation,
                    onRefreshLocation: () => ref
                        .read(locationProvider.notifier)
                        .requestPermissionAndRefresh(),
                    onOpenDetails: () =>
                        context.push(AppRoutes.detailsFor('current')),
                  );
                },
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.space16,
                  ),
                  child: _ErrorCard(
                    error: e,
                    onRetry: () => ref.invalidate(weatherReadingProvider),
                  ),
                ),
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Tokens.space16),
                  child: AppSkeletonList(),
                ),
              ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.navWeather.tr)),
      body: SafeArea(
        child: WeatherBackground(lowPower: lowPower, child: content),
      ),
    );
  }

  static String _buildLocationName(LocationState? state) {
    final coordinate = state?.coordinate;
    if (coordinate == null) {
      return LocaleKeys.weatherNoLocation.tr;
    }
    return '${coordinate.lat.toStringAsFixed(3)}, ${coordinate.lon.toStringAsFixed(3)}';
  }

  static String? _buildLocationRegion(LocationState? state) {
    final mode = state?.mode;
    return switch (mode) {
      LocationMode.manual => LocaleKeys.locationModeManual.tr,
      LocationMode.coarse => LocaleKeys.locationModeCoarse.tr,
      LocationMode.precise => LocaleKeys.locationModePrecise.tr,
      _ => null,
    };
  }

  static bool _isCurrentLocation(LocationMode? mode) {
    return mode == LocationMode.precise || mode == LocationMode.coarse;
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
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(LocaleKeys.weatherRetry.tr),
          ),
        ],
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({
    required this.value,
    required this.onOpenDetails,
    required this.locationName,
    this.regionName,
    this.isCurrentLocation = false,
    this.onRefreshLocation,
  });

  final WeatherReading value;
  final VoidCallback onOpenDetails;
  final String locationName;
  final String? regionName;
  final bool isCurrentLocation;
  final VoidCallback? onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final current = value.snapshot.current;
    final now = DateTime.now();
    final hourlyHorizon = value.snapshot.hourly
        .where(
          (item) =>
              item.time.isAfter(now.subtract(const Duration(hours: 1))) &&
              item.time.isBefore(now.add(const Duration(hours: 24))),
        )
        .toList();
    final hourlyItems = hourlyHorizon.isEmpty
        ? value.snapshot.hourly.take(24).toList()
        : hourlyHorizon;
    final dailyItems = value.snapshot.daily.take(7).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
          child: LocationHeader(
            locationName: locationName,
            regionName: regionName,
            isCurrentLocation: isCurrentLocation,
            onRefresh: onRefreshLocation,
          ),
        ),
        const SizedBox(height: Tokens.space16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
          child: FocusableActionDetector(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(Tokens.cornerRadius),
                onTap: onOpenDetails,
                child: Semantics(
                  button: true,
                  label: LocaleKeys.weatherDetails.tr,
                  child: CurrentWeatherCard(
                    weather: current,
                    isStale: value.isStale,
                    providerName: value.snapshot.providerName,
                    fetchedAt: value.snapshot.fetchedAt,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: Tokens.space16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
          child: WeatherMetricsGrid(
            uvIndex: current.uvIndex,
            humidity: current.humidityPercent,
            windSpeed: current.windSpeedMps,
            windDegrees: current.windDegrees,
            pressure: current.pressureHpa,
            visibility: current.visibilityKm,
            aqi: current.aqi,
          ),
        ),
        if (current.sunrise != null && current.sunset != null) ...[
          const SizedBox(height: Tokens.space16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
            child: SunriseSunsetCard(
              sunrise: current.sunrise!,
              sunset: current.sunset!,
              currentTime: now,
            ),
          ),
        ],
        if (current.aqi != null) ...[
          const SizedBox(height: Tokens.space16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
            child: AirQualityCard(aqi: current.aqi!),
          ),
        ],
        const SizedBox(height: Tokens.space16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
          child: WindCompass(
            degrees: current.windDegrees,
            speedMps: current.windSpeedMps,
            gustMps: current.windGustMps,
          ),
        ),
        const SizedBox(height: Tokens.space16),
        HourlyForecastList(items: hourlyItems),
        const SizedBox(height: Tokens.space16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
          child: DailyForecastTable(days: dailyItems),
        ),
      ],
    );
  }
}
