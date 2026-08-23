import 'dart:async';

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

  static const _autoRequestFlagKey =
      'settings.location.permissionAutoRequested';

  @override
  Future<LocationState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final resolved = await _resolve(prefs);
    _maybeAutoRequestPermission(prefs, resolved);
    return resolved;
  }

  /// First launch only: fire the OS consent prompt automatically so the app
  /// starts at the user's actual position instead of silently falling back
  /// to the default coordinate. Never repeats - afterwards the home-screen
  /// banner owns re-requesting.
  void _maybeAutoRequestPermission(SharedPreferences prefs, LocationState state) {
    if (state.mode == LocationMode.manual) return;
    if (!state.isPermissionDenied) return;
    if (LocationStorage.readLastKnown(prefs) != null) return;
    if (prefs.getBool(_autoRequestFlagKey) ?? false) return;

    unawaited(() async {
      await prefs.setBool(_autoRequestFlagKey, true);
      if (!ref.mounted) return;
      await requestPermissionAndRefresh();
    }());
  }

  Future<void> setMode(LocationMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await LocationStorage.writeMode(prefs, mode);
    // Keep lastKnown in sync so the background worker can refresh the manual
    // spot; done here (an explicit user action) rather than during resolve.
    if (mode == LocationMode.manual) {
      await LocationStorage.writeLastKnown(prefs, LocationStorage.readManual(prefs));
    }
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
      placeName = _cachedPlaceName(prefs, coordinate);
      if (placeName == null) {
        // Never block the first location emission on a geocode round-trip;
        // the name is patched in once it arrives.
        unawaited(_patchPlaceName(prefs, coordinate));
      }
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

  /// Reuses the cached place name while its anchor fix is within
  /// [_placeNameToleranceDeg] (~2 km in latitude; less longitudinally) of
  /// [coordinate]. Anchors live in dedicated keys because lastKnown is also
  /// written for manual picks and would otherwise corrupt the cache.
  String? _cachedPlaceName(SharedPreferences prefs, GeoCoordinate coordinate) {
    final cached = LocationStorage.readLastPlaceName(prefs);
    final anchor = LocationStorage.readLastPlaceNameAnchor(prefs);
    if (cached == null || anchor == null) return null;
    if ((anchor.lat - coordinate.lat).abs() >= _placeNameToleranceDeg ||
        (anchor.lon - coordinate.lon).abs() >= _placeNameToleranceDeg) {
      return null;
    }
    return cached;
  }

  /// Monotonic chain so overlapping patches cannot interleave the three
  /// place-name prefs writes into a name-anchored-at-wrong-spot state.
  Future<void> _placeNameWrites = Future.value();

  Future<void> _patchPlaceName(SharedPreferences prefs, GeoCoordinate coordinate) async {
    final name = await ref
        .read(reverseGeocoderProvider)
        .resolveName(coordinate, languageCode: _storedLanguageCode(prefs));
    if (name == null) return;

    final write = _placeNameWrites.then((_) async {
      try {
        await LocationStorage.writeLastPlaceName(prefs, name, coordinate);
      } catch (e, s) {
        AppLogger.warn('Failed to persist place name', error: e, stackTrace: s);
      }
    });
    _placeNameWrites = write;
    await write;

    // Guard before touching `state`: reading it on a disposed notifier throws.
    if (!ref.mounted) return;
    final current = state.value;
    if (current == null || current.coordinate != coordinate) {
      return;
    }
    state = AsyncData(current.copyWith(name: name));
  }

  static String _storedLanguageCode(SharedPreferences prefs) {
    return LocaleNotifier.tryParse(prefs.getString(LocaleNotifier.storageKey))
            ?.languageCode ??
        'en';
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
