import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationStorage {
  static const keyMode = 'settings.location.mode';
  static const keyManualName = 'settings.location.manualName';
  static const keyManualLat = 'settings.location.manualLat';
  static const keyManualLon = 'settings.location.manualLon';
  static const keyLastLat = 'settings.location.lastLat';
  static const keyLastLon = 'settings.location.lastLon';
  static const keyLastPlaceName = 'settings.location.lastKnownPlaceName';
  static const keyLastPlaceNameLat = 'settings.location.lastKnownPlaceName.lat';
  static const keyLastPlaceNameLon = 'settings.location.lastKnownPlaceName.lon';

  /// Fallback for first runs before the user has picked or fixed a position.
  static const defaultCoordinate = GeoCoordinate(lat: 52.370216, lon: 4.895168);

  static LocationMode readMode(SharedPreferences prefs) {
    final raw = prefs.getString(keyMode);
    return LocationMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => LocationMode.precise,
    );
  }

  static String? readManualName(SharedPreferences prefs) {
    return prefs.getString(keyManualName);
  }

  static GeoCoordinate readManual(SharedPreferences prefs) {
    final lat = prefs.getDouble(keyManualLat);
    final lon = prefs.getDouble(keyManualLon);
    if (lat == null || lon == null) return defaultCoordinate;
    return GeoCoordinate(lat: lat, lon: lon);
  }

  static GeoCoordinate? readLastKnown(SharedPreferences prefs) {
    final lat = prefs.getDouble(keyLastLat);
    final lon = prefs.getDouble(keyLastLon);
    if (lat == null || lon == null) return null;
    return GeoCoordinate(lat: lat, lon: lon);
  }

  static String? readLastPlaceName(SharedPreferences prefs) {
    return prefs.getString(keyLastPlaceName);
  }

  static GeoCoordinate? readLastPlaceNameAnchor(SharedPreferences prefs) {
    final lat = prefs.getDouble(keyLastPlaceNameLat);
    final lon = prefs.getDouble(keyLastPlaceNameLon);
    if (lat == null || lon == null) return null;
    return GeoCoordinate(lat: lat, lon: lon);
  }

  /// Persists the resolved name together with the coordinate it was resolved
  /// for, so later reads can verify proximity before reusing it.
  static Future<void> writeLastPlaceName(
    SharedPreferences prefs,
    String name,
    GeoCoordinate anchor,
  ) async {
    await prefs.setString(keyLastPlaceName, name);
    await prefs.setDouble(keyLastPlaceNameLat, anchor.lat);
    await prefs.setDouble(keyLastPlaceNameLon, anchor.lon);
  }

  static Future<void> writeMode(SharedPreferences prefs, LocationMode mode) async {
    await prefs.setString(keyMode, mode.name);
  }

  static Future<void> writeManualName(SharedPreferences prefs, String? name) async {
    if (name == null || name.isEmpty) {
      await prefs.remove(keyManualName);
    } else {
      await prefs.setString(keyManualName, name);
    }
  }

  static Future<void> writeManual(SharedPreferences prefs, GeoCoordinate coordinate) async {
    await prefs.setDouble(keyManualLat, coordinate.lat);
    await prefs.setDouble(keyManualLon, coordinate.lon);
  }

  static Future<void> writeLastKnown(
    SharedPreferences prefs,
    GeoCoordinate coordinate,
  ) async {
    await prefs.setDouble(keyLastLat, coordinate.lat);
    await prefs.setDouble(keyLastLon, coordinate.lon);
  }
}

