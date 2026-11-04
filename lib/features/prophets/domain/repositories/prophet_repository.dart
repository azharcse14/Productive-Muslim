import '../../../../core/utils/result.dart';
import '../entities/prophet.dart';

/// Bundled prophets list (JSON asset).
abstract interface class ProphetRepository {
  Future<Result<List<Prophet>>> prophets();
}
