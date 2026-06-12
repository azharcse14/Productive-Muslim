import '../../../../core/utils/result.dart';
import '../entities/dua.dart';

/// Bundled dua collection + Asmaul Husna (JSON assets).
abstract interface class DuaRepository {
  Future<Result<List<DuaCategory>>> categories();

  Future<Result<List<AsmaName>>> asmaulHusna();
}
