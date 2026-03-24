import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';

/// Animated sun with radiating rays and floating dust motes.
class SunAnimation extends StatefulWidget {
  const SunAnimation({super.key, this.intensity = 1.0, this.lowPower = false});

  /// Sun intensity affecting brightness and particle count.
  final double intensity;

  /// Disables animation when battery saving is active.
  final bool lowPower;

  @override
  State<SunAnimation> createState() => _SunAnimationState();
}

class _SunAnimationState extends State<SunAnimation>
    with SingleTickerProviderStateMixin {
  static const int _maxMoteCount = 20;
  late AnimationController _controller;
  late List<_DustMote> _motes;
  final Random _random = Random();

  int get _moteCount {
    final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
    final count = (20 * clampedIntensity).round();
    return count.clamp(0, _maxMoteCount);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Tokens.weatherAnimationDuration,
    )..repeat();
    _initMotes();
  }

  void _initMotes() {
    _motes = List.generate(_moteCount, (_) => _createMote());
  }

  _DustMote _createMote() {
    return _DustMote(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: 1 + _random.nextDouble() * 3,
      speed: 0.02 + _random.nextDouble() * 0.04,
      driftX: (_random.nextDouble() - 0.5) * 0.02,
      opacity: 0.2 + _random.nextDouble() * 0.4,
      phase: _random.nextDouble() * pi * 2,
      twinkleSpeed: 1 + _random.nextDouble() * 2,
    );
  }

  @override
  void didUpdateWidget(SunAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intensity != widget.intensity) {
      _initMotes();
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
          painter: _SunPainter(
            progress: _controller.value,
            intensity: widget.intensity,
            motes: _motes,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DustMote {
  _DustMote({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.driftX,
    required this.opacity,
    required this.phase,
    required this.twinkleSpeed,
  });

  final double x;
  final double y;
  final double size;
  final double speed;
  final double driftX;
  final double opacity;
  final double phase;
  final double twinkleSpeed;
}

class _SunPainter extends CustomPainter {
  _SunPainter({
    required this.progress,
    required this.intensity,
    required this.motes,
  });

  final double progress;
  final double intensity;
  final List<_DustMote> motes;
  static final Paint _motePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

  @override
  void paint(Canvas canvas, Size size) {
    // Sun position: upper-right area
    final sunCenter = Offset(size.width * 0.8, size.height * 0.15);
    final sunRadius = size.width * 0.08;

    _drawSunGlow(canvas, sunCenter, sunRadius, size);
    _drawSunRays(canvas, sunCenter, sunRadius, size);
    _drawSunCore(canvas, sunCenter, sunRadius);
    _drawDustMotes(canvas, size);
  }

  void _drawSunGlow(Canvas canvas, Offset center, double radius, Size size) {
    // Pulsing outer glow
    final pulseScale = 1.0 + sin(progress * pi * 2) * 0.08;
    final glowRadius = radius * 4 * pulseScale;

    final gradient = RadialGradient(
      colors: [
        const Color(0xFFFFD54F).withValues(alpha: 0.25 * intensity),
        const Color(0xFFFFB300).withValues(alpha: 0.1 * intensity),
        const Color(0xFFFF8F00).withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: glowRadius),
      );

    canvas.drawCircle(center, glowRadius, paint);
  }

  void _drawSunRays(Canvas canvas, Offset center, double radius, Size size) {
    final rayCount = 12;
    final rayLength = radius * 2.5;

    final rotation = progress * pi * 2 * 0.1; // Slow rotation

    for (var i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * pi * 2 + rotation;
      final pulseOffset = sin(progress * pi * 4 + i * 0.5) * 0.15;
      final currentLength = rayLength * (0.85 + pulseOffset);

      final startDistance = radius * 1.2;
      final start = Offset(
        center.dx + cos(angle) * startDistance,
        center.dy + sin(angle) * startDistance,
      );
      final end = Offset(
        center.dx + cos(angle) * (startDistance + currentLength),
        center.dy + sin(angle) * (startDistance + currentLength),
      );

      // Gradient along ray
      final rayPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFFFFD54F).withValues(alpha: 0.5 * intensity),
            const Color(0xFFFFB300).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromPoints(start, end))
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, rayPaint);
    }
  }

  void _drawSunCore(Canvas canvas, Offset center, double radius) {
    // Breathing effect
    final breathScale = 1.0 + sin(progress * pi * 4) * 0.03;
    final coreRadius = radius * breathScale;

    // Core gradient
    final coreGradient = RadialGradient(
      colors: [
        const Color(0xFFFFF8E1).withValues(alpha: 0.9),
        const Color(0xFFFFD54F).withValues(alpha: 0.7),
        const Color(0xFFFFB300).withValues(alpha: 0.5),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );

    canvas.drawCircle(center, coreRadius, corePaint);

    // Inner bright spot
    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(center, coreRadius * 0.4, innerPaint);
  }

  void _drawDustMotes(Canvas canvas, Size size) {
    for (final mote in motes) {
      // Floating motion
      final y = (mote.y - progress * mote.speed) % 1.0;
      final x =
          (mote.x +
              sin(progress * pi * 2 * mote.twinkleSpeed + mote.phase) * 0.02 +
              progress * mote.driftX) %
          1.0;

      // Twinkle effect
      final twinkle =
          (sin(progress * pi * 2 * mote.twinkleSpeed + mote.phase) + 1) / 2;
      final opacity = mote.opacity * (0.5 + twinkle * 0.5);

      _motePaint.color = const Color(0xFFFFE082).withValues(alpha: opacity);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        mote.size,
        _motePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SunPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.motes != motes;
}
