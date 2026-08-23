import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/features/weather/ui/background/particle_animation.dart';

/// Animated sun with radiating rays and floating dust motes.
class SunAnimation extends ParticleAnimation {
  const SunAnimation({super.key, super.intensity, super.lowPower});

  @override
  State<SunAnimation> createState() => _SunAnimationState();
}

class _SunAnimationState extends ParticleAnimationState<SunAnimation> {
  late List<_DustMote> _motes;

  @override
  Duration get cycleDuration => Tokens.weatherAnimationDuration;

  int get _moteCount {
    final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
    return (20 * clampedIntensity).round();
  }

  @override
  Random createRandom() => Random(303);

  @override
  void regenerate() {
    _motes = List.generate(_moteCount, (_) => _createMote());
  }

  _DustMote _createMote() {
    return _DustMote(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 1 + random.nextDouble() * 3,
      speed: 0.02 + random.nextDouble() * 0.04,
      driftX: (random.nextDouble() - 0.5) * 0.02,
      opacity: 0.2 + random.nextDouble() * 0.4,
      phase: random.nextDouble() * pi * 2,
      twinkleSpeed: 1 + random.nextDouble() * 2,
    );
  }

  @override
  CustomPainter createPainter(double progress) => _SunPainter(
        progress: progress,
        intensity: widget.intensity,
        motes: _motes,
      );
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
  static final Paint _glowPaint = Paint();
  static final Paint _rayPaint = Paint()
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round;
  static final Paint _corePaint = Paint();
  static final Paint _innerCorePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

  static List<Color> _glowColors(double intensity) => [
        const Color(0xFFFFD54F).withValues(alpha: 0.25 * intensity),
        const Color(0xFFFFB300).withValues(alpha: 0.1 * intensity),
        const Color(0xFFFF8F00).withValues(alpha: 0.0),
      ];

  static List<Color> _rayColors(double intensity) => [
        const Color(0xFFFFD54F).withValues(alpha: 0.5 * intensity),
        const Color(0xFFFFB300).withValues(alpha: 0.0),
      ];

  @override
  void paint(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.8, size.height * 0.15);
    // shortestSide keeps the disc inside tall phone screens AND very wide
    // desktop windows alike (width-only scaling clipped the glow on ultrawide).
    final sunRadius = size.shortestSide * 0.08;

    _drawSunGlow(canvas, sunCenter, sunRadius);
    _drawSunRays(canvas, sunCenter, sunRadius);
    _drawSunCore(canvas, sunCenter, sunRadius);
    _drawDustMotes(canvas, size);
  }

  void _drawSunGlow(Canvas canvas, Offset center, double radius) {
    final pulseScale = 1.0 + sin(progress * pi * 2) * 0.08;
    final glowRadius = radius * 4 * pulseScale;

    final gradient = RadialGradient(
      colors: _glowColors(intensity),
      stops: const [0.0, 0.5, 1.0],
    );

    canvas.drawCircle(
      center,
      glowRadius,
      _glowPaint
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: glowRadius),
        ),
    );
  }

  void _drawSunRays(Canvas canvas, Offset center, double radius) {
    const rayCount = 12;
    final rayLength = radius * 2.5;

    final rotation = progress * pi * 2 * 0.1;
    final rayColors = _rayColors(intensity);

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

      canvas.drawLine(
        start,
        end,
        _rayPaint
          ..shader = LinearGradient(colors: rayColors)
              .createShader(Rect.fromPoints(start, end)),
      );
    }
  }

  void _drawSunCore(Canvas canvas, Offset center, double radius) {
    final breathScale = 1.0 + sin(progress * pi * 4) * 0.03;
    final coreRadius = radius * breathScale;

    final coreGradient = RadialGradient(
      colors: [
        const Color(0xFFFFF8E1).withValues(alpha: 0.9),
        const Color(0xFFFFD54F).withValues(alpha: 0.7),
        const Color(0xFFFFB300).withValues(alpha: 0.5),
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    canvas.drawCircle(
      center,
      coreRadius,
      _corePaint
        ..shader = coreGradient.createShader(
          Rect.fromCircle(center: center, radius: coreRadius),
        ),
    );

    canvas.drawCircle(center, coreRadius * 0.4, _innerCorePaint);
  }

  void _drawDustMotes(Canvas canvas, Size size) {
    for (final mote in motes) {
      final y = (mote.y - progress * mote.speed) % 1.2 - 0.1;
      final x =
          (mote.x +
              sin(progress * pi * 2 * mote.twinkleSpeed + mote.phase) * 0.02 +
              progress * mote.driftX) %
          1.0;

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
