import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';

class LocationState {
  const LocationState({
    required this.mode,
    required this.coordinate,
    required this.isPermissionDenied,
    required this.isServiceDisabled,
    this.name,
  });

  final LocationMode mode;

  /// Human-readable place label; from search picks in manual mode, or
  /// reverse-geocoded for GPS fixes (may be absent while resolving).
  final String? name;
  final GeoCoordinate? coordinate;
  final bool isPermissionDenied;
  final bool isServiceDisabled;

  LocationState copyWith({
    LocationMode? mode,
    String? name,
    GeoCoordinate? coordinate,
    bool? isPermissionDenied,
    bool? isServiceDisabled,
  }) {
    return LocationState(
      mode: mode ?? this.mode,
      name: name ?? this.name,
      coordinate: coordinate ?? this.coordinate,
      isPermissionDenied: isPermissionDenied ?? this.isPermissionDenied,
      isServiceDisabled: isServiceDisabled ?? this.isServiceDisabled,
    );
  }
}
