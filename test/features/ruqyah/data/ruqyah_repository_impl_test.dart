import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/ruqyah/data/ruqyah_asset_data_source.dart';
import 'package:productive_muslim/features/ruqyah/data/ruqyah_repository_impl.dart';

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

const _ruqyahJson = '''
{
  "categories": [
    {
      "id": "protection",
      "icon": "shield",
      "items": [
        {
          "id": "ayatul_kursi",
          "titleEn": "Ayatul Kursi",
          "titleBn": "আয়াতুল কুরসি",
          "ar": "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ",
          "tr": "Allahu la ilaha illa huwa",
          "en": "Allah — there is no god but He",
          "bn": "আল্লাহ — তিনি ছাড়া কোনো ইলাহ নেই",
          "ref": "Qur'an 2:255",
          "repeat": 3
        },
        {"id": "broken_no_arabic", "tr": "missing arabic"},
        "not even a map"
      ]
    },
    {"id": "broken_category"},
    {
      "id": "healing",
      "icon": "healing",
      "items": [
        {
          "id": "la_basa",
          "ar": "لَا بَأْسَ طَهُورٌ",
          "tr": "La ba'sa tahur",
          "en": "No harm, a purification",
          "bn": "",
          "ref": "Bukhari 5656"
        }
      ]
    }
  ]
}
''';

void main() {
  RuqyahRepositoryImpl makeRepo(_FakeAssetBundle bundle) =>
      RuqyahRepositoryImpl(RuqyahAssetDataSource(bundle));

  _FakeAssetBundle goodBundle() =>
      _FakeAssetBundle({RuqyahAssetDataSource.ruqyahPath: _ruqyahJson});

  group('RuqyahRepositoryImpl.categories', () {
    test('parses categories and items from the asset JSON', () async {
      final result = await makeRepo(goodBundle()).categories();

      final categories = result.valueOrNull;
      expect(categories, isNotNull);
      expect(categories, hasLength(2));

      final protection = categories!.first;
      expect(protection.id, 'protection');
      expect(protection.icon, 'shield');
      expect(protection.items, hasLength(1));

      final kursi = protection.items.first;
      expect(kursi.id, 'ayatul_kursi');
      expect(kursi.titleBn, 'আয়াতুল কুরসি');
      expect(kursi.arabic, 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ');
      expect(kursi.translationBn, isNotEmpty);
      expect(kursi.reference, "Qur'an 2:255");
      expect(kursi.repeat, 3);
    });

    test('defaults repeat to 1 and bn to empty when absent', () async {
      final result = await makeRepo(goodBundle()).categories();

      final healing = result.valueOrNull![1];
      expect(healing.id, 'healing');
      expect(healing.items.single.repeat, 1);
      expect(healing.items.single.translationBn, isEmpty);
    });

    test('titleFor and translationFor fall back to English', () async {
      final result = await makeRepo(goodBundle()).categories();

      final laBasa = result.valueOrNull![1].items.single;
      // No bn title/translation → fall back to en for bn locale.
      expect(laBasa.titleFor('bn'), laBasa.titleEn);
      expect(laBasa.translationFor('bn'), 'No harm, a purification');
    });

    test('skips malformed categories and items without throwing', () async {
      final result = await makeRepo(goodBundle()).categories();

      final categories = result.valueOrNull!;
      expect(categories.map((c) => c.id), isNot(contains('broken_category')));
      expect(
        categories.first.items.map((i) => i.id),
        isNot(contains('broken_no_arabic')),
      );
    });

    test('caches after the first load', () async {
      final bundle = goodBundle();
      final repo = makeRepo(bundle);

      await repo.categories();
      await repo.categories();

      expect(bundle.loadCounts[RuqyahAssetDataSource.ruqyahPath], 1);
    });

    test('missing asset returns a failure result', () async {
      final repo = makeRepo(_FakeAssetBundle(const {}));

      final result = await repo.categories();

      expect(result.isSuccess, isFalse);
      expect(result, isA<FailureResult<Object?>>());
    });
  });
}
