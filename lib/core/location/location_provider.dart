import 'package:claudy/core/i18n/locale_provider.dart';
import 'package:claudy/core/location/location_client.dart';
import 'package:claudy/core/location/location_client_provider.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_state.dart';
import 'package:claudy/core/location/location_storage.dart';
import 'package:claudy/core/location/bigdatacloud_reverse_geocoder.dart';
import 'package:claudy/core/logging/app_logger.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

final locationProvider =
    AsyncNotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);

class LocationNotifier extends AsyncNotifier<LocationState> {
  /// Two fixes within ~2km count as the same spot for place-name caching.
  static const double _placeNameToleranceDeg = 0.02;

  @override
  Future<LocationState> build() async {
    return _resolve(await SharedPreferences.getInstance());
  }

  Future<void> setMode(LocationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await LocationStorage.writeMode(prefs, mode);
    await _applyResolved(prefs);
  }

  Future<void> setManualCoordinate(GeoCoordinate coordinate, {String? name}) async {
    final prefs = await SharedPreferences.getInstance();
    await LocationStorage.writeManual(prefs, coordinate);
    await LocationStorage.writeManualName(prefs, name);
    await LocationStorage.writeLastKnown(prefs, coordinate);
    await _applyResolved(prefs);
  }

  Future<void> requestPermissionAndRefresh() async {
    final permission = await ref.read(locationClientProvider).requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!ref.mounted) return;
      state = AsyncData(
        (state.value ??
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
    await _applyResolved(await SharedPreferences.getInstance());
  }

  Future<LocationState> _resolve(SharedPreferences prefs) async {
    final client = ref.read(locationClientProvider);
    final mode = LocationStorage.readMode(prefs);
    final manual = LocationStorage.readManual(prefs);
    final manualName = LocationStorage.readManualName(prefs);
    final lastKnown = LocationStorage.readLastKnown(prefs);

    if (mode == LocationMode.manual) {
      await LocationStorage.writeLastKnown(prefs, manual);
      return LocationState(
        mode: mode,
        name: manualName,
        coordinate: manual,
        isPermissionDenied: false,
        isServiceDisabled: false,
      );
    }

    if (!await client.isLocationServiceEnabled()) {
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
    GeoCoordinate coordinate;
    String? placeName;
    if (position == null) {
      coordinate = lastKnown ?? manual;
    } else {
      coordinate = GeoCoordinate(lat: position.latitude, lon: position.longitude);
      placeName = await _resolvePlaceName(prefs, coordinate);
    }

    await LocationStorage.writeLastKnown(prefs, coordinate);
    return LocationState(
      mode: mode,
      name: placeName,
      coordinate: coordinate,
      isPermissionDenied: false,
      isServiceDisabled: false,
    );
  }

  /// Resolves a place label for a GPS fix, reusing the cached name while the
  /// fix stays within [_placeNameToleranceDeg] of the one it was resolved for.
  Future<String?> _resolvePlaceName(SharedPreferences prefs, GeoCoordinate coordinate) async {
    final cached = LocationStorage.readLastPlaceName(prefs);
    final cachedLat = prefs.getDouble(LocationStorage.keyLastLat);
    final cachedLon = prefs.getDouble(LocationStorage.keyLastLon);
    final sameSpot = cachedLat != null &&
        cachedLon != null &&
        (cachedLat - coordinate.lat).abs() < _placeNameToleranceDeg &&
        (cachedLon - coordinate.lon).abs() < _placeNameToleranceDeg;
    if (cached != null && sameSpot) return cached;

    final name = await ref
        .read(reverseGeocoderProvider)
        .resolveName(coordinate, languageCode: _storedLanguageCode(prefs));
    if (name != null) {
      await LocationStorage.writeLastPlaceName(prefs, name);
    }
    return name;
  }

  static String _storedLanguageCode(SharedPreferences prefs) {
    final raw = prefs.getString(LocaleNotifier.storageKey);
    final parts = raw?.split('-') ?? const [];
    return parts.isEmpty || parts.first.isEmpty ? 'en' : parts.first;
  }

  Future<void> _applyResolved(SharedPreferences prefs) async {
    try {
      final next = await _resolve(prefs);
      if (!ref.mounted) return;
      state = AsyncData(next);
    } catch (e, s) {
      AppLogger.error('Failed to resolve location state', error: e, stackTrace: s);
    }
  }

  Future<Position?> _safeGetPosition(LocationClient client, LocationMode mode) async {
    try {
      final settings = LocationSettings(
        accuracy: mode == LocationMode.coarse ? LocationAccuracy.low : LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
      return await client.getCurrentPosition(settings: settings);
    } catch (e, s) {
      AppLogger.warn(
        'Position lookup failed; falling back to last known location',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}
