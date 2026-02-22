import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';

class LocationState {
  const LocationState({
    required this.mode,
    required this.coordinate,
    required this.isPermissionDenied,
    required this.isServiceDisabled,
  });

  final LocationMode mode;
  final GeoCoordinate? coordinate;
  final bool isPermissionDenied;
  final bool isServiceDisabled;

  LocationState copyWith({
    LocationMode? mode,
    GeoCoordinate? coordinate,
    bool? isPermissionDenied,
    bool? isServiceDisabled,
  }) {
    return LocationState(
      mode: mode ?? this.mode,
      coordinate: coordinate ?? this.coordinate,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      isServiceDisabled: isServiceDisabled ?? this.isServiceDisabled,
    );
  }
}

