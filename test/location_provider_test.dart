import 'package:claudy/core/location/bigdatacloud_reverse_geocoder.dart';
import 'package:claudy/core/location/location_client.dart';
import 'package:claudy/core/location/location_client_provider.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
import 'package:claudy/core/location/reverse_geocoder.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Manual mode uses stored coordinates and avoids platform calls', () async {
    SharedPreferences.setMockInitialValues({
      'settings.location.mode': 'manual',
      'settings.location.manualLat': 1.23,
      'settings.location.manualLon': 4.56,
    });

    final client = _FakeLocationClient();
    final container = ProviderContainer(overrides: [locationClientProvider.overrideWithValue(client)]);
    addTearDown(container.dispose);

    final state = await container.read(locationProvider.future);
    expect(state.mode, LocationMode.manual);
    expect(state.coordinate?.lat, 1.23);
    expect(state.coordinate?.lon, 4.56);
    expect(state.isPermissionDenied, isFalse);
    expect(state.isServiceDisabled, isFalse);
    expect(client.calls, 0);
  });

  test('Permission denied falls back to manual coordinate', () async {
    SharedPreferences.setMockInitialValues({
      'settings.location.mode': 'precise',
      'settings.location.manualLat': 10.0,
      'settings.location.manualLon': 20.0,
    });

    final client = _FakeLocationClient(serviceEnabled: true, permission: LocationPermission.denied);
    final container = ProviderContainer(overrides: [locationClientProvider.overrideWithValue(client)]);
    addTearDown(container.dispose);

    final state = await container.read(locationProvider.future);
    expect(state.mode, LocationMode.precise);
    expect(state.isPermissionDenied, isTrue);
    expect(state.coordinate?.lat, 10.0);
    expect(state.coordinate?.lon, 20.0);
  });

  test('Coarse mode requests low accuracy', () async {
    SharedPreferences.setMockInitialValues({
      'settings.location.mode': 'coarse',
      'settings.location.manualLat': 10.0,
      'settings.location.manualLon': 20.0,
    });

    final client = _FakeLocationClient(serviceEnabled: true, permission: LocationPermission.whileInUse, throwOnPosition: true);
    final container = ProviderContainer(overrides: [locationClientProvider.overrideWithValue(client)]);
    addTearDown(container.dispose);

    final state = await container.read(locationProvider.future);
    expect(state.mode, LocationMode.coarse);
    expect(client.lastSettings?.accuracy, LocationAccuracy.low);
  });

  test('Successful GPS fix resolves and persists a place name', () async {
    SharedPreferences.setMockInitialValues({
      'settings.location.mode': 'precise',
      'settings.location.manualLat': 10.0,
      'settings.location.manualLon': 20.0,
    });

    final client = _FakeLocationClient(
      serviceEnabled: true,
      permission: LocationPermission.whileInUse,
      position: _position(52.3725, 4.8930),
    );
    final geocoder = _FakeReverseGeocoder(name: 'Amsterdam, Netherlands');
    final container = ProviderContainer(overrides: [
      locationClientProvider.overrideWithValue(client),
      reverseGeocoderProvider.overrideWithValue(geocoder),
    ]);
    addTearDown(container.dispose);

    final state = await container.read(locationProvider.future);
    expect(state.coordinate?.lat, 52.3725);

    // The place name is patched in asynchronously after the first GPS fix;
    // let the geocode round-trip (fake, immediate) complete.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(locationProvider).value?.name, 'Amsterdam, Netherlands');
    expect(geocoder.calls, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('settings.location.lastKnownPlaceName'), 'Amsterdam, Netherlands');
    expect(prefs.getDouble('settings.location.lastKnownPlaceName.lat'), closeTo(52.3725, 1e-9));
    expect(prefs.getDouble('settings.location.lastKnownPlaceName.lon'), closeTo(4.8930, 1e-9));

    // Same spot again: cached name synchronously, no extra network call.
    final second = await container.refresh(locationProvider.future);
    expect(second.name, 'Amsterdam, Netherlands');
    expect(geocoder.calls, 1);
  });
}

Position _position(double lat, double lon) {
  return Position(
    latitude: lat,
    longitude: lon,
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    altitude: 0,
    altitudeAccuracy: 0,
    accuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class _FakeReverseGeocoder implements ReverseGeocoder {
  _FakeReverseGeocoder({this.name});

  int calls = 0;
  final String? name;

  @override
  Future<String?> resolveName(GeoCoordinate coordinate, {String? languageCode}) async {
    calls++;
    return name;
  }
}

class _FakeLocationClient implements LocationClient {
  _FakeLocationClient({
    this.serviceEnabled,
    this.permission,
    this.throwOnPosition = false,
    this.position,
  });

  int calls = 0;
  final bool? serviceEnabled;
  final LocationPermission? permission;
  final bool throwOnPosition;
  final Position? position;

  LocationSettings? lastSettings;

  @override
  Future<bool> isLocationServiceEnabled() async {
    calls++;
    return serviceEnabled ?? false;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    calls++;
    return permission ?? LocationPermission.denied;
  }

  @override
  Future<Position> getCurrentPosition({required LocationSettings settings}) async {
    calls++;
    lastSettings = settings;
    if (throwOnPosition) throw Exception('no position');
    final position = this.position;
    if (position == null) throw UnimplementedError();
    return position;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    calls++;
    return permission ?? LocationPermission.denied;
  }
}
