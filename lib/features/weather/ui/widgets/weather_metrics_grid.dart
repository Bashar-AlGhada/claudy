import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// A 2x3 grid displaying current weather metrics.
class WeatherMetricsGrid extends StatelessWidget {
  const WeatherMetricsGrid({
    super.key,
    required this.uvIndex,
    required this.humidity,
    required this.windSpeed,
    required this.windDegrees,
    required this.pressure,
    required this.visibility,
    this.aqi,
  });

  final int uvIndex;
  final int humidity;
  final double windSpeed;
  final int windDegrees;
  final double pressure;
  final double visibility;
  final int? aqi;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        icon: Icons.wb_sunny_outlined,
        value: uvIndex.toString(),
        label: 'UV Index',
        color: _uvColor(uvIndex),
      ),
      _MetricData(
        icon: Icons.water_drop_outlined,
        value: '$humidity%',
        label: 'Humidity',
      ),
      _MetricData(
        icon: Icons.air,
        value: '${windSpeed.toStringAsFixed(1)} m/s',
        label: 'Wind',
      ),
      _MetricData(
        icon: Icons.compress,
        value: '${pressure.round()} hPa',
        label: 'Pressure',
      ),
      _MetricData(
        icon: Icons.visibility_outlined,
        value: '${visibility.toStringAsFixed(1)} km',
        label: 'Visibility',
      ),
      if (aqi != null)
        _MetricData(
          icon: Icons.eco_outlined,
          value: aqi.toString(),
          label: 'AQI',
          color: _aqiColor(aqi!),
        ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: Tokens.space12,
        crossAxisSpacing: Tokens.space12,
        childAspectRatio: 1.0,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) => _MetricCard(data: metrics[index]),
    );
  }

  Color _uvColor(int uv) {
    if (uv <= 2) return Colors.green;
    if (uv <= 5) return Colors.yellow.shade700;
    if (uv <= 7) return Colors.orange;
    if (uv <= 10) return Colors.red;
    return Colors.purple;
  }

  Color _aqiColor(int aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow.shade700;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    if (aqi <= 300) return Colors.purple;
    return Colors.brown;
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.cornerRadius),
        color: colorScheme.surface.withValues(alpha: 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              data.icon,
              size: 24,
              color: data.color ?? colorScheme.primary,
            ),
            const SizedBox(height: Tokens.space8),
            Text(
              data.value,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: data.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Tokens.space4),
            Text(
              data.label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
