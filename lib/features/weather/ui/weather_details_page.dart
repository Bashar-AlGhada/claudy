import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/features/weather/providers/weather_reading_provider.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/core/ui/app_skeleton.dart';
import 'package:claudy/core/ui/app_states.dart';
import 'package:claudy/core/ui/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class WeatherDetailsPage extends ConsumerWidget {
  const WeatherDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(weatherReadingProvider);

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.weatherDetails.tr)),
      body: SafeArea(
        child: AppConstrained(
          padding: EdgeInsets.zero,
          child: reading.when(
            data: (data) {
              if (data == null) {
                return AppEmptyState(
                  title: LocaleKeys.weatherNoLocation.tr,
                );
              }
              final hourly = data.snapshot.hourly;
              final daily = data.snapshot.daily;
              return ListView(
                padding: const EdgeInsets.all(Tokens.space16),
                children: [
                  _MetricRow(
                    label: LocaleKeys.weatherFeelsLike.tr,
                    value: '${data.snapshot.current.feelsLikeC.round()}°',
                  ),
                  _MetricRow(
                    label: LocaleKeys.weatherHumidity.tr,
                    value: '${data.snapshot.current.humidityPercent}%',
                  ),
                  _MetricRow(
                    label: LocaleKeys.weatherWind.tr,
                    value: '${data.snapshot.current.windSpeedMps.toStringAsFixed(1)} m/s',
                  ),
                  const SizedBox(height: Tokens.space16),
                  Text(
                    LocaleKeys.weatherHourly.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Tokens.space12),
                  SizedBox(
                    height: 120,
                    child: Semantics(
                      label: LocaleKeys.weatherHourly.tr,
                      child: CustomPaint(
                        painter: _HourlySparklinePainter(
                          items: hourly,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Tokens.space16),
                  Text(
                    LocaleKeys.weatherDaily.tr,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Tokens.space12),
                  SizedBox(
                    height: 140,
                    child: Semantics(
                      label: LocaleKeys.weatherDaily.tr,
                      child: CustomPaint(
                        painter: _DailyRangePainter(
                          items: daily,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            error: (_, __) => AppErrorState(
              message: LocaleKeys.weatherError.tr,
              retryLabel: LocaleKeys.weatherRetry.tr,
              onRetry: () => ref.invalidate(weatherReadingProvider),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(Tokens.space16),
              child: AppSkeletonList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _HourlySparklinePainter extends CustomPainter {
  _HourlySparklinePainter({required this.items, required this.color});

  final List<HourlyWeather> items;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.length < 2) return;

    final temps = items.map((e) => e.temperatureC).toList();
    var minT = temps.first;
    var maxT = temps.first;
    for (final t in temps.skip(1)) {
      if (t < minT) minT = t;
      if (t > maxT) maxT = t;
    }
    final range = (maxT - minT).abs();
    final safeRange = range < 0.1 ? 1.0 : range;

    final line = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Offset.zero & size);

    final path = Path();
    final filled = Path();

    for (var i = 0; i < temps.length; i++) {
      final x = size.width * (i / (temps.length - 1));
      final y = size.height -
          ((temps[i] - minT) / safeRange) * (size.height * 0.9) -
          size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
        filled.moveTo(x, size.height);
        filled.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        filled.lineTo(x, y);
      }
    }
    filled.lineTo(size.width, size.height);
    filled.close();

    canvas.drawPath(filled, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _HourlySparklinePainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.color != color;
  }
}

class _DailyRangePainter extends CustomPainter {
  _DailyRangePainter({required this.items, required this.color});

  final List<DailyWeather> items;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    var minT = items.first.minTemperatureC;
    var maxT = items.first.maxTemperatureC;
    for (final d in items.skip(1)) {
      if (d.minTemperatureC < minT) minT = d.minTemperatureC;
      if (d.maxTemperatureC > maxT) maxT = d.maxTemperatureC;
    }
    final range = (maxT - minT).abs();
    final safeRange = range < 0.1 ? 1.0 : range;

    final bar = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final axis = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1), axis);

    final gap = 10.0;
    final itemWidth = (size.width - gap * (items.length - 1)) / items.length;

    for (var i = 0; i < items.length; i++) {
      final d = items[i];
      final x = i * (itemWidth + gap);
      final yMin = size.height -
          ((d.minTemperatureC - minT) / safeRange) * (size.height * 0.9) -
          size.height * 0.05;
      final yMax = size.height -
          ((d.maxTemperatureC - minT) / safeRange) * (size.height * 0.9) -
          size.height * 0.05;

      final top = yMax < yMin ? yMax : yMin;
      final bottom = yMax < yMin ? yMin : yMax;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, itemWidth, (bottom - top).clamp(6, size.height)),
        const Radius.circular(10),
      );
      canvas.drawRRect(rect, bar);
    }
  }

  @override
  bool shouldRepaint(covariant _DailyRangePainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.color != color;
  }
}
