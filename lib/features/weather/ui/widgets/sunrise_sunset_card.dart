import 'dart:math' as math;

import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Visual sun path arc showing sunrise/sunset times.
class SunriseSunsetCard extends StatelessWidget {
  const SunriseSunsetCard({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.currentTime,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime currentTime;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localizations = MaterialLocalizations.of(context);

    final sunriseStr = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(sunrise),
    );
    final sunsetStr = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(sunset),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.cornerRadius),
        color: colorScheme.surface.withValues(alpha: 0.55),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Tokens.space16),
        child: Column(
          children: [
            SizedBox(
              height: 100,
              child: CustomPaint(
                size: const Size(double.infinity, 100),
                painter: _SunPathPainter(
                  sunrise: sunrise,
                  sunset: sunset,
                  currentTime: currentTime,
                  arcColor: colorScheme.primary,
                  sunColor: Colors.amber,
                  inactiveColor: colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
            const SizedBox(height: Tokens.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TimeLabel(
                  icon: Icons.wb_twilight,
                  label: 'Sunrise',
                  time: sunriseStr,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
                _TimeLabel(
                  icon: Icons.nights_stay_outlined,
                  label: 'Sunset',
                  time: sunsetStr,
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({
    required this.icon,
    required this.label,
    required this.time,
    required this.textTheme,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final String time;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: Tokens.space8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              time,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SunPathPainter extends CustomPainter {
  _SunPathPainter({
    required this.sunrise,
    required this.sunset,
    required this.currentTime,
    required this.arcColor,
    required this.sunColor,
    required this.inactiveColor,
  });

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime currentTime;
  final Color arcColor;
  final Color sunColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height;
    final radius = size.width * 0.4;

    // Draw the horizon line
    final horizonPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - radius - 20, centerY - 10),
      Offset(centerX + radius + 20, centerY - 10),
      horizonPaint,
    );

    // Draw the arc path
    final arcRect = Rect.fromCircle(
      center: Offset(centerX, centerY - 10),
      radius: radius,
    );

    final inactiveArcPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw full arc in inactive color
    canvas.drawArc(arcRect, math.pi, math.pi, false, inactiveArcPaint);

    // Calculate sun position
    final dayDuration = sunset.difference(sunrise).inMinutes;
    final elapsed = currentTime.difference(sunrise).inMinutes;
    var progress = elapsed / dayDuration;
    progress = progress.clamp(0.0, 1.0);

    final isDaytime = currentTime.isAfter(sunrise) && currentTime.isBefore(sunset);

    if (isDaytime) {
      // Draw active arc up to current position
      final activeArcPaint = Paint()
        ..shader = LinearGradient(
          colors: [arcColor.withValues(alpha: 0.5), arcColor],
        ).createShader(arcRect)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, math.pi, math.pi * progress, false, activeArcPaint);
    }

    // Draw sun position
    final angle = math.pi + (math.pi * progress);
    final sunX = centerX + radius * math.cos(angle);
    final sunY = (centerY - 10) + radius * math.sin(angle);

    // Sun glow
    if (isDaytime) {
      final glowPaint = Paint()
        ..color = sunColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(sunX, sunY), 12, glowPaint);
    }

    // Sun circle
    final sunPaint = Paint()
      ..color = isDaytime ? sunColor : inactiveColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(sunX, sunY), 8, sunPaint);

    // Sun rays when daytime
    if (isDaytime) {
      final rayPaint = Paint()
        ..color = sunColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (var i = 0; i < 8; i++) {
        final rayAngle = (math.pi * 2 / 8) * i;
        final innerRadius = 11.0;
        final outerRadius = 15.0;
        canvas.drawLine(
          Offset(
            sunX + innerRadius * math.cos(rayAngle),
            sunY + innerRadius * math.sin(rayAngle),
          ),
          Offset(
            sunX + outerRadius * math.cos(rayAngle),
            sunY + outerRadius * math.sin(rayAngle),
          ),
          rayPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SunPathPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.sunrise != sunrise ||
        oldDelegate.sunset != sunset;
  }
}
