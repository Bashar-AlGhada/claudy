import 'package:claudy/core/location/location_client.dart';
import 'package:claudy/core/location/location_client_provider.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_provider.dart';
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
}

class _FakeLocationClient implements LocationClient {
  _FakeLocationClient({this.serviceEnabled, this.permission, this.throwOnPosition = false});

  int calls = 0;
  final bool? serviceEnabled;
  final LocationPermission? permission;
  final bool throwOnPosition;

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
    throw UnimplementedError();
  }

  @override
  Future<LocationPermission> requestPermission() async {
    calls++;
    return permission ?? LocationPermission.denied;
  }
}
