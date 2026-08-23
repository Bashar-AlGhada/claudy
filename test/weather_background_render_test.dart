import 'dart:async';

import 'package:claudy/core/i18n/i18n_store.dart';
import 'package:claudy/core/time/clock.dart';
import 'package:claudy/core/time/clock_provider.dart';
import 'package:claudy/features/weather/domain/models/current_weather.dart';
import 'package:claudy/features/weather/domain/models/geo_coordinate.dart';
import 'package:claudy/features/weather/domain/models/weather_reading.dart';
import 'package:claudy/features/weather/domain/models/weather_snapshot.dart';
import 'package:claudy/features/weather/providers/weather_reading_provider.dart';
import 'package:claudy/features/weather/ui/background/cloud_animation.dart';
import 'package:claudy/features/weather/ui/background/starry_night_animation.dart';
import 'package:claudy/features/weather/ui/background/sun_animation.dart';
import 'package:claudy/features/weather/ui/background/weather_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  _FixedClock(this.hour);
  final int hour;

  @override
  DateTime now() => DateTime(2026, 1, 10, hour);
}

class _ScenarioReading extends WeatherReadingNotifier {
  _ScenarioReading(this.code, this.isNight);
  final int code;
  final bool isNight;

  @override
  Future<WeatherReading?> build() async => _reading(code, night: isNight);
}

class _NoLocationReading extends WeatherReadingNotifier {
  @override
  Future<WeatherReading?> build() async => null;
}

WeatherReading _reading(int code, {required bool night}) {
  final now = DateTime(2026, 1, 10, night ? 21 : 13);
  return WeatherReading(
    snapshot: WeatherSnapshot(
      coordinate: const GeoCoordinate(lat: 52.37, lon: 4.89),
      providerName: 'Test',
      fetchedAt: now,
      current: CurrentWeather(
        temperatureC: 10,
        feelsLikeC: 9,
        humidityPercent: 50,
        windSpeedMps: 1,
        conditionCode: code,
        observedAt: now,
        uvIndex: 2,
        visibilityKm: 10,
        pressureHpa: 1012,
        windGustMps: 2,
        windDegrees: 180,
        sunrise: DateTime(2026, 1, 10, 8, 30),
        sunset: DateTime(2026, 1, 10, 17),
      ),
      hourly: const [],
      daily: const [],
    ),
    isStale: false,
    source: WeatherDataSource.network,
  );
}

Future<List<CustomPaint>> _painters(WidgetTester tester) {
  return Future.value(
    tester
        .widgetList<CustomPaint>(
          find.byWidgetPredicate((w) => w is CustomPaint && w.painter != null),
        )
        .toList(),
  );
}

Future<void> _pump(
  WidgetTester tester,
  WeatherReadingNotifier Function() notifier, {
  int clockHour = 21,
}) async {
  final fixed = _FixedClock(clockHour);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(fixed),
        // Single emission: no periodic timer to leak past teardown.
        wallClockProvider.overrideWith((ref) => Stream.value(fixed.now())),
        weatherReadingProvider.overrideWith(notifier),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: WeatherBackground(lowPower: false, child: SizedBox()),
        ),
      ),
    ),
  );
  // Animations repeat indefinitely, so settle with fixed pumps only.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  setUpAll(() {
    I18nStore.setKeys({'en': {}});
  });

  testWidgets('clear day renders sun animation and it advances', (tester) async {
    await _pump(tester, () => _ScenarioReading(800, false), clockHour: 13);
    var painters = await _painters(tester);

    expect(find.byType(SunAnimation), findsOneWidget);
    expect(find.byType(CloudAnimation), findsNothing);
    final sunPainters = painters
        .where((p) => p.painter.runtimeType.toString() == '_SunPainter')
        .toList();
    expect(sunPainters, isNotEmpty);
    final first = (sunPainters.first.painter as dynamic).progress as double;

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    painters = await _painters(tester);
    final second = (painters
            .where((p) => p.painter.runtimeType.toString() == '_SunPainter')
            .first
            .painter as dynamic)
        .progress as double;
    expect(second, isNot(first));
  });

  testWidgets('no location falls back to clouds animation', (tester) async {
    await _pump(tester, _NoLocationReading.new);
    final painters = await _painters(tester);

    expect(find.byType(CloudAnimation), findsOneWidget);
    expect(
      painters.where((p) => p.painter.runtimeType.toString() == '_CloudPainter'),
      isNotEmpty,
    );
  });

  testWidgets('clear night renders starry sky with advancing painter', (tester) async {
    await _pump(tester, () => _ScenarioReading(800, true));
    var painters = await _painters(tester);

    expect(find.byType(StarryNightAnimation), findsOneWidget);
    expect(find.byType(SunAnimation), findsNothing);
    final nightPainters = painters
        .where((p) => p.painter.runtimeType.toString() == '_StarryNightPainter')
        .toList();
    expect(nightPainters, isNotEmpty);
    final first = (nightPainters.first.painter as dynamic).progress as double;

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    painters = await _painters(tester);
    final second = (painters
            .where((p) => p.painter.runtimeType.toString() == '_StarryNightPainter')
            .first
            .painter as dynamic)
        .progress as double;
    expect(second, isNot(first));
  });

  testWidgets('selection matrix: night few-clouds composes stars + clouds', (tester) async {
    await _pump(tester, () => _ScenarioReading(801, true));
    await _painters(tester);

    expect(find.byType(StarryNightAnimation), findsOneWidget);
    expect(find.byType(CloudAnimation), findsOneWidget);
    expect(find.byType(SunAnimation), findsNothing);
  });

  testWidgets('selection matrix: day few-clouds renders clouds only', (tester) async {
    await _pump(tester, () => _ScenarioReading(801, false), clockHour: 13);
    await _painters(tester);

    expect(find.byType(CloudAnimation), findsOneWidget);
    expect(find.byType(SunAnimation), findsNothing);
    expect(find.byType(StarryNightAnimation), findsNothing);
  });
}
