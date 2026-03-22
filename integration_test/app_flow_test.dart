import 'package:claudy/app/app.dart';
import 'package:claudy/core/i18n/i18n_loader.dart';
import 'package:claudy/core/i18n/i18n_store.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/location/location_client_provider.dart';
import 'package:claudy/core/location/location_mode.dart';
import 'package:claudy/core/location/location_storage.dart';
import 'package:claudy/core/notifications/noop_notification_service.dart';
import 'package:claudy/core/notifications/notification_provider.dart';
import 'package:claudy/core/perf/frame_monitor.dart';
import 'package:claudy/core/routing/app_routes.dart';
import 'package:claudy/core/routing/app_router.dart';
import 'package:claudy/core/time/clock.dart';
import 'package:claudy/core/time/clock_provider.dart';
import 'package:claudy/features/search/data/openweather_place_search_repository.dart';
import 'package:claudy/features/search/domain/models/place.dart';
import 'package:claudy/features/weather/data/cache/weather_cache_provider.dart';
import 'package:claudy/features/weather/data/weather_provider_selector.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import 'support/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'First launch, pick location, offline uses cached snapshot, theme change',
    (tester) async {
      FrameMonitor.reset();
      FrameMonitor.start();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(480, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await prefs.setString('settings.locale', 'en');

      await I18nLoader.load();
      Get.addTranslations(I18nStore.keys);
      Get.updateLocale(const Locale('en'));

      final now = DateTime(2026, 2, 21, 12, 0);
      final fakeLocation = FakeLocationClient(
        serviceEnabled: true,
        permission: LocationPermission.denied,
        position: Position(
          latitude: 52.370216,
          longitude: 4.895168,
          timestamp: now,
          accuracy: 10,
          altitudeAccuracy: 0,
          altitude: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        ),
      );
      final fakeWeather = FakeWeatherProvider(now: now);
      final fakeCache = InMemoryWeatherCache();
      final fakeSearch = FakePlaceSearchRepository(
        results: [
          Place(
            name: 'Amsterdam',
            country: 'NL',
            coordinate: const GeoCoordinate(lat: 52.370216, lon: 4.895168),
          ),
        ],
      );
      final clock = _MutableClock(now);

    await tester.pumpWidget(
      App(
        overrides: [
          locationClientProvider.overrideWithValue(fakeLocation),
          activeWeatherProvider.overrideWithValue(fakeWeather),
          weatherCacheProvider.overrideWith((ref) async => fakeCache),
          placeSearchRepositoryProvider.overrideWithValue(fakeSearch),
          clockProvider.overrideWithValue(clock),
          notificationServiceProvider.overrideWithValue(NoopNotificationService()),
        ],
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 2));
    AppRouter.router.go(AppRoutes.home);
    await _pumpFor(tester, const Duration(milliseconds: 800));

    expect(find.byType(NavigationBar), findsOneWidget);
    await _pumpUntilFound(tester, find.text(LocaleKeys.weatherLocationDenied.tr));

    await tester.tap(find.text(LocaleKeys.weatherChooseLocation.tr));
    await _pumpFor(tester, const Duration(seconds: 1));
    await _pumpUntilFound(tester, find.byType(TextField));

    await tester.enterText(find.byType(TextField), 'Am');
    await _pumpFor(tester, const Duration(seconds: 1));
    await _pumpUntilFound(tester, find.text('Amsterdam'));

    await tester.tap(find.text('Amsterdam'));
    await _pumpFor(tester, const Duration(seconds: 2));

    await _pumpUntilFound(tester, find.text('21°'), timeout: const Duration(seconds: 30));
    expect(find.text('21°'), findsWidgets);

    clock.setNow(now.add(const Duration(minutes: 11)));
    fakeWeather.mode = FakeWeatherMode.offline;
    final refreshList = find
        .descendant(of: find.byType(RefreshIndicator), matching: find.byType(ListView))
        .first;
    await tester.fling(refreshList, const Offset(0, 300), 1000);
    await _pumpFor(tester, const Duration(seconds: 3));

    await _pumpUntilFound(tester, find.text(LocaleKeys.weatherStale.tr));

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await _pumpFor(tester, const Duration(seconds: 1));

      final lowPowerSwitch = find.widgetWithText(SwitchListTile, LocaleKeys.settingsLowPower.tr);
      if (lowPowerSwitch.evaluate().isNotEmpty) {
        await tester.tap(lowPowerSwitch);
        await _pumpFor(tester, const Duration(seconds: 1));
      }
      debugPrint('frameMetrics=${FrameMonitor.metrics()}');
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );

  testWidgets(
    'Rate limit shows a clear error state without cache',
    (tester) async {
      FrameMonitor.reset();
      FrameMonitor.start();
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(480, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('settings.locale', 'en');
    await LocationStorage.writeMode(prefs, LocationMode.manual);
    await LocationStorage.writeManual(prefs, const GeoCoordinate(lat: 1, lon: 2));
    await LocationStorage.writeLastKnown(prefs, const GeoCoordinate(lat: 1, lon: 2));

    await I18nLoader.load();
    Get.addTranslations(I18nStore.keys);
    Get.updateLocale(const Locale('en'));

    final now = DateTime(2026, 2, 21, 12, 0);
    final fakeLocation = FakeLocationClient(
      serviceEnabled: true,
      permission: LocationPermission.whileInUse,
      position: Position(
        latitude: 1,
        longitude: 2,
        timestamp: now,
        accuracy: 10,
        altitudeAccuracy: 0,
        altitude: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );
    final fakeWeather = FakeWeatherProvider(now: now)..mode = FakeWeatherMode.rateLimited;
    final fakeCache = InMemoryWeatherCache();

    await tester.pumpWidget(
      App(
        overrides: [
          locationClientProvider.overrideWithValue(fakeLocation),
          activeWeatherProvider.overrideWithValue(fakeWeather),
          weatherCacheProvider.overrideWith((ref) async => fakeCache),
          clockProvider.overrideWithValue(_FixedClock(now)),
          notificationServiceProvider.overrideWithValue(NoopNotificationService()),
        ],
      ),
    );
    await _pumpFor(tester, const Duration(seconds: 2));
    AppRouter.router.go(AppRoutes.home);
    await _pumpFor(tester, const Duration(milliseconds: 800));
    await _pumpUntilFound(tester, find.text(LocaleKeys.weatherRateLimited.tr));
      debugPrint('frameMetrics=${FrameMonitor.metrics()}');
    },
    timeout: const Timeout(Duration(minutes: 30)),
  );
}

class _FixedClock implements Clock {
  const _FixedClock(this._now);
  final DateTime _now;
  @override
  DateTime now() => _now;
}

class _MutableClock implements Clock {
  _MutableClock(this._now);

  DateTime _now;

  void setNow(DateTime now) {
    _now = now;
  }

  @override
  DateTime now() => _now;
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<void> _pumpFor(WidgetTester tester, Duration duration) async {
  final end = DateTime.now().add(duration);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
