import 'package:claudy/features/map/data/canvas_map_provider.dart';
import 'package:claudy/features/map/domain/map_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeMapProvider = Provider<MapProvider>((ref) => CanvasMapProvider());

