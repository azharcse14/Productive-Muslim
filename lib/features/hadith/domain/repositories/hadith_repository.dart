import '../../../../core/utils/result.dart';
import '../entities/hadith.dart';

/// Bundled hadith collection (JSON asset) plus the user's favorites.
abstract interface class HadithRepository {
  Future<Result<List<Hadith>>> all();

  /// Favorited [Hadith.id]s (kept apart from the bundled data).
  Future<Result<Set<String>>> favoriteIds();

  Future<Result<void>> setFavoriteIds(Set<String> ids);
}
