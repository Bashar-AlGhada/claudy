import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/features/weather/ui/background/particle_animation.dart';

/// Parallax cloud layers animation with smooth drifting motion.
class CloudAnimation extends ParticleAnimation {
  const CloudAnimation({super.key, super.intensity, super.lowPower});

  @override
  State<CloudAnimation> createState() => _CloudAnimationState();
}

class _CloudAnimationState extends ParticleAnimationState<CloudAnimation> {
  static const int _maxCloudsPerLayer = 5;

  late List<_CloudLayer> _layers;

  @override
  Duration get cycleDuration => Tokens.weatherAnimationDuration * 3;

  @override
  Random createRandom() => Random(123);

  @override
  void regenerate() {
    final clampedIntensity = widget.intensity.clamp(0.0, 1.0);
    _layers = [
      _createLayer(depth: 0, cloudCount: _boundedCount(3, clampedIntensity)),
      _createLayer(depth: 1, cloudCount: _boundedCount(4, clampedIntensity)),
      _createLayer(depth: 2, cloudCount: _boundedCount(5, clampedIntensity)),
    ];
  }

  int _boundedCount(int base, double intensity) {
    final scaled = (base * intensity).ceil();
    final minimum = intensity > 0 ? 1 : 0;
    return scaled.clamp(minimum, _maxCloudsPerLayer);
  }

  _CloudLayer _createLayer({required int depth, required int cloudCount}) {
    final speed = 0.05 + depth * 0.03;
    final opacity = 0.15 - depth * 0.03;
    final scale = 1.0 - depth * 0.2;

    return _CloudLayer(
      clouds: List.generate(
        cloudCount,
        (_) => _Cloud(
          x: random.nextDouble() * 1.5 - 0.25,
          y: 0.05 + random.nextDouble() * 0.35,
          width: (0.25 + random.nextDouble() * 0.3) * scale,
          height: (0.06 + random.nextDouble() * 0.06) * scale,
          puffSpecs: _createPuffSpecs(3 + random.nextInt(4)),
        ),
      ),
      speed: speed,
      opacity: opacity,
      depth: depth,
    );
  }

  List<_PuffSpec> _createPuffSpecs(int count) {
    return List.generate(
      count,
      (_) => _PuffSpec(
        yOffsetFactor: (random.nextDouble() - 0.5),
        widthFactor: 0.8 + random.nextDouble() * 0.4,
        heightFactor: 0.7 + random.nextDouble() * 0.6,
      ),
    );
  }

  @override
  CustomPainter createPainter(double progress) =>
      _CloudPainter(layers: _layers, progress: progress);
}

class _CloudLayer {
  _CloudLayer({
    required this.clouds,
    required this.speed,
    required this.opacity,
    required this.depth,
  });

  final List<_Cloud> clouds;
  final double speed;
  final double opacity;
  final int depth;
}

class _Cloud {
  _Cloud({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.puffSpecs,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final List<_PuffSpec> puffSpecs;
}

class _CloudPainter extends CustomPainter {
  _CloudPainter({required this.layers, required this.progress});

  static final Paint _cloudPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

  final List<_CloudLayer> layers;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers.reversed) {
      _drawLayer(canvas, size, layer);
    }
  }

  void _drawLayer(Canvas canvas, Size size, _CloudLayer layer) {
    for (final cloud in layer.clouds) {
      final x = ((cloud.x + progress * layer.speed) % 1.5) - 0.25;

      double edgeFade = 1.0;
      if (x < 0) {
        edgeFade = (x + 0.25) / 0.25;
      } else if (x > 1.0) {
        edgeFade = 1.0 - (x - 1.0) / 0.25;
      }
      edgeFade = edgeFade.clamp(0.0, 1.0);

      final opacity = layer.opacity * edgeFade;
      if (opacity <= 0) continue;

      _drawCloud(
        canvas,
        Offset(x * size.width, cloud.y * size.height),
        cloud.width * size.width,
        cloud.height * size.height,
        cloud.puffSpecs,
        opacity,
      );
    }
  }

  void _drawCloud(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    List<_PuffSpec> puffs,
    double opacity,
  ) {
    final paint = _cloudPaint..color = Colors.white.withValues(alpha: opacity);

    for (var i = 0; i < puffs.length; i++) {
      final puff = puffs[i];
      final puffX =
          center.dx + (i - puffs.length / 2) * (width / puffs.length) * 0.8;
      final puffY = center.dy + puff.yOffsetFactor * height * 0.5;
      final puffWidth = width / puffs.length * puff.widthFactor;
      final puffHeight = height * puff.heightFactor;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(puffX, puffY),
          width: puffWidth,
          height: puffHeight,
        ),
        paint,
      );
    }

    canvas.drawOval(
      Rect.fromCenter(center: center, width: width * 0.5, height: height * 1.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.layers != layers;
}

class _PuffSpec {
  const _PuffSpec({
    required this.yOffsetFactor,
    required this.widthFactor,
    required this.heightFactor,
  });

  final double yOffsetFactor;
  final double widthFactor;
  final double heightFactor;
}
