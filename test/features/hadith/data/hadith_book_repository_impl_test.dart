import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/hadith/data/hadith_book_catalog_data_source.dart';
import 'package:qalbee/features/hadith/data/hadith_book_remote_data_source.dart';
import 'package:qalbee/features/hadith/data/hadith_book_repository_impl.dart';

final class _FakeAssetBundle extends AssetBundle {
  _FakeAssetBundle(this.assets);

  final Map<String, String> assets;

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = assets[key];
    if (value == null) {
      throw StateError('Asset not found: $key');
    }
    return value;
  }
}

const _catalogJson = '''
{
  "books": [
    {
      "id": "bukhari",
      "en": "Sahih al-Bukhari",
      "bn": "সহিহ বুখারি",
      "author": "Imam al-Bukhari",
      "kind": "sahih",
      "total": 7563,
      "edition_ar": "ara-bukhari",
      "edition_en": "eng-bukhari",
      "edition_bn": "ben-bukhari",
      "sections": [
        {"n": 1, "name": "Revelation", "first": 1, "last": 7},
        {"n": 2, "name": "Belief", "first": 8, "last": 58}
      ]
    },
    {"id": "broken"},
    {
      "id": "tirmidhi",
      "en": "Jami at-Tirmidhi",
      "bn": "জামে তিরমিজি",
      "author": "Imam at-Tirmidhi",
      "kind": "graded",
      "total": 3956,
      "sections": [{"n": 1, "name": "Purification", "first": 1, "last": 10}]
    },
    {
      "id": "nasai",
      "en": "Sunan an-Nasai",
      "bn": "সুনানে নাসায়ি",
      "author": "Imam an-Nasai",
      "kind": "graded",
      "bn_folder": "Al-Nasai",
      "total": 5758,
      "sections": [{"n": 1, "name": "Purification", "first": 1, "last": 9}],
      "sections_bn": [{"n": 1, "name": "পবিত্রতা", "first": 1, "last": 8}]
    }
  ]
}
''';

/// A hadithbangla per-chapter file (list of raw hadith objects).
const _bnChapter = '''
[
  {"hadith_id": 1, "ar": "عربي-١", "bn": "বাংলা অনুবাদ ১",
   "narrator": "আনাস (রাঃ)", "grade": "সহিহ হাদিস"},
  {"hadith_id": 2, "ar": "عربي-٢", "bn": "বাংলা অনুবাদ ২",
   "narrator": "উমর (রাঃ)", "grade": "হাসান হাদিস"}
]
''';

String _section(String lang, {bool withGrade = false}) => '''
{
  "metadata": {"name": "Revelation"},
  "hadiths": [
    {
      "hadithnumber": 1,
      "text": "$lang-text-1",
      "grades": ${withGrade ? '[{"name":"Al-Albani","grade":"Sahih"},{"name":"Other","grade":"Hasan"}]' : '[]'},
      "reference": {"book": 1, "hadith": 1}
    },
    {
      "hadithnumber": 2,
      "text": "$lang-text-2",
      "grades": [],
      "reference": {"book": 1, "hadith": 2}
    }
  ]
}
''';

