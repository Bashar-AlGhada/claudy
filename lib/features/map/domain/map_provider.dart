import 'package:claudy/features/map/domain/map_overlay.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:flutter/widgets.dart';

abstract class MapProvider {
  String get name;

  Widget build({
    required Set<MapOverlay> overlays,
    required GeoCoordinate? marker,
    required ValueChanged<GeoCoordinate> onTap,
  });
}

