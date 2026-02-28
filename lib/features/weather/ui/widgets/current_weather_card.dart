import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/ui/widgets/weather_condition_icon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CurrentWeatherCard extends StatelessWidget {
  const CurrentWeatherCard({
    super.key,
    required this.weather,
    required this.isStale,
    required this.providerName,
    required this.fetchedAt,
  });

  final CurrentWeather weather;
  final bool isStale;
  final String providerName;
  final DateTime fetchedAt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(fetchedAt));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.cornerRadius),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.35),
            colorScheme.secondary.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                WeatherConditionIcon(conditionCode: weather.conditionCode, size: 28),
                const SizedBox(width: 8),
                Text(
                  '${weather.temperatureC.round()}°',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const Spacer(),
                Text(
                  providerName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${LocaleKeys.weatherUpdatedAt.tr} $time',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _Chip(label: '${LocaleKeys.weatherFeelsLike.tr} ${weather.feelsLikeC.round()}°'),
                _Chip(label: '${LocaleKeys.weatherHumidity.tr} ${weather.humidityPercent}%'),
                _Chip(
                  label:
                      '${LocaleKeys.weatherWind.tr} ${weather.windSpeedMps.toStringAsFixed(1)} m/s',
                ),
              ],
            ),
            if (isStale) ...[
              const SizedBox(height: 12),
              _StalePill(colorScheme: colorScheme),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.45),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _StalePill extends StatelessWidget {
  const _StalePill({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: colorScheme.errorContainer.withValues(alpha: 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 16, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Text(
              LocaleKeys.weatherStale.tr,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: colorScheme.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}
