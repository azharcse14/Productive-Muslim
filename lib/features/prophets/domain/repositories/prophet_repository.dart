import '../../../../core/utils/result.dart';
import '../entities/prophet.dart';

/// Bundled prophets list (JSON asset).
abstract interface class ProphetRepository {
  Future<Result<List<Prophet>>> prophets();

  /// Every person in the prophets' lineage, in display order. The 25
  /// prophets carry their names from [prophets]; the rest have names only.
  Future<Result<List<Prophet>>> lineage();
}
