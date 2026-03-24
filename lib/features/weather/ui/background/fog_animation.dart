import 'dart:math';
import 'package:flutter/material.dart';
import 'package:claudy/core/theme/tokens.dart';

/// Drifting fog/mist layers animation with depth effect.
class FogAnimation extends StatefulWidget {
  const FogAnimation({super.key, this.density = 1.0, this.lowPower = false});

  /// Fog density from 0.0 (light mist) to 1.0 (thick fog).
  final double density;

  /// Disables animation when battery saving is active.
  final bool lowPower;

  @override
  State<FogAnimation> createState() => _FogAnimationState();
}

class _FogAnimationState extends State<FogAnimation>
    with SingleTickerProviderStateMixin {
  static const int _maxLayers = 5;
  late AnimationController _controller;
  late List<_FogLayer> _layers;
  final Random _random = Random(456);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Tokens.weatherAnimationDuration * 4,
    )..repeat();
    _initLayers();
  }

  void _initLayers() {
    final clampedDensity = widget.density.clamp(0.0, 1.0);
    final layerCount = (2 + (3 * clampedDensity).round()).clamp(2, _maxLayers);
    _layers = List.generate(
      layerCount,
      (index) => _createLayer(index, layerCount),
    );
  }

  _FogLayer _createLayer(int index, int layerCount) {
    // Layers at different depths with varying properties
    final depth = layerCount <= 1 ? 0.0 : index / (layerCount - 1);
    return _FogLayer(
      yPosition: 0.3 + depth * 0.5 + _random.nextDouble() * 0.1,
      height: 0.15 + (1 - depth) * 0.2,
      speed: 0.02 + (1 - depth) * 0.03,
      direction: index.isEven ? 1.0 : -1.0,
      opacity: (0.08 + (1 - depth) * 0.12) * widget.density,
      waveAmplitude: 0.02 + _random.nextDouble() * 0.02,
      waveFrequency: 0.5 + _random.nextDouble() * 0.5,
      phase: _random.nextDouble() * pi * 2,
      seed: _random.nextInt(10000),
    );
  }

  @override
  void didUpdateWidget(FogAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.density != widget.density) {
      _initLayers();
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
          painter: _FogPainter(
            layers: _layers,
            progress: _controller.value,
            density: widget.density,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
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
    required this.density,
  });

  final List<_FogLayer> layers;
  final double progress;
  final double density;
  static final Paint _layerPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  static final Paint _wispPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      _drawFogLayer(canvas, size, layer);
    }
  }

  void _drawFogLayer(Canvas canvas, Size size, _FogLayer layer) {
    final path = Path();

    // Horizontal offset with wrapping
    final xOffset = (progress * layer.speed * layer.direction) % 1.0;

    // Build wavy fog shape
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

    // Create gradient fog band
    path.moveTo(points.first.dx, size.height);
    path.lineTo(points.first.dx, points.first.dy);

    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }

    path.lineTo(points.last.dx, size.height);
    path.close();

    // Gradient from transparent edges to opaque center
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

    // Additional wisp details
    _drawWisps(canvas, size, layer, xOffset);
  }

  void _drawWisps(Canvas canvas, Size size, _FogLayer layer, double xOffset) {
    final wispCount = (4 * density.clamp(0.0, 1.0)).round().clamp(0, 4);

    for (var i = 0; i < wispCount; i++) {
      final seed = layer.seed + i;
      final baseX = ((seed * 0.217) % 1.0);
      final x = ((baseX + xOffset * layer.direction) % 1.0) * size.width;
      final yFactor = (((seed * 0.391) % 1.0) - 0.5);
      final y =
          layer.yPosition * size.height + yFactor * layer.height * size.height;

      final wispWidth = 40 + ((seed * 0.173) % 1.0) * 60;
      final wispHeight = 10 + ((seed * 0.257) % 1.0) * 20;

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
      oldDelegate.density != density ||
      oldDelegate.layers != layers;
}
