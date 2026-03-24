import 'package:claudy/features/map/domain/map_overlay.dart';
import 'package:claudy/features/map/domain/map_provider.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FlutterMapProvider implements MapProvider {
  @override
  String get name => 'OpenStreetMap';

  @override
  Widget build({
    required Set<MapOverlay> overlays,
    required GeoCoordinate? marker,
    required ValueChanged<GeoCoordinate> onTap,
  }) {
    return _FlutterMapView(overlays: overlays, marker: marker, onTap: onTap);
  }
}

class _FlutterMapView extends StatefulWidget {
  const _FlutterMapView({
    required this.overlays,
    required this.marker,
    required this.onTap,
  });

  final Set<MapOverlay> overlays;
  final GeoCoordinate? marker;
  final ValueChanged<GeoCoordinate> onTap;

  @override
  State<_FlutterMapView> createState() => _FlutterMapViewState();
}

class _FlutterMapViewState extends State<_FlutterMapView> {
  final MapController _mapController = MapController();
  bool _mapReady = false;

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
    final initialCenter = widget.marker != null
        ? LatLng(widget.marker!.lat, widget.marker!.lon)
        : const LatLng(51.5, -0.09); // Default to London

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
        if (widget.overlays.isNotEmpty)
          IgnorePointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.overlays.contains(MapOverlay.radar))
                  const ColoredBox(color: Color(0x334280F4)),
                if (widget.overlays.contains(MapOverlay.heatmap))
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                        colors: [
                          Color(0x33FDD835),
                          Color(0x44FB8C00),
                          Color(0x33E53935),
                        ],
                      ),
                    ),
                  ),
                if (widget.overlays.contains(MapOverlay.wind))
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x2239C4FF), Color(0x1150E3C2)],
                      ),
                    ),
                  ),
              ],
            ),
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
          ],
        ),
      ],
    );
  }
}
