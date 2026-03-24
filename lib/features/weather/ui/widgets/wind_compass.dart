import 'dart:math' as math;

import 'package:claudy/core/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Wind direction compass with speed display.
class WindCompass extends StatelessWidget {
  const WindCompass({
    super.key,
    required this.degrees,
    required this.speedMps,
    this.gustMps,
  });

  final int degrees;
  final double speedMps;
  final double? gustMps;

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
        padding: const EdgeInsets.all(Tokens.space16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.air, color: colorScheme.primary, size: 24),
                const SizedBox(width: Tokens.space8),
                Text(
                  'Wind',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.space16),
            SizedBox(
              width: 150,
              height: 150,
              child: CustomPaint(
                size: const Size(150, 150),
                painter: _CompassPainter(
                  degrees: degrees,
                  primaryColor: colorScheme.primary,
                  secondaryColor: colorScheme.onSurface.withValues(alpha: 0.3),
                  arrowColor: colorScheme.error,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        speedMps.toStringAsFixed(1),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'm/s',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Tokens.space12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WindDetail(
                  label: 'Direction',
                  value: '${_degreesToCardinal(degrees)} ($degrees°)',
                  textTheme: textTheme,
                  colorScheme: colorScheme,
                ),
                if (gustMps != null) ...[
                  const SizedBox(width: Tokens.space24),
                  _WindDetail(
                    label: 'Gusts',
                    value: '${gustMps!.toStringAsFixed(1)} m/s',
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _degreesToCardinal(int degrees) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((degrees + 22.5) / 45).floor() % 8;
    return directions[index];
  }
}

class _WindDetail extends StatelessWidget {
  const _WindDetail({
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.degrees,
    required this.primaryColor,
    required this.secondaryColor,
    required this.arrowColor,
  });

  final int degrees;
  final Color primaryColor;
  final Color secondaryColor;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw outer circle
    final outerCirclePaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 5, outerCirclePaint);

    // Draw tick marks
    final tickPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 360; i += 15) {
      final angle = (i - 90) * math.pi / 180;
      final isCardinal = i % 90 == 0;
      final isIntercardinal = i % 45 == 0;
      final innerRadius = isCardinal
          ? radius - 18
          : isIntercardinal
              ? radius - 14
              : radius - 10;

      canvas.drawLine(
        Offset(
          center.dx + innerRadius * math.cos(angle),
          center.dy + innerRadius * math.sin(angle),
        ),
        Offset(
          center.dx + (radius - 5) * math.cos(angle),
          center.dy + (radius - 5) * math.sin(angle),
        ),
        tickPaint,
      );
    }

    // Draw cardinal direction labels
    final directions = ['N', 'E', 'S', 'W'];
    final angles = [-90, 0, 90, 180];

    for (var i = 0; i < directions.length; i++) {
      final angle = angles[i] * math.pi / 180;
      final labelRadius = radius - 28;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: directions[i],
          style: TextStyle(
            color: directions[i] == 'N' ? primaryColor : secondaryColor,
            fontSize: 12,
            fontWeight: directions[i] == 'N' ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw wind direction arrow
    final arrowAngle = (degrees - 90) * math.pi / 180;
    final arrowLength = radius - 35;

    final arrowPaint = Paint()
      ..color = arrowColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Arrow line
    final arrowEnd = Offset(
      center.dx + arrowLength * math.cos(arrowAngle),
      center.dy + arrowLength * math.sin(arrowAngle),
    );

    // Draw arrow head
    final arrowHeadPath = Path();
    final arrowHeadSize = 10.0;
    final arrowTipX = center.dx + arrowLength * math.cos(arrowAngle);
    final arrowTipY = center.dy + arrowLength * math.sin(arrowAngle);

    arrowHeadPath.moveTo(arrowTipX, arrowTipY);
    arrowHeadPath.lineTo(
      arrowTipX - arrowHeadSize * math.cos(arrowAngle - 0.4),
      arrowTipY - arrowHeadSize * math.sin(arrowAngle - 0.4),
    );
    arrowHeadPath.moveTo(arrowTipX, arrowTipY);
    arrowHeadPath.lineTo(
      arrowTipX - arrowHeadSize * math.cos(arrowAngle + 0.4),
      arrowTipY - arrowHeadSize * math.sin(arrowAngle + 0.4),
    );

    // Draw arrow from center to tip
    canvas.drawLine(center, arrowEnd, arrowPaint);
    canvas.drawPath(arrowHeadPath, arrowPaint);

    // Draw center dot
    final centerDotPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.degrees != degrees;
  }
}
