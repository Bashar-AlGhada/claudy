import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:claudy/features/weather/ui/background/cloud_animation.dart';
import 'package:claudy/features/weather/ui/background/fog_animation.dart';
import 'package:claudy/features/weather/ui/background/rain_animation.dart';
import 'package:claudy/features/weather/ui/background/snow_animation.dart';
import 'package:claudy/features/weather/ui/background/sun_animation.dart';
import 'package:claudy/features/weather/ui/background/thunder_animation.dart';
import 'package:claudy/features/weather/providers/weather_reading_provider.dart';
import 'package:claudy/features/weather/ui/background/visual_mapping.dart';
import 'package:claudy/core/theme/tokens.dart';

enum WeatherVisual { clear, clouds, rain, snow, fog, thunder }

class WeatherBackground extends ConsumerWidget {
  const WeatherBackground({
    super.key,
    required this.child,
    required this.lowPower,
  });
  final Widget child;
  final bool lowPower;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reading = ref.watch(weatherReadingProvider);
    return reading.when(
      data: (value) {
        final visual = value == null
            ? WeatherVisual.clouds
            : mapOpenWeatherCode(value.snapshot.current.conditionCode);
        final colors = _gradientFor(visual, Theme.of(context).colorScheme);
        return _BackgroundLayer(
          colors: colors,
          visual: visual,
          lowPower: lowPower,
          child: child,
        );
      },
      error: (_, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: child,
        );
      },
      loading: () {
        final colors = _gradientFor(
          WeatherVisual.clouds,
          Theme.of(context).colorScheme,
        );
        return _BackgroundLayer(
          colors: colors,
          visual: WeatherVisual.clouds,
          lowPower: lowPower,
          child: child,
        );
      },
    );
  }

  List<Color> _gradientFor(WeatherVisual v, ColorScheme scheme) {
    switch (v) {
      case WeatherVisual.clear:
        return [scheme.primary.withValues(alpha: 0.12), scheme.surface];
      case WeatherVisual.clouds:
        return [
          scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          scheme.surface,
        ];
      case WeatherVisual.rain:
        return [
          Colors.blueGrey.shade700.withValues(alpha: 0.22),
          scheme.surface,
        ];
      case WeatherVisual.snow:
        return [
          Colors.blueGrey.shade200.withValues(alpha: 0.20),
          scheme.surface,
        ];
      case WeatherVisual.fog:
        return [Colors.grey.shade500.withValues(alpha: 0.20), scheme.surface];
      case WeatherVisual.thunder:
        return [Colors.indigo.shade700.withValues(alpha: 0.24), scheme.surface];
    }
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({
    required this.colors,
    required this.visual,
    required this.lowPower,
    required this.child,
  });

  final List<Color> colors;
  final WeatherVisual visual;
  final bool lowPower;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget? animationLayer = lowPower
        ? null
        : RepaintBoundary(child: _animationFor(visual));
    return AnimatedContainer(
      duration: Tokens.motionSlow,
      curve: Tokens.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (animationLayer case final Widget layer) layer,
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.08),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _animationFor(WeatherVisual visual) {
    switch (visual) {
      case WeatherVisual.clear:
        return SunAnimation(lowPower: lowPower);
      case WeatherVisual.clouds:
        return CloudAnimation(lowPower: lowPower);
      case WeatherVisual.rain:
        return RainAnimation(lowPower: lowPower);
      case WeatherVisual.snow:
        return SnowAnimation(lowPower: lowPower);
      case WeatherVisual.fog:
        return FogAnimation(lowPower: lowPower);
      case WeatherVisual.thunder:
        return Stack(
          fit: StackFit.expand,
          children: [
            RainAnimation(intensity: 1.0, lowPower: lowPower),
            ThunderAnimation(intensity: 1.0, lowPower: lowPower),
          ],
        );
    }
  }
}
