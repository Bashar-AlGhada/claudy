import 'package:claudy/core/config/api_key_store.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/features/map/data/rainviewer_service.dart';
import 'package:claudy/features/map/domain/map_overlay.dart';
import 'package:claudy/features/map/domain/map_provider.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapProvider implements MapProvider {
  @override
  String get name => 'OpenStreetMap';

  @override
  Widget build({
    required Set<MapOverlay> overlays,
    required GeoCoordinate? marker,
    GeoCoordinate? userLocation,
    required ValueChanged<GeoCoordinate> onTap,
  }) {
    return _FlutterMapView(
      overlays: overlays,
      marker: marker,
      userLocation: userLocation,
      onTap: onTap,
    );
  }
}

class _FlutterMapView extends ConsumerStatefulWidget {
  const _FlutterMapView({
    required this.overlays,
    required this.marker,
    required this.userLocation,
    required this.onTap,
  });

  final Set<MapOverlay> overlays;
  final GeoCoordinate? marker;
  final GeoCoordinate? userLocation;
  final ValueChanged<GeoCoordinate> onTap;

  @override
  ConsumerState<_FlutterMapView> createState() => _FlutterMapViewState();
}

class _FlutterMapViewState extends ConsumerState<_FlutterMapView> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

  /// Messages already shown; one per key per session.
  final Set<String> _warnedKeys = {};

  @override
  void didUpdateWidget(covariant _FlutterMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.marker;
    final current = widget.marker;
    if (current == null) return;
    final markerChanged =
        previous?.lat != current.lat || previous?.lon != current.lon;
    if (markerChanged) {
      _moveToMarker(current);
    }
  }

  void _moveToMarker(GeoCoordinate marker) {
    if (!_mapReady) return;
    _mapController.move(
      LatLng(marker.lat, marker.lon),
      _mapController.camera.zoom.clamp(6, 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Reactive: saving a key in Settings re-renders overlays immediately.
    final apiKey = ref.watch(openWeatherApiKeyProvider).asData?.value ?? '';
    final wantsKeyedOverlay = widget.overlays.contains(MapOverlay.heatmap) ||
        widget.overlays.contains(MapOverlay.wind);
    if (wantsKeyedOverlay && apiKey.isEmpty) {
      _warnOnce('needs-key', LocaleKeys.mapOverlayNeedsKey.tr);
    }

    // Start where the user is; only fall back when nothing is known yet.
    final initialCenter = (widget.userLocation ?? widget.marker) != null
        ? LatLng(
            (widget.userLocation ?? widget.marker)!.lat,
            (widget.userLocation ?? widget.marker)!.lon,
          )
        : const LatLng(52.370216, 4.895168);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 10,
        onMapReady: () {
          _mapReady = true;
          final marker = widget.marker;
          if (marker != null) {
            _moveToMarker(marker);
          }
        },
        onTap: (tapPosition, point) {
          widget.onTap(
            GeoCoordinate(lat: point.latitude, lon: point.longitude),
          );
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.claudy.app',
        ),
        ..._overlayTileLayers(apiKey),
        if (widget.userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  widget.userLocation!.lat,
                  widget.userLocation!.lon,
                ),
                width: 28,
                height: 28,
                child: const Icon(
                  Icons.my_location,
                  color: Color(0xFF2979FF),
                  size: 26,
                ),
              ),
            ],
          ),
        if (widget.marker != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(widget.marker!.lat, widget.marker!.lon),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors', onTap: () {}),
            if (widget.overlays.contains(MapOverlay.radar))
              const TextSourceAttribution('Radar: RainViewer'),
          ],
        ),
      ],
    );
  }

  /// Real weather tile layers. Radar comes from RainViewer's free API;
  /// heat/wind come from OpenWeatherMap tiles and require an API key.
  List<Widget> _overlayTileLayers(String apiKey) {
    final layers = <Widget>[];

    if (widget.overlays.contains(MapOverlay.radar)) {
      layers.add(
        FutureBuilder<String?>(
          future: ref.read(rainViewerProvider).latestRadarFrameUrl(),
          builder: (context, snapshot) {
            final url = snapshot.data;
            if (url == null) return const SizedBox.shrink();
            // flutter_map 7 exposes no TileLayer opacity; wrap instead.
            return Opacity(
              opacity: 0.65,
              child: TileLayer(
                urlTemplate: url,
                userAgentPackageName: 'com.claudy.app',
              ),
            );
          },
        ),
      );
    }

    if (apiKey.isEmpty) {
      return layers;
    }

    if (widget.overlays.contains(MapOverlay.heatmap)) {
      layers.add(_gatedOwmLayer('temp_new', apiKey));
    }
    if (widget.overlays.contains(MapOverlay.wind)) {
      layers.add(_gatedOwmLayer('wind_new', apiKey));
    }
    return layers;
  }

  /// Shows [message] at most once per key per session.
  void _warnOnce(String key, String message) {
    if (!_warnedKeys.add(key)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
      );
    });
  }

  /// Renders an OWM layer only after probing confirms the key may use it AND
  /// discovers the plan's native zoom cap; beyond the cap flutter_map upscales
  /// tiles instead of requesting rejected zooms, which is what used to paint
  /// "zoom level not supported" placeholders over the map.
  Widget _gatedOwmLayer(String layer, String apiKey) {
    return FutureBuilder<(bool, int?)>(
      future: () async {
        final service = ref.read(rainViewerProvider);
        final available = await service.owmLayerAvailable(layer, apiKey);
        if (!available) return (false, null);
        final maxNative = await service.discoverOwmMaxNativeZoom(layer, apiKey);
        return (maxNative != null, maxNative);
      }(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || !data.$1 || data.$2 == null) {
          final failed = snapshot.connectionState == ConnectionState.done;
          if (failed && data != null && !data.$1) {
            _warnOnce(layer, LocaleKeys.mapOverlayUnavailable.tr);
          }
          return const SizedBox.shrink();
        }
        return _owmTileLayer(layer, apiKey, data.$2!);
      },
    );
  }

  Widget _owmTileLayer(String layer, String apiKey, int maxNativeZoom) {
    return Opacity(
      opacity: 0.6,
      child: TileLayer(
        urlTemplate:
            'https://tile.openweathermap.org/map/$layer/{z}/{x}/{y}.png?appid=$apiKey',
        userAgentPackageName: 'com.claudy.app',
        maxNativeZoom: maxNativeZoom,
      ),
    );
  }
}
