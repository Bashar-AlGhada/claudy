import 'package:claudy/core/result/app_result.dart';
import 'package:claudy/features/search/domain/models/place.dart';

abstract class PlaceSearchRepository {
  Future<AppResult<List<Place>>> search(String query);
}

