import '../../../../core/utils/result.dart';
import '../entities/city.dart';

/// Bundled world-city database for manual location selection.
abstract interface class CityRepository {
  /// Case/diacritic-insensitive prefix-then-substring search, ranked by
  /// city size. Empty query returns the largest cities.
  Future<Result<List<City>>> search(String query, {int limit = 30});
}
