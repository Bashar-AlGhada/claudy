import 'package:claudy/core/location/location_client.dart';
import 'package:claudy/core/location/location_client_provider.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_state.dart';
import 'package:claudy/core/location/location_storage.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

final locationProvider =
    AsyncNotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);

class LocationNotifier extends AsyncNotifier<LocationState> {
  @override
  Future<LocationState> build() async {
    final client = ref.read(locationClientProvider);
    final prefs = await SharedPreferences.getInstance();
    final mode = LocationStorage.readMode(prefs);
    final manual = LocationStorage.readManual(prefs);
    final lastKnown = LocationStorage.readLastKnown(prefs);

    if (mode == LocationMode.manual) {
      await LocationStorage.writeLastKnown(prefs, manual);
      return LocationState(
        mode: mode,
        coordinate: manual,
        isPermissionDenied: false,
        isServiceDisabled: false,
      );
    }

    final serviceEnabled = await client.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationState(
        mode: mode,
        coordinate: lastKnown ?? manual,
        isPermissionDenied: false,
        isServiceDisabled: true,
      );
    }

    final permission = await client.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return LocationState(
        mode: mode,
        coordinate: lastKnown ?? manual,
        isPermissionDenied: true,
        isServiceDisabled: false,
      );
    }

    final position = await _safeGetPosition(client, mode);
    final coordinate = position == null
        ? (lastKnown ?? manual)
        : GeoCoordinate(lat: position.latitude, lon: position.longitude);

    await LocationStorage.writeLastKnown(prefs, coordinate);
    return LocationState(
      mode: mode,
      coordinate: coordinate,
      isPermissionDenied: false,
      isServiceDisabled: false,
    );
  }

  Future<void> setMode(LocationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await LocationStorage.writeMode(prefs, mode);
    state = AsyncData(await build());
  }

  Future<void> setManualCoordinate(GeoCoordinate coordinate) async {
    final prefs = await SharedPreferences.getInstance();
    await LocationStorage.writeManual(prefs, coordinate);
    await LocationStorage.writeLastKnown(prefs, coordinate);
    state = AsyncData(await build());
  }

  Future<void> requestPermissionAndRefresh() async {
    final client = ref.read(locationClientProvider);
    final permission = await client.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      state = AsyncData(
        (state.valueOrNull ??
                const LocationState(
                  mode: LocationMode.manual,
                  coordinate: null,
                  isPermissionDenied: true,
                  isServiceDisabled: false,
                ))
            .copyWith(isPermissionDenied: true),
      );
      return;
    }
    state = AsyncData(await build());
  }

  Future<Position?> _safeGetPosition(LocationClient client, LocationMode mode) async {
    try {
      return await client.getCurrentPosition(
        desiredAccuracy: mode == LocationMode.coarse
            ? LocationAccuracy.low
            : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      return null;
    }
  }
}
