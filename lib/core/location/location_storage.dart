import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationStorage {
  static const keyMode = 'settings.location.mode';
  static const keyManualLat = 'settings.location.manualLat';
  static const keyManualLon = 'settings.location.manualLon';
  static const keyLastLat = 'settings.location.lastLat';
  static const keyLastLon = 'settings.location.lastLon';

  static LocationMode readMode(SharedPreferences prefs) {
    final raw = prefs.getString(keyMode);
    return LocationMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => LocationMode.precise,
    );
  }

  static GeoCoordinate readManual(SharedPreferences prefs) {
    final lat = prefs.getDouble(keyManualLat) ?? 52.370216;
    final lon = prefs.getDouble(keyManualLon) ?? 4.895168;
    return GeoCoordinate(lat: lat, lon: lon);
  }

  static GeoCoordinate? readLastKnown(SharedPreferences prefs) {
    final lat = prefs.getDouble(keyLastLat);
    final lon = prefs.getDouble(keyLastLon);
    if (lat == null || lon == null) return null;
    return GeoCoordinate(lat: lat, lon: lon);
  }

  static Future<void> writeMode(SharedPreferences prefs, LocationMode mode) async {
    await prefs.setString(keyMode, mode.name);
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

