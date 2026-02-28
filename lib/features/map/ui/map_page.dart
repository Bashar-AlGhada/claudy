import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/features/map/data/map_provider_selector.dart';
import 'package:claudy/features/map/domain/map_overlay.dart';
import 'package:claudy/features/weather/data/weather_repository_impl.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:claudy/features/weather/ui/widgets/current_weather_card.dart';
import 'package:claudy/core/theme/tokens.dart';
import 'package:claudy/core/ui/app_skeleton.dart';
import 'package:claudy/core/ui/app_states.dart';
import 'package:claudy/core/ui/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  bool _radar = false;
  bool _heatmap = false;
  bool _wind = false;
  GeoCoordinate? _picked;
  AsyncValue<WeatherReading>? _reading;
  WeatherReading? _lastReading;

  Set<MapOverlay> get _overlays {
    final overlays = <MapOverlay>{};
    if (_radar) overlays.add(MapOverlay.radar);
    if (_heatmap) overlays.add(MapOverlay.heatmap);
    if (_wind) overlays.add(MapOverlay.wind);
    return overlays;
  }

  Future<void> _selectCoordinate(GeoCoordinate coordinate) async {
    setState(() {
      _picked = coordinate;
      _lastReading = _reading?.valueOrNull ?? _lastReading;
      _reading = const AsyncLoading();
    });

    await ref.read(locationProvider.notifier).setManualCoordinate(coordinate);
    await ref.read(locationProvider.notifier).setMode(LocationMode.manual);

    final repo = ref.read(weatherRepositoryProvider);
    final result = await repo.getWeather(coordinate, hours: 12, days: 5);
    if (!mounted) return;
    setState(() {
      _reading = result.fold(
        (failure) => AsyncError(failure, StackTrace.current),
        (reading) => AsyncData(reading),
      );
      final next = _reading?.valueOrNull;
      if (next != null) _lastReading = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(activeMapProvider);

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.navMap.tr)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            if (!wide) {
              return Column(
                children: [
                  AppConstrained(
                    padding: const EdgeInsets.all(Tokens.space16),
                    child: Text(LocaleKeys.mapTapHint.tr),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Tokens.cornerRadius),
                      ),
                      child: Semantics(
                        label: LocaleKeys.mapTapHint.tr,
                        child: provider.build(
                          overlays: _overlays,
                          marker: _picked,
                          onTap: _selectCoordinate,
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: Tokens.motionMedium,
                    switchInCurve: Tokens.easeOut,
                    switchOutCurve: Tokens.easeInOut,
                    child: _reading == null
                        ? const SizedBox.shrink()
                        : AppConstrained(
                            key: const ValueKey('map_weather_panel'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Tokens.space16,
                              vertical: Tokens.space12,
                            ),
                            child: _WeatherPanel(
                              reading: _reading!,
                              last: _lastReading,
                              onRetry: _picked == null ? null : () => _selectCoordinate(_picked!),
                            ),
                          ),
                  ),
                  AppConstrained(
                    padding: const EdgeInsets.all(Tokens.space16),
                    child: _OverlayChips(
                      radar: _radar,
                      heatmap: _heatmap,
                      wind: _wind,
                      onRadar: (v) => setState(() => _radar = v),
                      onHeatmap: (v) => setState(() => _heatmap = v),
                      onWind: (v) => setState(() => _wind = v),
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(Tokens.space16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Tokens.cornerRadius),
                      child: Semantics(
                        label: LocaleKeys.mapTapHint.tr,
                        child: provider.build(
                          overlays: _overlays,
                          marker: _picked,
                          onTap: _selectCoordinate,
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 420,
                  child: ListView(
                    padding: const EdgeInsets.all(Tokens.space16),
                    children: [
                      Text(
                        LocaleKeys.mapTapHint.tr,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: Tokens.space16),
                      if (_reading != null)
                        _WeatherPanel(
                          reading: _reading!,
                          last: _lastReading,
                          onRetry: _picked == null ? null : () => _selectCoordinate(_picked!),
                        )
                      else
                        const SizedBox.shrink(),
                      const SizedBox(height: Tokens.space16),
                      _OverlayChips(
                        radar: _radar,
                        heatmap: _heatmap,
                        wind: _wind,
                        onRadar: (v) => setState(() => _radar = v),
                        onHeatmap: (v) => setState(() => _heatmap = v),
                        onWind: (v) => setState(() => _wind = v),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WeatherPanel extends StatelessWidget {
  const _WeatherPanel({
    required this.reading,
    required this.last,
    required this.onRetry,
  });

  final AsyncValue<WeatherReading> reading;
  final WeatherReading? last;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (reading.isLoading && last != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: Tokens.space8),
          CurrentWeatherCard(
            weather: last!.snapshot.current,
            isStale: last!.isStale,
            providerName: last!.snapshot.providerName,
            fetchedAt: last!.snapshot.fetchedAt,
          ),
        ],
      );
    }

    return reading.when(
      data: (value) => CurrentWeatherCard(
        weather: value.snapshot.current,
        isStale: value.isStale,
        providerName: value.snapshot.providerName,
        fetchedAt: value.snapshot.fetchedAt,
      ),
      error: (_, __) => AppErrorState(
        message: LocaleKeys.mapWeatherError.tr,
        retryLabel: LocaleKeys.weatherRetry.tr,
        onRetry: onRetry,
      ),
      loading: () => const AppSkeletonBox(height: 140, radius: Tokens.cornerRadius),
    );
  }
}

class _OverlayChips extends StatelessWidget {
  const _OverlayChips({
    required this.radar,
    required this.heatmap,
    required this.wind,
    required this.onRadar,
    required this.onHeatmap,
    required this.onWind,
  });

  final bool radar;
  final bool heatmap;
  final bool wind;
  final ValueChanged<bool> onRadar;
  final ValueChanged<bool> onHeatmap;
  final ValueChanged<bool> onWind;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Tokens.space12,
      runSpacing: Tokens.space8,
      children: [
        FilterChip(
          label: Text(LocaleKeys.mapOverlayRadar.tr),
          selected: radar,
          onSelected: onRadar,
        ),
        FilterChip(
          label: Text(LocaleKeys.mapOverlayHeatmap.tr),
          selected: heatmap,
          onSelected: onHeatmap,
        ),
        FilterChip(
          label: Text(LocaleKeys.mapOverlayWind.tr),
          selected: wind,
          onSelected: onWind,
        ),
      ],
    );
  }
}
