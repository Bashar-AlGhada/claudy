import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:claudy/features/weather/providers/weather_reading_provider.dart';
import 'package:claudy/features/weather/ui/background/visual_mapping.dart';
import 'package:claudy/core/theme/tokens.dart';

enum WeatherVisual { clear, clouds, rain, snow, fog, thunder }

class WeatherBackground extends ConsumerStatefulWidget {
  const WeatherBackground({super.key, required this.child, required this.lowPower});
  final Widget child;
  final bool lowPower;

  @override
  ConsumerState<WeatherBackground> createState() => _WeatherBackgroundState();
}

class _WeatherBackgroundState extends ConsumerState<WeatherBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reading = ref.watch(weatherReadingProvider);
    return reading.when(
      data: (value) {
        if (value == null) {
          return Container(color: Theme.of(context).colorScheme.surface, child: widget.child);
        }
        final visual = mapOpenWeatherCode(value.snapshot.current.conditionCode);
        if (widget.lowPower) {
          return Container(color: Theme.of(context).colorScheme.surface, child: widget.child);
        }
        final colors = _gradientFor(visual, Theme.of(context).colorScheme);
        return AnimatedContainer(
          duration: Tokens.motionSlow,
          curve: Tokens.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => CustomPaint(painter: _ParticlePainter(_controller.value, visual)),
              ),
              Container(decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.08))),
              widget.child,
            ],
          ),
        );
      },
      error: (_, stackTrace) {
        return Container(color: Theme.of(context).colorScheme.surface, child: widget.child);
      },
      loading: () {
        if (widget.lowPower) {
          return Container(color: Theme.of(context).colorScheme.surface, child: widget.child);
        }
        final colors = _gradientFor(WeatherVisual.clouds, Theme.of(context).colorScheme);
        return AnimatedContainer(
          duration: Tokens.motionSlow,
          curve: Tokens.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
          ),
          child: widget.child,
        );
      },
    );
  }

  List<Color> _gradientFor(WeatherVisual v, ColorScheme scheme) {
    switch (v) {
      case WeatherVisual.clear:
        return [scheme.primary.withValues(alpha: 0.12), scheme.surface];
      case WeatherVisual.clouds:
        return [scheme.surfaceContainerHighest.withValues(alpha: 0.18), scheme.surface];
      case WeatherVisual.rain:
        return [Colors.blueGrey.shade700.withValues(alpha: 0.22), scheme.surface];
      case WeatherVisual.snow:
        return [Colors.blueGrey.shade200.withValues(alpha: 0.20), scheme.surface];
      case WeatherVisual.fog:
        return [Colors.grey.shade500.withValues(alpha: 0.20), scheme.surface];
      case WeatherVisual.thunder:
        return [Colors.indigo.shade700.withValues(alpha: 0.24), scheme.surface];
    }
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.t, this.visual);
  final double t;
  final WeatherVisual visual;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(42);
    final count = 24;
    final paint = Paint()
      ..color = switch (visual) {
        WeatherVisual.rain => Colors.blueGrey.withValues(alpha: 0.25),
        WeatherVisual.snow => Colors.white.withValues(alpha: 0.35),
        WeatherVisual.clouds => Colors.white.withValues(alpha: 0.12),
        WeatherVisual.fog => Colors.white.withValues(alpha: 0.18),
        WeatherVisual.thunder => Colors.yellow.withValues(alpha: 0.10),
        WeatherVisual.clear => Colors.white.withValues(alpha: 0.0),
      }
      ..strokeWidth = 1.0;
    for (var i = 0; i < count; i++) {
      final x = (rnd.nextDouble() * size.width + t * 40) % size.width;
      final y = (rnd.nextDouble() * size.height + t * 60) % size.height;
      switch (visual) {
        case WeatherVisual.rain:
          canvas.drawLine(Offset(x, y), Offset(x, y + 8), paint);
        case WeatherVisual.snow:
          canvas.drawCircle(Offset(x, y), 2.0, paint);
        case WeatherVisual.clouds:
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        case WeatherVisual.fog:
          canvas.drawLine(Offset(x - 10, y), Offset(x + 10, y), paint);
        case WeatherVisual.thunder:
          canvas.drawLine(Offset(x, y), Offset(x + 6, y + 6), paint);
        case WeatherVisual.clear:
        // no particles
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.visual != visual;
  }
}
