import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/ui/widgets/weather_condition_icon.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';

class DailyForecastList extends StatelessWidget {
  const DailyForecastList({super.key, required this.items});

  final List<DailyWeather> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: Tokens.space16),
      itemCount: items.length,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return _DailyRow(item: item);
      },
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({required this.item});

  final DailyWeather item;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final day = localizations.narrowWeekdays[item.date.weekday % 7];
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(child: Text(day)),
          WeatherConditionIcon(conditionCode: item.conditionCode, size: 18),
          const SizedBox(width: Tokens.space12),
          Text('${item.minTemperatureC.round()}°'),
          const SizedBox(width: Tokens.space8),
          Text('${item.maxTemperatureC.round()}°'),
        ],
      ),
    );
  }
}
