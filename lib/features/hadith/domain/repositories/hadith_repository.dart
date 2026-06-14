import '../../../../core/utils/result.dart';
import '../entities/hadith.dart';

/// Bundled hadith collection (JSON asset).
abstract interface class HadithRepository {
  Future<Result<List<Hadith>>> all();
}
