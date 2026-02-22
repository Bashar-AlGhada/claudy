import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/features/map/data/map_provider_selector.dart';
import 'package:claudy/features/map/domain/map_overlay.dart';
import 'package:claudy/features/weather/data/weather_repository_impl.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:claudy/features/weather/ui/widgets/current_weather_card.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(activeMapProvider);

    return Scaffold(
      appBar: AppBar(title: Text(LocaleKeys.navMap.tr)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(LocaleKeys.mapTapHint.tr),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            if (_reading != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _reading!.when(
                  data: (value) => CurrentWeatherCard(
                    weather: value.snapshot.current,
                    isStale: value.isStale,
                    providerName: value.snapshot.providerName,
                    fetchedAt: value.snapshot.fetchedAt,
                  ),
                  error: (_, __) => Text(LocaleKeys.mapWeatherError.tr),
                  loading: () => Text(LocaleKeys.mapWeatherLoading.tr),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(LocaleKeys.mapOverlayRadar.tr),
                    selected: _radar,
                    onSelected: (v) => setState(() => _radar = v),
                  ),
                  FilterChip(
                    label: Text(LocaleKeys.mapOverlayHeatmap.tr),
                    selected: _heatmap,
                    onSelected: (v) => setState(() => _heatmap = v),
                  ),
                  FilterChip(
                    label: Text(LocaleKeys.mapOverlayWind.tr),
                    selected: _wind,
                    onSelected: (v) => setState(() => _wind = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
