import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:claudy/features/weather/ui/widgets/weather_condition_icon.dart';
import 'package:flutter/material.dart';

class HourlyForecastList extends StatelessWidget {
  const HourlyForecastList({super.key, required this.items});

  final List<HourlyWeather> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = items[index];
          return _HourlyItem(item: item);
        },
      ),
    );
  }
}

class _HourlyItem extends StatelessWidget {
  const _HourlyItem({required this.item});

  final HourlyWeather item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time = TimeOfDay.fromDateTime(item.time);

    return Container(
      width: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colorScheme.surface.withValues(alpha: 0.6),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time.format(context),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const SizedBox(height: 6),
          WeatherConditionIcon(conditionCode: item.conditionCode, size: 18),
          const SizedBox(height: 6),
          Text('${item.temperatureC.round()}°'),
        ],
      ),
    );
  }
}
