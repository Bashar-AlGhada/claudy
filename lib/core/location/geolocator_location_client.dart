import 'package:claudy/core/location/location_client.dart';
import 'package:geolocator/geolocator.dart';

class GeolocatorLocationClient implements LocationClient {
  @override
  Future<bool> isLocationServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition({required LocationSettings settings}) {
    return Geolocator.getCurrentPosition(locationSettings: settings);
  }
}
