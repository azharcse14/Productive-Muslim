import '../../../../core/utils/result.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/city_repository.dart';
import '../datasources/city_asset_data_source.dart';

final class CityRepositoryImpl implements CityRepository {
  CityRepositoryImpl(this._source);

  final CityAssetDataSource _source;

  /// Normalized names parallel to [_indexed], built once instead of
  /// re-normalizing every city on each keystroke.
  List<City>? _indexed;
  List<String> _names = const [];

  @override
  Future<Result<List<City>>> search(String query, {int limit = 30}) async {
    try {
      final all = await _source.loadAll();
      if (!identical(all, _indexed)) {
        _names = [
          for (final city in all)
            // Newline can't appear in a query, so it never matches across.
            [city.name, ?city.nameBn].map(_normalize).join('\n'),
        ];
        _indexed = all;
      }
      final q = _normalize(query);
      if (q.isEmpty) {
        return Result.success(all.take(limit).toList());
      }
      // Source is population-ordered, so prefix hits collect biggest first.
      final prefix = <City>[];
      final contains = <City>[];
      for (var i = 0; i < all.length; i++) {
        final city = all[i];
        final name = _names[i];
        if (name.startsWith(q) || name.contains('\n$q')) {
          prefix.add(city);
          if (prefix.length >= limit) {
            break;
          }
        } else if (contains.length < limit && name.contains(q)) {
          contains.add(city);
        }
      }
      return Result.success(
        [...prefix, ...contains].take(limit).toList(),
      );
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('City search failed', e));
    }
  }

  /// Lowercase + strip common Latin diacritics so "Sao" matches "São".
  /// Bengali য়/ড়/ঢ় are typed either precomposed or as base + nukta
  /// depending on keyboard; fold to precomposed and drop ZWJ/ZWNJ.
  static String _normalize(String input) {
    const from = 'àáâãäåāçèéêëēìíîïīñòóôõöōùúûüūýÿšžł’';
    const to = "aaaaaaaceeeeeiiiiinoooooouuuuuyyszl'";
    final lower = input
        .toLowerCase()
        .replaceAll('\u09AF\u09BC', '\u09DF')
        .replaceAll('\u09A1\u09BC', '\u09DC')
        .replaceAll('\u09A2\u09BC', '\u09DD')
        .replaceAll(RegExp('[\u200C\u200D]'), '');
    final buffer = StringBuffer();
    for (final ch in lower.runes) {
      final s = String.fromCharCode(ch);
      final idx = from.indexOf(s);
      buffer.write(idx >= 0 ? to[idx] : s);
    }
    return buffer.toString().trim();
  }
}
