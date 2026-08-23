import 'package:claudy/core/errors/app_failure.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/core/location/location_state.dart';
import 'package:claudy/core/routing/app_routes.dart';
import 'package:claudy/core/theme/theme_provider.dart';
import 'package:claudy/core/theme/tokens.dart';
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

  static const double _wideBreakpoint = 900;
  static const double _wideMaxWidth = 1200;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final reading = ref.watch(weatherReadingProvider);
    final lowPower =
        ref.watch(themeProvider).asData?.value.lowPowerMode ?? false;

    final locationData = location.asData?.value;
    final locationName = _buildLocationName(locationData);
    final coordinates = _buildCoordinates(locationData);
    final isCurrentLocation = _isCurrentLocation(locationData?.mode);

    Widget weatherContent(WeatherReading value) => _WeatherContent(
          value: value,
          locationName: locationName,
          coordinates: coordinates,
          isCurrentLocation: isCurrentLocation,
          onRefreshLocation: () =>
              ref.read(locationProvider.notifier).requestPermissionAndRefresh(),
          onOpenDetails: () => context.push(AppRoutes.detailsFor('current')),
        );

    final content = LayoutBuilder(
      builder: (context, constraints) {
        // Keep the phone column width; only spread out on genuinely wide
        // windows so the two-pane layout has room to breathe.
        final maxWidth =
            constraints.maxWidth >= _wideBreakpoint ? _wideMaxWidth : 720.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
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
                      padding:
                          const EdgeInsets.symmetric(horizontal: Tokens.space16),
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
                        padding:
                            EdgeInsets.symmetric(horizontal: Tokens.space16),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    weatherContent(reading.asData!.value!),
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
                        return weatherContent(value);
                      },
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Tokens.space16,
                        ),
                        child: _ErrorCard(
                          error: e,
                          onRetry: () =>
                              ref.invalidate(weatherReadingProvider),
                        ),
                      ),
                      loading: () => const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: Tokens.space16),
                        child: AppSkeletonList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    return Scaffold(
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
    final name = state?.name;
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    // Device fixes show the generic label; unlabeled manual picks get the
    // mode label so the coordinates are not rendered twice (title + subtitle).
    if (_isCurrentLocation(state?.mode)) {
      return LocaleKeys.currentLocation.tr;
    }
    return LocaleKeys.locationModeManual.tr;
  }

  static String? _buildCoordinates(LocationState? state) {
    final coordinate = state?.coordinate;
    if (coordinate == null) return null;
    return '${coordinate.lat.toStringAsFixed(4)}, ${coordinate.lon.toStringAsFixed(4)}';
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
    required this.coordinates,
    this.isCurrentLocation = false,
    this.onRefreshLocation,
  });

  final WeatherReading value;
  final VoidCallback onOpenDetails;
  final String locationName;
  final String? coordinates;
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

    final header = Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
      child: LocationHeader(
        locationName: locationName,
        coordinates: coordinates,
        isCurrentLocation: isCurrentLocation,
        onRefresh: onRefreshLocation,
      ),
    );

    Widget conditionsColumn({required bool trailingAqi}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
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
            const SizedBox(height: Tokens.space16),
            WeatherMetricsGrid(
              uvIndex: current.uvIndex,
              humidity: current.humidityPercent,
              windSpeed: current.windSpeedMps,
              windDegrees: current.windDegrees,
              pressure: current.pressureHpa,
              visibility: current.visibilityKm,
              aqi: current.aqi,
            ),
            if (current.sunrise != null && current.sunset != null) ...[
              const SizedBox(height: Tokens.space16),
              SunriseSunsetCard(
                sunrise: current.sunrise!,
                sunset: current.sunset!,
                currentTime: now,
              ),
            ],
            const SizedBox(height: Tokens.space16),
            WindCompass(
              degrees: current.windDegrees,
              speedMps: current.windSpeedMps,
              gustMps: current.windGustMps,
            ),
            if (current.aqi != null && trailingAqi) ...[
              const SizedBox(height: Tokens.space16),
              AirQualityCard(aqi: current.aqi!),
            ],
          ],
        );

    Widget forecastColumn() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HourlyForecastList(items: hourlyItems),
            const SizedBox(height: Tokens.space16),
            DailyForecastTable(days: dailyItems),
          ],
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= WeatherHomePage._wideBreakpoint;

        if (!isWide) {
          // Single-column layout for phones and narrow windows.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: Tokens.space16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
                child: conditionsColumn(trailingAqi: true),
              ),
              const SizedBox(height: Tokens.space16),
              forecastColumn(),
            ],
          );
        }

        // Two-pane layout for wide windows/desktop.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            const SizedBox(height: Tokens.space16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: conditionsColumn(trailingAqi: true)),
                  const SizedBox(width: Tokens.space16),
                  Expanded(flex: 7, child: forecastColumn()),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
