import 'package:claudy/app/app.dart';
import 'package:claudy/core/i18n/i18n_store.dart';
import 'package:claudy/core/i18n/locale_keys.dart';
import 'package:claudy/core/ui/floating_nav_bar.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/daily_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/hourly_weather.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';
import 'package:claudy/features/weather/providers/weather_reading_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    I18nStore.setKeys({
      'en': {
        LocaleKeys.appTitle: 'Claudy',
        LocaleKeys.navWeather: 'Weather',
        LocaleKeys.navMap: 'Map',
        LocaleKeys.navSearch: 'Search',
        LocaleKeys.navSettings: 'Settings',
      },
      'ar': {
        LocaleKeys.appTitle: 'كلودي',
        LocaleKeys.navWeather: 'الطقس',
        LocaleKeys.navMap: 'الخريطة',
        LocaleKeys.navSearch: 'بحث',
        LocaleKeys.navSettings: 'الإعدادات',
      },
    });
    Get.addTranslations(I18nStore.keys);
  });

  testWidgets('Shows bottom navigation labels (EN)', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(480, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'settings.locale': 'en',
      'settings.location.mode': 'manual',
      'settings.location.manualLat': 52.37,
      'settings.location.manualLon': 4.89,
    });

    await tester.pumpWidget(
      App(
        overrides: [
          weatherReadingProvider.overrideWith(_TestWeatherReadingNotifier.new),
        ],
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(FloatingNavBar).evaluate().isNotEmpty) break;
    }

    expect(find.byType(FloatingNavBar), findsOneWidget);
    final navBar = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
    expect(navBar.items.map((item) => item.label).toList(), ['Weather', 'Map', 'Search', 'Settings']);
  });

  testWidgets('Renders RTL direction when locale is AR', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(480, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'settings.locale': 'ar',
      'settings.location.mode': 'manual',
      'settings.location.manualLat': 52.37,
      'settings.location.manualLon': 4.89,
    });

    await tester.pumpWidget(
      App(
        overrides: [
          weatherReadingProvider.overrideWith(_TestWeatherReadingNotifier.new),
        ],
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(FloatingNavBar).evaluate().isEmpty) continue;
      final directions =
          tester.widgetList(find.byType(Directionality)).map((e) => (e as Directionality).textDirection);
      if (directions.contains(TextDirection.rtl)) break;
    }

    expect(find.byType(FloatingNavBar), findsOneWidget);
    final navBar = tester.widget<FloatingNavBar>(find.byType(FloatingNavBar));
    expect(navBar.items.map((item) => item.label).toList(), ['الطقس', 'الخريطة', 'بحث', 'الإعدادات']);

    final directionality = tester.widget<Directionality>(
      find.ancestor(of: find.byType(FloatingNavBar), matching: find.byType(Directionality)).first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets('Uses navigation rail on wide layouts', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'settings.locale': 'en',
      'settings.location.mode': 'manual',
      'settings.location.manualLat': 52.37,
      'settings.location.manualLon': 4.89,
    });

    await tester.pumpWidget(
      App(
        overrides: [
          weatherReadingProvider.overrideWith(_TestWeatherReadingNotifier.new),
        ],
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(NavigationRail).evaluate().isNotEmpty) break;
    }

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(FloatingNavBar), findsNothing);
  });
}

WeatherReading _reading() {
  final now = DateTime(2026, 1, 1, 12);
  return WeatherReading(
    snapshot: WeatherSnapshot(
      coordinate: const GeoCoordinate(lat: 52.37, lon: 4.89),
      providerName: 'Test',
      fetchedAt: now,
      current: CurrentWeather(
        temperatureC: 10,
        feelsLikeC: 9,
        humidityPercent: 50,
        windSpeedMps: 1.2,
        conditionCode: 800,
        observedAt: now,
        uvIndex: 2,
        visibilityKm: 10,
        pressureHpa: 1012,
        windGustMps: 1.8,
        windDegrees: 180,
      ),
      hourly: [
        HourlyWeather(
          time: now,
          temperatureC: 10,
          precipProbabilityPercent: 0,
          conditionCode: 800,
          windSpeedMps: 1.2,
          feelsLikeC: 9,
          uvIndex: 2,
        ),
      ],
      daily: [
        DailyWeather(
          date: DateTime(now.year, now.month, now.day),
          minTemperatureC: 8,
          maxTemperatureC: 12,
          conditionCode: 800,
          uvIndex: 3,
          precipMm: 0,
          precipProbabilityPercent: 0,
          windSpeedMps: 1.5,
        ),
      ],
    ),
    isStale: false,
    source: WeatherDataSource.cache,
  );
}

class _TestWeatherReadingNotifier extends WeatherReadingNotifier {
  @override
  Future<WeatherReading?> build() async => _reading();
}
