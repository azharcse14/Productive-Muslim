import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/result.dart';
import '../domain/entities/hadith.dart';
import '../domain/repositories/hadith_repository.dart';
import 'hadith_asset_data_source.dart';

final class HadithRepositoryImpl implements HadithRepository {
  const HadithRepositoryImpl(this._source, this._prefs);

  static const _favoritesKey = 'hadith_favorites';

  final HadithAssetDataSource _source;
  final SharedPreferencesAsync _prefs;

  @override
  Future<Result<List<Hadith>>> all() async {
    try {
      return Result.success(await _source.loadAll());
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Hadith load failed', e));
    }
  }

  @override
  Future<Result<Set<String>>> favoriteIds() async {
    try {
      return Result.success(
        (await _prefs.getStringList(_favoritesKey))?.toSet() ?? const {},
      );
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Hadith favorites load', e));
    }
  }

  @override
  Future<Result<void>> setFavoriteIds(Set<String> ids) async {
    try {
      await _prefs.setStringList(_favoritesKey, ids.toList());
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Hadith favorites save', e));
    }
  }
}
