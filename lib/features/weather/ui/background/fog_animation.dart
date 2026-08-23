import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/features/weather/ui/background/particle_animation.dart';

/// Drifting fog/mist layers animation with depth effect.
class FogAnimation extends ParticleAnimation {
  const FogAnimation({super.key, super.intensity, super.lowPower});

  @override
  State<FogAnimation> createState() => _FogAnimationState();
}

class _FogAnimationState extends ParticleAnimationState<FogAnimation> {
  static const int _maxLayers = 5;

  late List<_FogLayer> _layers;

  @override
  Duration get cycleDuration => Tokens.weatherAnimationDuration * 4;

  @override
  Random createRandom() => Random(456);

  @override
  void regenerate() {
    final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
    final layerCount = (2 + (3 * clampedIntensity).round()).clamp(2, _maxLayers);
    _layers = List.generate(
      layerCount,
      (index) => _createLayer(index, layerCount),
    );
  }

  _FogLayer _createLayer(int index, int layerCount) {
    final depth = layerCount <= 1 ? 0.0 : index / (layerCount - 1);
    return _FogLayer(
      yPosition: 0.3 + depth * 0.5 + random.nextDouble() * 0.1,
      height: 0.15 + (1 - depth) * 0.2,
      speed: 0.02 + (1 - depth) * 0.03,
      direction: index.isEven ? 1.0 : -1.0,
      opacity:
          (0.13 + (1 - depth) * 0.15) * widget.intensity.clamp(0.0, 1.0),
      waveAmplitude: 0.03 + random.nextDouble() * 0.03,
      waveFrequency: 0.5 + random.nextDouble() * 0.5,
      phase: random.nextDouble() * pi * 2,
      seed: random.nextInt(10000),
    );
  }

  @override
  CustomPainter createPainter(double progress) => _FogPainter(
        layers: _layers,
        progress: progress,
        intensity: widget.intensity,
      );
}

class _FogLayer {
  _FogLayer({
    required this.yPosition,
    required this.height,
    required this.speed,
    required this.direction,
    required this.opacity,
    required this.waveAmplitude,
    required this.waveFrequency,
    required this.phase,
    required this.seed,
  });

  final double yPosition;
  final double height;
  final double speed;
  final double direction;
  final double opacity;
  final double waveAmplitude;
  final double waveFrequency;
  final double phase;
  final int seed;
}

class _FogPainter extends CustomPainter {
  _FogPainter({
    required this.layers,
    required this.progress,
    required this.intensity,
  });

  final List<_FogLayer> layers;
  final double progress;
  final double intensity;
  static final Paint _layerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  static final Paint _wispPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      _drawFogLayer(canvas, size, layer);
    }
  }

  void _drawFogLayer(Canvas canvas, Size size, _FogLayer layer) {
    final path = Path();

    final xOffset = (progress * layer.speed * layer.direction) % 1.0;

    const segments = 20;
    final points = List<Offset>.generate(segments + 1, (i) {
      final t = i / segments;
      final x = t * size.width * 2 - size.width * 0.5 + xOffset * size.width;
      final wave =
          sin(
            t * pi * 4 * layer.waveFrequency + progress * pi * 2 + layer.phase,
          ) *
          layer.waveAmplitude *
          size.height;
      final y = layer.yPosition * size.height + wave;
      return Offset(x, y);
    });

    path.moveTo(points.first.dx, size.height);
    path.lineTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    path.lineTo(points.last.dx, size.height);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withValues(alpha: 0),
        Colors.white.withValues(alpha: layer.opacity),
        Colors.white.withValues(alpha: layer.opacity * 0.8),
        Colors.white.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    );

    final layerRect = Rect.fromLTWH(
      0,
      layer.yPosition * size.height - layer.height * size.height,
      size.width,
      layer.height * size.height * 2,
    );

    final paint = _layerPaint..shader = gradient.createShader(layerRect);

    canvas.drawPath(path, paint);

    _drawWisps(canvas, size, layer, xOffset);
  }

  void _drawWisps(Canvas canvas, Size size, _FogLayer layer, double xOffset) {
    final wispCount = (6 * intensity.clamp(0.0, 1.0)).round();

    for (var i = 0; i < wispCount; i++) {
      final seed = layer.seed + i;
      final baseX = ((seed * 0.217) % 1.0);
      final x = ((baseX + xOffset * layer.direction) % 1.0) * size.width;
      final yFactor = (((seed * 0.391) % 1.0) - 0.5);
      final y =
          layer.yPosition * size.height + yFactor * layer.height * size.height;

      final wispWidth = 60 + ((seed * 0.173) % 1.0) * 80;
      final wispHeight = 14 + ((seed * 0.257) % 1.0) * 26;

      _wispPaint.color = Colors.white.withValues(alpha: layer.opacity * 0.5);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: wispWidth,
          height: wispHeight,
        ),
        _wispPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FogPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.intensity != intensity ||
      oldDelegate.layers != layers;
}