void main() {
  HadithBookRepositoryImpl makeRepo(HttpGet get) => HadithBookRepositoryImpl(
        HadithBookCatalogDataSource(
          _FakeAssetBundle(const {
            HadithBookCatalogDataSource.catalogAssetPath: _catalogJson,
          }),
        ),
        HadithBookRemoteDataSource(get),
      );

  group('books (catalog)', () {
    test('parses books and skips malformed entries', () async {
      final result = await makeRepo((_) async => '').books();

      final books = result.valueOrNull;
      expect(books, isNotNull);
      expect(books!.map((b) => b.id), <String>['bukhari', 'tirmidhi', 'nasai']);

      final bukhari = books.first;
      expect(bukhari.isSahih, isTrue);
      expect(bukhari.titleFor('bn'), 'সহিহ বুখারি');
      expect(bukhari.titleFor('en'), 'Sahih al-Bukhari');
      expect(bukhari.sections, hasLength(2));
      expect(bukhari.sections.first.count, 7);
      expect(bukhari.usesBanglaSource('bn'), isFalse); // no bn_folder
      expect(books[1].isSahih, isFalse);
    });

    test('a bn_folder book exposes Bengali chapters + source selection',
        () async {
      final nasai = (await makeRepo((_) async => '').books()).valueOrNull!.last;
      expect(nasai.bnFolder, 'Al-Nasai');
      expect(nasai.usesBanglaSource('bn'), isTrue);
      expect(nasai.usesBanglaSource('en'), isFalse);
      // bn locale shows the Bangla chapter list (own numbering/titles).
      expect(nasai.sectionsFor('bn').first.name, 'পবিত্রতা');
      expect(nasai.sectionsFor('en').first.name, 'Purification');
    });

    test('missing catalog asset yields a failure', () async {
      final repo = HadithBookRepositoryImpl(
        HadithBookCatalogDataSource(_FakeAssetBundle(const {})),
        HadithBookRemoteDataSource((_) async => ''),
      );
      final result = await repo.books();
      expect(result.isSuccess, isFalse);
    });
  });

  group('section (online fetch)', () {
    test('zips Arabic with English translation and keeps numbers', () async {
      final repo = makeRepo((url) async {
        final u = url.toString();
        if (u.contains('ara-bukhari')) return _section('ar');
        return _section('en');
      });
      final book = (await repo.books()).valueOrNull!.first;

      final result = await repo.section(book, book.sections.first, 'en');
      final items = result.valueOrNull!;

      expect(items, hasLength(2));
      expect(items.first.number, 1);
      expect(items.first.arabic, 'ar-text-1');
      expect(items.first.translation, 'en-text-1');
      expect(items.first.reference, 'Sahih al-Bukhari 1');
    });

    test('prefers Al-Albani grade when present', () async {
      final repo = makeRepo((url) async {
        final u = url.toString();
        if (u.contains('ara-')) return _section('ar', withGrade: true);
        return _section('en');
      });
      final book = (await repo.books()).valueOrNull!.last; // tirmidhi (graded)

      final items =
          (await repo.section(book, book.sections.first, 'en')).valueOrNull!;
      expect(items.first.grade, 'Sahih');
    });

    test('falls back to English when Bengali edition lacks a hadith', () async {
      final repo = makeRepo((url) async {
        final u = url.toString();
        if (u.contains('ara-bukhari')) return _section('ar');
        if (u.contains('ben-bukhari')) {
          // Bengali edition returns only hadith #2.
          return '''
{"metadata":{"name":"Revelation"},
 "hadiths":[{"hadithnumber":2,"text":"bn-text-2","grades":[],"reference":{"book":1,"hadith":2}}]}''';
        }
        return _section('en'); // English fallback
      });
      final book = (await repo.books()).valueOrNull!.first;

      final items =
          (await repo.section(book, book.sections.first, 'bn')).valueOrNull!;
      // #1 absent in bn -> English fallback; #2 present in bn.
      expect(items.first.translation, 'en-text-1');
      expect(items[1].translation, 'bn-text-2');
    });

    test('caches each edition URL after the first fetch', () async {
      final calls = <String>[];
      final repo = makeRepo((url) async {
        calls.add(url.toString());
        return url.toString().contains('ara-') ? _section('ar') : _section('en');
      });
      final book = (await repo.books()).valueOrNull!.first;

      await repo.section(book, book.sections.first, 'en');
      await repo.section(book, book.sections.first, 'en');

      // Two editions (ara + eng) fetched once each, despite two section calls.
      expect(calls, hasLength(2));
    });

    test('missing Bengali edition falls back to English, not a failure',
        () async {
      // ben-* 404s (like 40 Hadith Qudsi), ara-* and eng-* succeed.
      final repo = makeRepo((url) async {
        final u = url.toString();
        if (u.contains('ben-')) throw const SocketishError();
        if (u.contains('ara-')) return _section('ar');
        return _section('en');
      });
      final book = (await repo.books()).valueOrNull!.first;

      final result = await repo.section(book, book.sections.first, 'bn');
      final items = result.valueOrNull;
      expect(items, isNotNull, reason: 'should not fail when only bn is missing');
      expect(items!.first.translation, 'en-text-1');
    });

    test('offline (English fallback also fails) is a failure', () async {
      // Arabic loads but every translation edition is unreachable.
      final repo = makeRepo((url) async {
        if (url.toString().contains('ara-')) return _section('ar');
        throw const SocketishError();
      });
      final book = (await repo.books()).valueOrNull!.first;

      final result = await repo.section(book, book.sections.first, 'bn');
      expect(result.isSuccess, isFalse);
    });

    test('a network error becomes a failure result', () async {
      final repo = makeRepo((_) async => throw const SocketishError());
      final book = (await repo.books()).valueOrNull!.first;

      final result = await repo.section(book, book.sections.first, 'en');
      expect(result.isSuccess, isFalse);
      expect(result, isA<FailureResult<Object?>>());
    });

    test('bn on a hadithbangla book reads the Bengali chapter source',
        () async {
      var hitBangla = false;
      final repo = makeRepo((url) async {
        if (url.toString().contains('hadithbangla')) {
          hitBangla = true;
          return _bnChapter;
        }
        // Must NOT touch fawazahmed0 for a hadithbangla book in bn.
        return _section('SHOULD-NOT-BE-USED');
      });
      final nasai = (await repo.books()).valueOrNull!.last;

      final items =
          (await repo.section(nasai, nasai.sectionsFor('bn').first, 'bn'))
              .valueOrNull!;

      expect(hitBangla, isTrue);
      expect(items, hasLength(2));
      expect(items.first.translation, 'বাংলা অনুবাদ ১');
      expect(items.first.narrator, 'আনাস (রাঃ)');
      expect(items.first.grade, 'সহিহ হাদিস');
      expect(items.first.reference, 'সুনানে নাসায়ি 1');
      expect(items.first.fallbackTranslation, isFalse);
      expect(items[1].grade, 'হাসান হাদিস');
    });

    test('en on a hadithbangla book still uses fawazahmed0 (English)',
        () async {
      final repo = makeRepo((url) async {
        if (url.toString().contains('hadithbangla')) {
          throw StateError('should not hit bangla source for en');
        }
        return _section(url.toString().contains('ara-') ? 'ar' : 'en');
      });
      final nasai = (await repo.books()).valueOrNull!.last;

      final items =
          (await repo.section(nasai, nasai.sections.first, 'en')).valueOrNull!;
      expect(items.first.translation, 'en-text-1');
    });
  });
}

/// Stand-in network error (avoids a dart:io import in the test).
final class SocketishError implements Exception {
  const SocketishError();
}
