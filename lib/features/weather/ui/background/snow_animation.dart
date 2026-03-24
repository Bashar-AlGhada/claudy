import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';

/// Gentle snowfall animation with drifting, rotating snowflakes.
class SnowAnimation extends StatefulWidget {
  const SnowAnimation({super.key, this.intensity = 1.0, this.lowPower = false});

  /// Snow intensity from 0.0 (light flurries) to 1.0 (heavy snowfall).
  final double intensity;

  /// Disables animation when battery saving is active.
  final bool lowPower;

  @override
  State<SnowAnimation> createState() => _SnowAnimationState();
}

class _SnowAnimationState extends State<SnowAnimation>
    with SingleTickerProviderStateMixin {
  static const int _minFlakeCount = 16;
  static const int _maxFlakeCount = 60;
  late AnimationController _controller;
  late List<_Snowflake> _flakes;
  final Random _random = Random();

  int get _flakeCount {
    final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
    return (40 + (20 * clampedIntensity).toInt()).clamp(
      _minFlakeCount,
      _maxFlakeCount,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Tokens.weatherAnimationDuration,
    )..repeat();
    _initFlakes();
  }

  void _initFlakes() {
    _flakes = List.generate(_flakeCount, (_) => _createFlake());
  }

  _Snowflake _createFlake() {
    return _Snowflake(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: 2 + _random.nextDouble() * 6,
      speed: 0.15 + _random.nextDouble() * 0.25,
      driftAmplitude: 0.02 + _random.nextDouble() * 0.04,
      driftFrequency: 0.5 + _random.nextDouble() * 1.5,
      rotation: _random.nextDouble() * pi * 2,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.5,
      opacity: 0.4 + _random.nextDouble() * 0.5,
      phase: _random.nextDouble() * pi * 2,
    );
  }

  @override
  void didUpdateWidget(SnowAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intensity != widget.intensity) {
      _initFlakes();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lowPower) return const SizedBox.expand();

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _SnowPainter(flakes: _flakes, progress: _controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
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
      // Vertical movement with wrapping
      final y = (flake.y + progress * flake.speed) % 1.1 - 0.05;

      // Horizontal sine wave drift
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

    // Main body - soft circle with blur effect
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

    // Small arms for larger flakes
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
