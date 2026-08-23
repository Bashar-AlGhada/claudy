import 'dart:math' as math;

import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The arc box grows with the card width (capped), so the sun path
            // scales visibly between phone and wide desktop panes instead of
            // being a fixed-size semicircle everywhere.
            final arcHeight =
                (constraints.maxWidth * 0.26).clamp(96.0, 150.0);
            return Column(
              children: [
                SizedBox(
                  height: arcHeight,
                  width: double.infinity,
                  child: ClipRect(
                    // The painter fits itself to this box; the clip guarantees
                    // nothing can ever bleed into neighbouring cards again.
                    child: CustomPaint(
                      size: Size(double.infinity, arcHeight),
                      painter: _SunPathPainter(
                        sunrise: sunrise,
                        sunset: sunset,
                        currentTime: currentTime,
                        arcColor: colorScheme.primary,
                        sunColor: Colors.amber,
                        inactiveColor:
                            colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: Tokens.space12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TimeLabel(
                      icon: Icons.wb_twilight,
                      label: LocaleKeys.labelSunrise.tr,
                      time: sunriseStr,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    _TimeLabel(
                      icon: Icons.nights_stay_outlined,
                      label: LocaleKeys.labelSunset.tr,
                      time: sunsetStr,
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ],
            );
          },
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

  /// Headroom above the arc apex so the sun disc, glow, and rays stay inside
  /// the box at the top of the path.
  static const double _sunTopClearance = 34;

  final DateTime sunrise;
  final DateTime sunset;
  final DateTime currentTime;
  final Color arcColor;
  final Color sunColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    // Horizon sits near the bottom of the box; the semicircle must fit the
    // height too (width-only scaling made it overflow upward on wide cards).
    const horizonInset = 10.0;
    final centerY = size.height;
    final radius = math.min(
      size.width * 0.45,
      size.height - horizonInset - _sunTopClearance,
    );

    final horizonPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX - radius - 20, centerY - horizonInset),
      Offset(centerX + radius + 20, centerY - horizonInset),
      horizonPaint,
    );

    final arcRect = Rect.fromCircle(
      center: Offset(centerX, centerY - horizonInset),
      radius: radius,
    );

    final inactiveArcPaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawArc(arcRect, math.pi, math.pi, false, inactiveArcPaint);

    final dayDuration = sunset.difference(sunrise).inMinutes;
    final elapsed = currentTime.difference(sunrise).inMinutes;
    // Degenerate data (sunrise == sunset, e.g. polar day/night rows) must not
    // divide by zero into NaN coordinates.
    var progress = dayDuration > 0 ? elapsed / dayDuration : 0.0;
    progress = progress.clamp(0.0, 1.0);

    final isDaytime = currentTime.isAfter(sunrise) && currentTime.isBefore(sunset);

    // At night the moon travels the same path from sunset to sunrise.
    double nightProgress = 0.0;
    if (!isDaytime) {
      var nightStart = sunset;
      var nightEnd = sunrise;
      if (currentTime.isBefore(sunrise)) {
        // Early morning: night began at yesterday's sunset.
        nightStart = nightStart.subtract(const Duration(days: 1));
      } else {
        // After sunset: night ends at tomorrow's sunrise.
        nightEnd = nightEnd.add(const Duration(days: 1));
      }
      final nightDuration = nightEnd.difference(nightStart).inMinutes;
      final nightElapsed = currentTime.difference(nightStart).inMinutes;
      nightProgress =
          nightDuration > 0 ? (nightElapsed / nightDuration).clamp(0.0, 1.0) : 0.0;
      progress = nightProgress;
    }

    if (isDaytime) {
      final activeArcPaint = Paint()
        ..shader = LinearGradient(
          colors: [arcColor.withValues(alpha: 0.5), arcColor],
        ).createShader(arcRect)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, math.pi, math.pi * progress, false, activeArcPaint);
    } else {
      // Night: dim moonlit arc trailing the travelling moon.
      final nightArcPaint = Paint()
        ..color = moonColor.withValues(alpha: 0.35)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(arcRect, math.pi, math.pi * progress, false, nightArcPaint);
    }

    final angle = math.pi + (math.pi * progress);
    final sunX = centerX + radius * math.cos(angle);
    final sunY = (centerY - horizonInset) + radius * math.sin(angle);

    if (isDaytime) {
      // Sun glow
      final glowPaint = Paint()
        ..color = sunColor.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(sunX, sunY), 12, glowPaint);
    }

    if (isDaytime) {
      // Sun circle
      final sunPaint = Paint()
        ..color = sunColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sunX, sunY), 8, sunPaint);

      // Sun rays
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
      return;
    }

    _drawMoon(canvas, Offset(sunX, sunY));
  }

  /// Pale moon colour for the night path.
  static const Color moonColor = Color(0xFFE8ECF5);

  /// Crescent moon travelling the arc during the night.
  void _drawMoon(Canvas canvas, Offset center) {
    final glowPaint = Paint()
      ..color = moonColor.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, 11, glowPaint);

    final moonPaint = Paint()
      ..color = moonColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7, moonPaint);

    // Crescent shadow: bite out an offset disc.
    final shadowPaint = Paint()
      ..color = const Color(0xFF1C2436).withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + const Offset(3.2, -1.6), 6, shadowPaint);

    final craterPaint = Paint()
      ..color = moonColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center - const Offset(2.5, 1.5), 1.4, craterPaint);
    canvas.drawCircle(center - const Offset(1.0, 3.0), 0.9, craterPaint);
  }

  @override
  bool shouldRepaint(covariant _SunPathPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.sunrise != sunrise ||
        oldDelegate.sunset != sunset;
  }
}
