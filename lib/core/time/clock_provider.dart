import 'dart:async';

import 'package:claudy/core/time/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clockProvider = Provider<Clock>((ref) => SystemClock());

/// Ticks every 30 s so time-dependent UI (e.g. day/night backgrounds)
/// flips without waiting for an unrelated rebuild. autoDispose: the
/// periodic timer must not outlive its last listener.
final wallClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  final clock = ref.watch(clockProvider);
  yield clock.now();
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield clock.now();
  }
});

