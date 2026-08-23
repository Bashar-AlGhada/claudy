import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:claudy/core/logging/app_logger.dart';
import 'package:claudy/core/time/clock_provider.dart';
import 'package:claudy/features/weather/ui/background/cloud_animation.dart';
import 'package:claudy/features/weather/ui/background/fog_animation.dart';
import 'package:claudy/features/weather/ui/background/rain_animation.dart';
import 'package:claudy/features/weather/ui/background/snow_animation.dart';
import 'package:claudy/features/weather/ui/background/starry_night_animation.dart';
import 'package:claudy/features/weather/ui/background/sun_animation.dart';
import 'package:claudy/features/weather/ui/background/thunder_animation.dart';
import 'package:claudy/features/weather/providers/weather_reading_provider.dart';
import 'package:claudy/features/weather/ui/background/visual_mapping.dart';
import 'package:claudy/core/theme/tokens.dart';

enum WeatherVisual { clear, clearNight, clouds, rain, snow, fog, thunder }

/// Hidden debug scenarios forcing the background to a fixed state.
/// [auto] follows the real weather; anything else pins the pipeline.
enum BackgroundScenario {
  auto,
  clearDay,
  clearNight,
  cloudsDay,
  cloudsNight,
  rainDay,
  rainNight,
  snowDay,
  snowNight,
  fogDay,
  thunder;

  WeatherVisual get visual => switch (this) {
        BackgroundScenario.auto => WeatherVisual.clouds,
        BackgroundScenario.clearDay => WeatherVisual.clear,
        BackgroundScenario.clearNight => WeatherVisual.clearNight,
        BackgroundScenario.cloudsDay || BackgroundScenario.cloudsNight =>
          WeatherVisual.clouds,
        BackgroundScenario.rainDay || BackgroundScenario.rainNight =>
          WeatherVisual.rain,
        BackgroundScenario.snowDay || BackgroundScenario.snowNight =>
          WeatherVisual.snow,
        BackgroundScenario.fogDay => WeatherVisual.fog,
        BackgroundScenario.thunder => WeatherVisual.thunder,
      };

  bool get night => switch (this) {
        BackgroundScenario.clearNight ||
        BackgroundScenario.cloudsNight ||
        BackgroundScenario.rainNight ||
        BackgroundScenario.snowNight =>
          true,
        _ => false,
      };

  int? get code => switch (this) {
        BackgroundScenario.cloudsNight => 801,
        BackgroundScenario.cloudsDay => 802,
        _ => null,
      };
}

/// Active hidden preview scenario; [BackgroundScenario.auto] = production.
class BackgroundPreviewNotifier extends Notifier<BackgroundScenario> {
  @override
  BackgroundScenario build() => BackgroundScenario.auto;

  void set(BackgroundScenario scenario) => state = scenario;
}

