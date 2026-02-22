import 'package:claudy/core/location/geolocator_location_client.dart';
import 'package:claudy/core/location/location_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationClientProvider = Provider<LocationClient>((ref) => GeolocatorLocationClient());

