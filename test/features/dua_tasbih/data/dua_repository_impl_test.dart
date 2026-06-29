import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/dua_tasbih/data/dua_asset_data_source.dart';
import 'package:productive_muslim/features/dua_tasbih/data/dua_repository_impl.dart';

/// Serves canned strings; counts loads so caching is observable.
final class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this.assets);

  final Map<String, String> assets;
  final Map<String, int> loadCounts = {};

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    loadCounts[key] = (loadCounts[key] ?? 0) + 1;
    final value = assets[key];
    if (value == null) {
      throw StateError('Asset not found: $key');
    }
    return value;
  }
}

const _duasJson = '''
{
  "categories": [
    {
      "id": "morning_evening",
      "icon": "sun",
      "duas": [
        {
          "id": "me_1",
          "ar": "بِسْمِ اللَّهِ",
          "tr": "Bismillah",
          "en": "In the name of Allah",
          "bn": "আল্লাহর নামে",
          "ref": "Muslim 2723",
          "repeat": 3
        },
        {"id": "me_broken", "tr": "missing arabic"},
        "not even a map"
      ]
    },
    {"id": "broken_category"},
    {
      "id": "sleep",
      "icon": "moon",
      "duas": [
        {
          "id": "sl_1",
          "ar": "اللَّهُمَّ",
          "tr": "Allahumma",
          "en": "O Allah",
          "bn": "",
          "ref": "Bukhari 6324",
          "repeat": 1
        }
      ]
    }
  ]
}
''';

const _asmaJson = '''
[
  {"n": 1, "ar": "الرَّحْمَنُ", "tr": "Ar-Rahman",
   "en": "The Most Merciful", "bn": "পরম দয়ালু"},
  {"n": "two", "ar": "broken", "tr": "broken", "en": "broken"},
  {"n": 3, "ar": "الْمَلِكُ", "tr": "Al-Malik", "en": "The King"}
]
''';

void main() {
  DuaRepositoryImpl makeRepo(_FakeAssetBundle bundle) =>
      DuaRepositoryImpl(DuaAssetDataSource(bundle));

  _FakeAssetBundle goodBundle() => _FakeAssetBundle({
        DuaAssetDataSource.duasAssetPath: _duasJson,
        DuaAssetDataSource.asmaAssetPath: _asmaJson,
      });

  group('DuaRepositoryImpl.categories', () {
    test('parses categories and duas from the asset JSON', () async {
      final result = await makeRepo(goodBundle()).categories();

      final categories = result.valueOrNull;
      expect(categories, isNotNull);
      expect(categories, hasLength(2));

      final morning = categories!.first;
      expect(morning.id, 'morning_evening');
      expect(morning.icon, 'sun');
      expect(morning.duas, hasLength(1));
      expect(morning.duas.first.id, 'me_1');
      expect(morning.duas.first.arabic, 'بِسْمِ اللَّهِ');
      expect(morning.duas.first.translationBn, 'আল্লাহর নামে');
      expect(morning.duas.first.reference, 'Muslim 2723');
      expect(morning.duas.first.repeat, 3);

      expect(categories[1].id, 'sleep');
      expect(categories[1].duas.single.repeat, 1);
    });

    test('skips malformed categories and duas without throwing', () async {
      final result = await makeRepo(goodBundle()).categories();

      final categories = result.valueOrNull!;
      expect(categories.map((c) => c.id), isNot(contains('broken_category')));
      expect(
        categories.first.duas.map((d) => d.id),
        isNot(contains('me_broken')),
      );
    });

    test('caches after the first load', () async {
      final bundle = goodBundle();
      final repo = makeRepo(bundle);

      await repo.categories();
      await repo.categories();

      expect(bundle.loadCounts[DuaAssetDataSource.duasAssetPath], 1);
    });

    test('missing asset returns a failure result', () async {
      final repo = makeRepo(_FakeAssetBundle(const {}));

      final result = await repo.categories();

      expect(result.isSuccess, isFalse);
      expect(result, isA<FailureResult<Object?>>());
    });
  });

  group('DuaRepositoryImpl.asmaulHusna', () {
    test('parses names and skips malformed entries', () async {
      final result = await makeRepo(goodBundle()).asmaulHusna();

      final names = result.valueOrNull;
      expect(names, isNotNull);
      expect(names, hasLength(2));
      expect(names!.first.number, 1);
      expect(names.first.transliteration, 'Ar-Rahman');
      expect(names.first.meaningBn, 'পরম দয়ালু');
      expect(names[1].number, 3);
      expect(names[1].meaningBn, isEmpty);
    });

    test('caches after the first load', () async {
      final bundle = goodBundle();
      final repo = makeRepo(bundle);

      await repo.asmaulHusna();
      await repo.asmaulHusna();

      expect(bundle.loadCounts[DuaAssetDataSource.asmaAssetPath], 1);
    });

    test('missing asset returns a failure result', () async {
      final repo = makeRepo(_FakeAssetBundle(const {}));

      final result = await repo.asmaulHusna();

      expect(result.isSuccess, isFalse);
    });
  });
}