final backgroundPreviewProvider = NotifierProvider<BackgroundPreviewNotifier, BackgroundScenario>(
  BackgroundPreviewNotifier.new,
);

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
    // Hidden debug override: pin the pipeline to a fixed scenario.
    final preview = ref.watch(backgroundPreviewProvider);
    if (preview != BackgroundScenario.auto) {
      return _visualLayer(
        context,
        preview.visual,
        lowPower: lowPower,
        conditionCode: preview.code,
        night: preview.night,
      );
    }

    final reading = ref.watch(weatherReadingProvider);

    // Derive the visual from the LAST KNOWN snapshot. reading.value spans
    // data, error-with-previous and loading-with-previous in Riverpod 3, so a
    // failed refresh or a reload can never blank the sky into a static
    // fallback - the hit-and-miss sun of previous builds.
    final snapshot = reading.value?.snapshot;

    // Prefer the current payload's solar times; fall back to today's daily
    // entry (some providers/cached snapshots only fill the latter).
    final current = snapshot?.current;
    final today = snapshot?.daily.firstOrNull;
    var sunrise = current?.sunrise ?? today?.sunrise;
    var sunset = current?.sunset ?? today?.sunset;
    if (sunrise == null || sunset == null) {
      sunrise = null;
      sunset = null;
    }
    final solar = sunrise != null && sunset != null;

    // Watched so clear/clearNight flips at sunrise/sunset without needing an
    // unrelated rebuild. Only subscribed when solar times exist — that is the
    // sole scenario where time can change the visual.
    final now = solar
        ? (ref.watch(wallClockProvider).value ?? ref.read(clockProvider).now())
        : ref.read(clockProvider).now();

    final daytime = isDaytimeNow(now: now, sunrise: sunrise, sunset: sunset);
    final visual = snapshot == null
        ? WeatherVisual.clouds
        : mapOpenWeatherCode(snapshot.current.conditionCode, isDaytime: daytime);
    _logVisualOnce(visual, daytime, snapshot?.current.conditionCode);

    return _visualLayer(
      context,
      visual,
      lowPower: lowPower,
      conditionCode: snapshot?.current.conditionCode,
      night: !daytime,
    );
  }

  /// One line per visual change, so "why does the sky look like X" is always
  /// answerable from the diagnostics log.
  static String? _lastVisualLog;
  void _logVisualOnce(WeatherVisual visual, bool daytime, int? code) {
    final key = '${visual.name}/day=$daytime/code=${code ?? '-'}';
    if (key == _lastVisualLog) return;
    _lastVisualLog = key;
    AppLogger.info('Background visual: $key');
  }

  Widget _visualLayer(
    BuildContext context,
    WeatherVisual visual, {
    required bool lowPower,
    int? conditionCode,
    bool night = false,
  }) {
    return _BackgroundLayer(
      colors: _gradientFor(visual, night: night),
      visual: visual,
      lowPower: lowPower,
      conditionCode: conditionCode,
      night: night,
      child: child,
    );
  }

  /// Fixed sky palettes keyed by condition and time of day. Deliberately
  /// independent of the app theme: a clear afternoon must read as a bright
  /// sky even in dark mode, and nights stay deep navy in light mode.
  List<Color> _gradientFor(WeatherVisual v, {required bool night}) {
    switch (v) {
      case WeatherVisual.clear:
        return night
            ? const [Color(0xFF0B1233), Color(0xFF16204A), Color(0xFF27335F)]
            : const [Color(0xFF4FA8E8), Color(0xFF9FD4F5)];
      case WeatherVisual.clearNight:
        return const [
          Color(0xFF0B1233),
          Color(0xFF16204A),
          Color(0xFF27335F),
        ];
      case WeatherVisual.clouds:
        return night
            ? const [Color(0xFF10182E), Color(0xFF1D2740)]
            : const [Color(0xFF63A9E4), Color(0xFFA9D2F2)];
      case WeatherVisual.rain:
        return night
            ? const [Color(0xFF0E1420), Color(0xFF1A2434)]
            : const [Color(0xFF7E96AC), Color(0xFFC9D6E2)];
      case WeatherVisual.snow:
        // Same rainy-sky family as rain, a touch bluer and softer for
        // snowing clouds. Snow nights glow lighter and colder than rain
        // nights (snow reflects moonlight).
        return night
            ? const [Color(0xFF1B2440), Color(0xFF334066)]
            : const [Color(0xFF8CA2B8), Color(0xFFD4E0EC)];
      case WeatherVisual.fog:
        // Muted grey-blue: bright fog palettes glare on desktop screens.
        return night
            ? const [Color(0xFF151B26), Color(0xFF242D3A)]
            : const [Color(0xFF9FAAB8), Color(0xFFCBD4DE)];
      case WeatherVisual.thunder:
        return const [Color(0xFF232E44), Color(0xFF4C5D75)];
    }
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({
    required this.colors,
    required this.visual,
    required this.lowPower,
    required this.child,
    this.conditionCode,
    this.night = false,
  });

  final List<Color> colors;
  final WeatherVisual visual;
  final bool lowPower;
  final Widget child;

  /// Raw OpenWeather condition code; refines cloud density/night composition.
  final int? conditionCode;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final Widget? animationLayer =
        lowPower ? null : _animationFor(visual, conditionCode, night);
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

  Widget _animationFor(WeatherVisual visual, int? code, bool night) {
    switch (visual) {
      case WeatherVisual.clear:
        return SunAnimation(lowPower: lowPower);
      case WeatherVisual.clearNight:
        return StarryNightAnimation(lowPower: lowPower);
      case WeatherVisual.clouds:
        // Few/scattered clouds on a clear night keep the starry sky visible
        // behind a few dimmed puffs instead of a wall of white.
        if (night && (code == 801 || code == 802)) {
          return Stack(
            fit: StackFit.expand,
            children: [
              StarryNightAnimation(lowPower: lowPower),
              CloudAnimation(
                intensity: code == 801 ? 0.35 : 0.6,
                night: true,
                lowPower: lowPower,
              ),
            ],
          );
        }
        return CloudAnimation(
          intensity: _cloudDensity(code),
          night: night,
          lowPower: lowPower,
        );
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

  /// 801 few clouds -> sparse; 804 overcast -> full coverage.
  static double _cloudDensity(int? code) {
    switch (code) {
      case 801:
        return 0.35;
      case 802:
        return 0.6;
      case 803:
        return 0.85;
      default:
        return 1.0;
    }
  }
}
