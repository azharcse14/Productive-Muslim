import '../../../../core/utils/result.dart';
import '../entities/ruqyah.dart';

/// Bundled ruqyah collection (JSON asset).
abstract interface class RuqyahRepository {
  Future<Result<List<RuqyahCategory>>> categories();
}
