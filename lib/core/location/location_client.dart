import 'package:geolocator/geolocator.dart';

abstract class LocationClient {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition({required LocationSettings settings});
}

