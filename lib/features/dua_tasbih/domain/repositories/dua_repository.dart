import '../../../../core/utils/result.dart';
import '../entities/dua.dart';

/// Bundled dua collection + Asmaul Husna + the Prophet's ﷺ names.
abstract interface class DuaRepository {
  Future<Result<List<DuaCategory>>> categories();

  Future<Result<List<AsmaName>>> asmaulHusna();

  Future<Result<List<AsmaName>>> rasulNames();
}
