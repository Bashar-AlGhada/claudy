import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/features/weather/ui/background/particle_animation.dart';

/// Snowfall animation with drifting, rotating snowflakes.
class SnowAnimation extends ParticleAnimation {
  const SnowAnimation({super.key, super.intensity, super.lowPower});

  @override
  State<SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends ParticleAnimationState<SnowAnimation> {
  static const int _minFlakeCount = 16;
  static const int _maxFlakeCount = 60;

  late List<_Snowflake> _flakes;

  @override
  Duration get cycleDuration => Tokens.weatherAnimationDuration;

  int get _flakeCount {
    final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
    return (40 + (20 * clampedIntensity).toInt()).clamp(
      _minFlakeCount,
      _maxFlakeCount,
    );
  }

  @override
  void regenerate() {
    _flakes = List.generate(_flakeCount, (_) => _createFlake());
  }

  _Snowflake _createFlake() {
    return _Snowflake(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 2 + random.nextDouble() * 6,
      speed: 0.15 + random.nextDouble() * 0.25,
      driftAmplitude: 0.02 + random.nextDouble() * 0.04,
      driftFrequency: 0.5 + random.nextDouble() * 1.5,
      rotation: random.nextDouble() * pi * 2,
      rotationSpeed: (random.nextDouble() - 0.5) * 0.5,
      opacity: 0.4 + random.nextDouble() * 0.5,
      phase: random.nextDouble() * pi * 2,
    );
  }

  @override
  CustomPainter createPainter(double progress) =>
      _SnowPainter(flakes: _flakes, progress: progress);
}

class _Snowflake {
  _Snowflake({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.driftAmplitude,
    required this.driftFrequency,
    required this.rotation,
    required this.rotationSpeed,
    required this.opacity,
    required this.phase,
  });

  double x;
  double y;
  final double size;
  final double speed;
  final double driftAmplitude;
  final double driftFrequency;
  double rotation;
  final double rotationSpeed;
  final double opacity;
  final double phase;
}

class _SnowPainter extends CustomPainter {
  _SnowPainter({required this.flakes, required this.progress});

  static final Paint _flakePaint = Paint()
    ..strokeWidth = 1.0
    ..style = PaintingStyle.fill;

  final List<_Snowflake> flakes;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final flake in flakes) {
      final y = (flake.y + progress * flake.speed) % 1.1 - 0.05;

      final drift =
          sin(progress * pi * 2 * flake.driftFrequency + flake.phase) *
          flake.driftAmplitude;
      final x = (flake.x + drift) % 1.0;

      final centerX = x * size.width;
      final centerY = y * size.height;
      final currentRotation =
          flake.rotation + progress * flake.rotationSpeed * pi * 2;

      canvas.save();
      canvas.translate(centerX, centerY);
      canvas.rotate(currentRotation);

      _drawSnowflake(canvas, flake);

      canvas.restore();
    }
  }

  void _drawSnowflake(Canvas canvas, _Snowflake flake) {
    final paint = _flakePaint
      ..color = Colors.white.withValues(alpha: flake.opacity);

    final gradient = RadialGradient(
      colors: [
        Colors.white.withValues(alpha: flake.opacity),
        Colors.white.withValues(alpha: flake.opacity * 0.3),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final rect = Rect.fromCircle(center: Offset.zero, radius: flake.size);
    paint.shader = gradient.createShader(rect);
    canvas.drawCircle(Offset.zero, flake.size, paint);

    if (flake.size > 4) {
      paint
        ..shader = null
        ..color = Colors.white.withValues(alpha: flake.opacity * 0.6)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke;

      for (var i = 0; i < 6; i++) {
        final angle = i * pi / 3;
        final armLength = flake.size * 0.8;
        canvas.drawLine(
          Offset.zero,
          Offset(cos(angle) * armLength, sin(angle) * armLength),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SnowPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.flakes != flakes;
}
