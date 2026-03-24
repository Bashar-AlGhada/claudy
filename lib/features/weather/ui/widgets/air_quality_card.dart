import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// AQI display with color-coded indicator and health recommendations.
class AirQualityCard extends StatelessWidget {
  const AirQualityCard({
    super.key,
    required this.aqi,
  });

  final int aqi;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final category = _getCategory(aqi);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.cornerRadius),
        color: colorScheme.surface.withValues(alpha: 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.eco_outlined,
                  color: category.color,
                  size: 24,
                ),
                const SizedBox(width: Tokens.space8),
                Text(
                  'Air Quality',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.space12,
                    vertical: Tokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    aqi.toString(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: category.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.space16),
            _AqiScale(currentAqi: aqi),
            const SizedBox(height: Tokens.space12),
            Text(
              category.label,
              style: textTheme.titleSmall?.copyWith(
                color: category.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: Tokens.space4),
            Text(
              category.recommendation,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _AqiCategory _getCategory(int aqi) {
    if (aqi <= 50) {
      return _AqiCategory(
        label: 'Good',
        color: Colors.green,
        recommendation: 'Air quality is satisfactory. Enjoy outdoor activities.',
      );
    } else if (aqi <= 100) {
      return _AqiCategory(
        label: 'Moderate',
        color: Colors.yellow.shade700,
        recommendation:
            'Acceptable quality. Sensitive individuals should limit prolonged outdoor exertion.',
      );
    } else if (aqi <= 150) {
      return _AqiCategory(
        label: 'Unhealthy for Sensitive Groups',
        color: Colors.orange,
        recommendation:
            'Sensitive groups may experience health effects. Consider reducing outdoor activities.',
      );
    } else if (aqi <= 200) {
      return _AqiCategory(
        label: 'Unhealthy',
        color: Colors.red,
        recommendation:
            'Everyone may experience health effects. Limit prolonged outdoor exertion.',
      );
    } else if (aqi <= 300) {
      return _AqiCategory(
        label: 'Very Unhealthy',
        color: Colors.purple,
        recommendation:
            'Health alert: increased risk for everyone. Avoid outdoor activities.',
      );
    } else {
      return _AqiCategory(
        label: 'Hazardous',
        color: Colors.brown.shade700,
        recommendation:
            'Health warning of emergency conditions. Stay indoors and keep windows closed.',
      );
    }
  }
}

class _AqiCategory {
  const _AqiCategory({
    required this.label,
    required this.color,
    required this.recommendation,
  });

  final String label;
  final Color color;
  final String recommendation;
}

class _AqiScale extends StatelessWidget {
  const _AqiScale({required this.currentAqi});

  final int currentAqi;

  @override
  Widget build(BuildContext context) {
    // AQI scale: 0-50 green, 51-100 yellow, 101-150 orange, 151-200 red, 201-300 purple, 301+ maroon
    final segments = [
      (color: Colors.green, maxValue: 50),
      (color: Colors.yellow.shade700, maxValue: 100),
      (color: Colors.orange, maxValue: 150),
      (color: Colors.red, maxValue: 200),
      (color: Colors.purple, maxValue: 300),
      (color: Colors.brown.shade700, maxValue: 500),
    ];

    // Calculate indicator position (0.0 to 1.0)
    final clampedAqi = currentAqi.clamp(0, 500);
    final position = clampedAqi / 500;

    return Column(
      children: [
        SizedBox(
          height: 8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: segments.map((segment) {
                final prevMax =
                    segments.indexOf(segment) == 0 ? 0 : segments[segments.indexOf(segment) - 1].maxValue;
                final width = (segment.maxValue - prevMax) / 500;
                return Expanded(
                  flex: (width * 100).round(),
                  child: Container(color: segment.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: Tokens.space4),
        LayoutBuilder(
          builder: (context, constraints) {
            final indicatorPosition = position * constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(height: 12, width: constraints.maxWidth),
                Positioned(
                  left: indicatorPosition.clamp(6.0, constraints.maxWidth - 6),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
