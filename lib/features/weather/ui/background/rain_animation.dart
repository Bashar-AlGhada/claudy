import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';

/// Realistic rain animation with varying drop sizes, speeds, and wind angles.
class RainAnimation extends StatefulWidget {
  const RainAnimation({super.key, this.intensity = 1.0, this.lowPower = false});

  /// Rain intensity from 0.0 (light drizzle) to 1.0 (heavy downpour).
  final double intensity;

  /// Disables animation when battery saving is active.
  final bool lowPower;

  @override
  State<RainAnimation> createState() => _RainAnimationState();
}

class _RainAnimationState extends State<RainAnimation>
    with SingleTickerProviderStateMixin {
  static const int _minDropCount = 24;
  static const int _maxDropCount = 80;
  late AnimationController _controller;
  late List<_Raindrop> _drops;
  final Random _random = Random();

  int get _dropCount {
    final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
    return (50 + (30 * clampedIntensity).toInt()).clamp(
      _minDropCount,
      _maxDropCount,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Tokens.particleAnimationDuration,
    )..repeat();
    _initDrops();
  }

  void _initDrops() {
    _drops = List.generate(_dropCount, (_) => _createDrop());
  }

  _Raindrop _createDrop() {
    final speedMultiplier =
        0.6 + (_random.nextDouble() * 0.8 * widget.intensity);
    return _Raindrop(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      length: 8 + _random.nextDouble() * 12 * widget.intensity,
      speed: speedMultiplier,
      thickness: 1.0 + _random.nextDouble() * 1.5,
      angle: -0.1 + _random.nextDouble() * 0.2,
      opacity: 0.3 + _random.nextDouble() * 0.4,
    );
  }

  @override
  void didUpdateWidget(RainAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intensity != widget.intensity) {
      _initDrops();
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
          painter: _RainPainter(
            drops: _drops,
            progress: _controller.value,
            intensity: widget.intensity,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
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
      // Calculate position with wrapping
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

    // Draw ripples at bottom
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
