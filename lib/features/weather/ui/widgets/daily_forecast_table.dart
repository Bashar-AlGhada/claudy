import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/ui/widgets/weather_condition_icon.dart';
import 'package:flutter/material.dart';

/// Enhanced 7-day forecast displayed as a detailed table.
class DailyForecastTable extends StatelessWidget {
  const DailyForecastTable({
    super.key,
    required this.days,
  });

  final List<DailyWeather> days;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.cornerRadius),
        color: colorScheme.surface.withValues(alpha: 0.55),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.cornerRadius),
        child: Column(
          children: [
            _TableHeader(colorScheme: colorScheme),
            ...List.generate(days.length, (index) {
              return _DailyForecastRow(
                item: days[index],
                isAlternate: index.isOdd,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final headerStyle = textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurface.withValues(alpha: 0.7),
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.space16,
        vertical: Tokens.space12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('Day', style: headerStyle),
          ),
          Expanded(
            flex: 1,
            child: Center(child: Text('', style: headerStyle)),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('High/Low', style: headerStyle)),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('Precip', style: headerStyle)),
          ),
          Expanded(
            flex: 2,
            child: Center(child: Text('Wind', style: headerStyle)),
          ),
        ],
      ),
    );
  }
}

class _DailyForecastRow extends StatefulWidget {
  const _DailyForecastRow({
    required this.item,
    required this.isAlternate,
  });

  final DailyWeather item;
  final bool isAlternate;

  @override
  State<_DailyForecastRow> createState() => _DailyForecastRowState();
}

class _DailyForecastRowState extends State<_DailyForecastRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);

    final dayOfWeek = _getDayName(widget.item.date, localizations);
    final dateStr =
        '${widget.item.date.day}/${widget.item.date.month}';

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.space16,
              vertical: Tokens.space12,
            ),
            decoration: BoxDecoration(
              color: widget.isAlternate
                  ? colorScheme.surface.withValues(alpha: 0.3)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayOfWeek,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: WeatherConditionIcon(
                      conditionCode: widget.item.conditionCode,
                      size: 22,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        style: textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: '${widget.item.maxTemperatureC.round()}°',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: ' / ${widget.item.minTemperatureC.round()}°',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.water_drop,
                          size: 14,
                          color: _getPrecipColor(widget.item.precipProbabilityPercent),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.item.precipProbabilityPercent}%',
                          style: textTheme.bodySmall?.copyWith(
                            color: _getPrecipColor(widget.item.precipProbabilityPercent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      '${widget.item.windSpeedMps.toStringAsFixed(1)} m/s',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Expanded details
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: _ExpandedDetails(
            item: widget.item,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          crossFadeState:
              _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: Tokens.motionFast,
        ),
      ],
    );
  }

  String _getDayName(DateTime date, MaterialLocalizations localizations) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.add(const Duration(days: 1))) return 'Tomorrow';

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }

  Color _getPrecipColor(int percent) {
    if (percent < 20) return Colors.grey;
    if (percent < 50) return Colors.lightBlue;
    if (percent < 70) return Colors.blue;
    return Colors.indigo;
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({
    required this.item,
    required this.colorScheme,
    required this.textTheme,
  });

  final DailyWeather item;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);

    String? sunriseStr;
    String? sunsetStr;
    if (item.sunrise != null) {
      sunriseStr = localizations.formatTimeOfDay(
        TimeOfDay.fromDateTime(item.sunrise!),
      );
    }
    if (item.sunset != null) {
      sunsetStr = localizations.formatTimeOfDay(
        TimeOfDay.fromDateTime(item.sunset!),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Tokens.space16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
      ),
      child: Wrap(
        spacing: Tokens.space24,
        runSpacing: Tokens.space12,
        children: [
          _DetailItem(
            icon: Icons.wb_sunny_outlined,
            label: 'UV Index',
            value: item.uvIndex.toString(),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          _DetailItem(
            icon: Icons.water_drop_outlined,
            label: 'Precipitation',
            value: '${item.precipMm.toStringAsFixed(1)} mm',
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          if (sunriseStr != null)
            _DetailItem(
              icon: Icons.wb_twilight,
              label: 'Sunrise',
              value: sunriseStr,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
          if (sunsetStr != null)
            _DetailItem(
              icon: Icons.nights_stay_outlined,
              label: 'Sunset',
              value: sunsetStr,
              textTheme: textTheme,
              colorScheme: colorScheme,
            ),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: Tokens.space4),
        Text(
          '$label: ',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
