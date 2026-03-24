import 'package:claudy/features/map/data/flutter_map_provider.dart';
import 'package:claudy/features/map/domain/map_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeMapProvider = Provider<MapProvider>((ref) => FlutterMapProvider());

