import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/features/weather/ui/background/particle_animation.dart';

/// Rain animation with varying drop sizes, speeds, and wind angles.
class RainAnimation extends ParticleAnimation {
  const RainAnimation({super.key, super.intensity, super.lowPower});

  @override
  State<RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends ParticleAnimationState<RainAnimation> {
  static const int _minDropCount = 24;
  static const int _maxDropCount = 80;

  late List<_Raindrop> _drops;

  @override
  Duration get cycleDuration => Tokens.particleAnimationDuration;

  int get _dropCount {
    final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
    return (50 + (30 * clampedIntensity).toInt()).clamp(
      _minDropCount,
      _maxDropCount,
    );
  }

  @override
  void regenerate() {
    _drops = List.generate(_dropCount, (_) => _createDrop());
  }

  _Raindrop _createDrop() {
    final speedMultiplier =
        0.6 + (random.nextDouble() * 0.8 * widget.intensity);
    return _Raindrop(
      x: random.nextDouble(),
      y: random.nextDouble(),
      length: 8 + random.nextDouble() * 12 * widget.intensity,
      speed: speedMultiplier,
      thickness: 1.0 + random.nextDouble() * 1.5,
      angle: -0.1 + random.nextDouble() * 0.2,
      opacity: 0.3 + random.nextDouble() * 0.4,
    );
  }

  @override
  CustomPainter createPainter(double progress) => _RainPainter(
        drops: _drops,
        progress: progress,
        intensity: widget.intensity,
      );
}

class _Raindrop {
  _Raindrop({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.thickness,
    required this.angle,
    required this.opacity,
  });

  double x;
  double y;
  final double length;
  final double speed;
  final double thickness;
  final double angle;
  final double opacity;
}

class _RainPainter extends CustomPainter {
  _RainPainter({
    required this.drops,
    required this.progress,
    required this.intensity,
  });

  final List<_Raindrop> drops;
  final double progress;
  final double intensity;
  static final Paint _dropPaint = Paint()..strokeCap = StrokeCap.round;
  static final Paint _ripplePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    final clampedIntensity = intensity.clamp(0.0, 1.0);
    final windOffset = sin(progress * pi * 2) * 0.02 * clampedIntensity;

    for (final drop in drops) {
      final y = (drop.y + progress * drop.speed * 2) % 1.2 - 0.1;
      final x = (drop.x + windOffset + progress * drop.angle * 0.5) % 1.0;

      final startX = x * size.width;
      final startY = y * size.height;
      final endX = startX + sin(drop.angle) * drop.length;
      final endY = startY + cos(drop.angle) * drop.length;

      _dropPaint
        ..color = Colors.white.withValues(alpha: drop.opacity * 0.6)
        ..strokeWidth = drop.thickness;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), _dropPaint);
    }

    _drawRipples(canvas, size, clampedIntensity);
  }

  void _drawRipples(Canvas canvas, Size size, double clampedIntensity) {
    final rippleCount = (8 * clampedIntensity).round().clamp(0, 8);

    for (var i = 0; i < rippleCount; i++) {
      final baseX = ((i * 0.173) % 1.0) * size.width;
      final ripplePhase = (progress + i * 0.12) % 1.0;
      final radius = ripplePhase * 8;
      final opacity = (1.0 - ripplePhase) * 0.3;
      final y = size.height - 20 + (((i * 0.311) % 1.0) * 15);

      _ripplePaint.color = Colors.white.withValues(alpha: opacity);

      canvas.drawCircle(Offset(baseX, y), radius, _ripplePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.drops != drops;
}
