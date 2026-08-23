import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/features/weather/ui/background/particle_animation.dart';

/// Clear-night sky: twinkling stars, a cratered moon with a pulsing halo,
/// and an occasional shooting star.
class StarryNightAnimation extends ParticleAnimation {
  const StarryNightAnimation({super.key, super.intensity, super.lowPower});

  @override
  State<StarryNightAnimation> createState() => _StarryNightState();
}

class _StarryNightState extends ParticleAnimationState<StarryNightAnimation> {
  late List<_Star> _stars;

  @override
  Duration get cycleDuration => Tokens.weatherAnimationDuration;

  @override
  Random createRandom() => Random(789);

  @override
  void regenerate() {
    // Floor at 0.3 so the sky never goes fully starless for low intensities;
    // callers pass 1.0 today but the widget contract allows less.
    final clampedIntensity = widget.intensity.clamp(0.3, 1.0);
    final count = (90 * clampedIntensity).round();
    _stars = List.generate(count, (_) => _createStar());
  }

  _Star _createStar() {
    return _Star(
      x: random.nextDouble(),
      y: random.nextDouble() * 0.8,
      radius: 0.5 + random.nextDouble() * 1.4,
      phase: random.nextDouble() * pi * 2,
      twinkleSpeed: 0.5 + random.nextDouble() * 2,
      baseAlpha: 0.35 + random.nextDouble() * 0.6,
      sparkle: random.nextDouble() < 0.12,
    );
  }

  @override
  CustomPainter createPainter(double progress) =>
      _StarryNightPainter(stars: _stars, progress: progress);
}

class _Star {
  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.phase,
    required this.twinkleSpeed,
    required this.baseAlpha,
    required this.sparkle,
  });

  final double x;
  final double y;
  final double radius;
  final double phase;
  final double twinkleSpeed;
  final double baseAlpha;
  final bool sparkle;
}

class _StarryNightPainter extends CustomPainter {
  _StarryNightPainter({required this.stars, required this.progress});

  static const Color _starColor = Color(0xFFF6F7FF);
  static const Color _moonColor = Color(0xFFF3EEDD);
  static const Color _craterColor = Color(0xFFDDD5BC);
  static const Color _glowColor = Color(0xFFEDE9FF);

  /// Window within the cycle where the shooting star is visible.
  static const double _shootingStart = 0.72;
  static const double _shootingEnd = 0.86;

  final List<_Star> stars;
  final double progress;

  final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final twinkle =
          (sin(progress * pi * 2 * star.twinkleSpeed + star.phase) + 1) / 2;
      final alpha = star.baseAlpha * (0.35 + 0.65 * twinkle);
      final center = Offset(star.x * size.width, star.y * size.height);

      _paint
        ..shader = null
        ..style = PaintingStyle.fill
        ..color = _starColor.withValues(alpha: alpha);
      canvas.drawCircle(center, star.radius, _paint);

      if (star.sparkle && star.radius > 1.2) {
        _paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8;
        final arm = star.radius * (2.2 + twinkle * 1.6);
        canvas.drawLine(
          center - Offset(arm, 0),
          center + Offset(arm, 0),
          _paint,
        );
        canvas.drawLine(
          center - Offset(0, arm),
          center + Offset(0, arm),
          _paint,
        );
      }
    }

    _drawMoon(canvas, size);
    _drawShootingStar(canvas, size);
  }

  void _drawMoon(Canvas canvas, Size size) {
    final moonRadius =
        (size.shortestSide * 0.07).clamp(24.0, 44.0).toDouble();
    final center = Offset(size.width * 0.78, size.height * 0.18);

    final pulse = 1.0 + sin(progress * pi * 2) * 0.05;
    final glowRadius = moonRadius * 3.2 * pulse;
    final glow = RadialGradient(
      colors: [
        _glowColor.withValues(alpha: 0.22),
        _glowColor.withValues(alpha: 0.08),
        _glowColor.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    _paint.style = PaintingStyle.fill;
    _paint.shader = glow.createShader(
      Rect.fromCircle(center: center, radius: glowRadius),
    );
    canvas.drawCircle(center, glowRadius, _paint);

    final disc = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      colors: const [Colors.white, _moonColor, Color(0xFFE2DBC2)],
      stops: const [0.0, 0.6, 1.0],
    );
    _paint.shader = disc.createShader(
      Rect.fromCircle(center: center, radius: moonRadius),
    );
    canvas.drawCircle(center, moonRadius, _paint);

    _paint.shader = null;
    _paint.color = _craterColor.withValues(alpha: 0.85);
    final craters = [
      Offset(-0.28, -0.12),
      Offset(0.18, 0.26),
      Offset(0.34, -0.3),
      Offset(-0.1, 0.42),
    ];
    for (var i = 0; i < craters.length; i++) {
      canvas.drawCircle(
        center + craters[i] * moonRadius,
        moonRadius * (0.09 + 0.04 * (i % 3)),
        _paint,
      );
    }
  }

  void _drawShootingStar(Canvas canvas, Size size) {
    if (progress < _shootingStart || progress > _shootingEnd) return;

    final t = (progress - _shootingStart) / (_shootingEnd - _shootingStart);
    final fade = sin(pi * t);

    final head = Offset(
      size.width * (0.12 + 0.52 * t),
      size.height * (0.08 + 0.30 * t),
    );
    const direction = Offset(1.0, 0.58);
    final tailLength = size.width * 0.11;
    final tail = head - direction * tailLength;

    _paint.shader = LinearGradient(
      colors: [
        _starColor.withValues(alpha: 0.9 * fade),
        _starColor.withValues(alpha: 0),
      ],
    ).createShader(Rect.fromPoints(tail, head));
    _paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(head, tail, _paint);

    _paint
      ..shader = null
      ..style = PaintingStyle.fill
      ..color = _starColor.withValues(alpha: fade);
    canvas.drawCircle(head, 1.8, _paint);
  }

  @override
  bool shouldRepaint(covariant _StarryNightPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.stars != stars;
}
