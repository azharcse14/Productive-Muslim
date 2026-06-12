import '../../../../core/utils/result.dart';
import '../entities/ayah.dart';
import '../entities/surah.dart';

/// Bundled Quran DB (copied from assets to the app dir on first run,
/// opened via drift — guide §5) plus user bookmarks/last-read state.
abstract interface class QuranRepository {
  Future<Result<List<Surah>>> surahs();

  Future<Result<List<Ayah>>> ayahsOf(int surah);

  /// Case/diacritic-insensitive match on transliteration and translated
  /// name; empty query returns all surahs in order.
  Future<Result<List<Surah>>> searchSurahs(String query);

  Future<Result<QuranPosition?>> lastRead();

  Future<Result<void>> setLastRead(QuranPosition position);

  /// Global ayah ids.
  Future<Result<Set<int>>> bookmarkedAyahIds();

  Future<Result<void>> toggleBookmark(int ayahId);
}
