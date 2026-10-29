import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_book_remote_data_source.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';

const _section = HadithSection(
  number: 3,
  name: 'Knowledge',
  first: 1,
  last: 2,
  count: 2,
);

HadithBook _book({String kind = 'graded', bool bangla = false}) => HadithBook(
  id: 'tirmidhi',
  en: "Jami' at-Tirmidhi",
  bn: 'জামে তিরমিজি',
  author: 'at-Tirmidhi',
  kind: kind,
  total: 3956,
  editionAr: 'ara-tirmidhi',
  editionEn: 'eng-tirmidhi',
  editionBn: 'ben-tirmidhi',
  sections: const [_section],
  bnFolder: bangla ? 'Tirmidhi' : '',
  bnSections: bangla ? const [_section] : const [],
);

/// A fawazahmed0 `{section}.min.json` body; `null` texts are left out.
String _edition(Map<int, String?> texts, {String grade = ''}) => jsonEncode({
  'metadata': {'name': 'x'},
  'hadiths': [
    for (final MapEntry(:key, :value) in texts.entries)
      if (value != null)
        {
          'hadithnumber': key,
          'text': value,
          'grades': grade.isEmpty
              ? <Object>[]
              : [
                  {'name': 'Al-Albani', 'grade': grade},
                ],
        },
    // Malformed entries are skipped by the parser.
    {'text': 'no number'},
    'not a map',
  ],
});

/// Records every requested URL and serves bodies by edition key; an edition
/// missing from [bodies] throws like an HTTP 404 / offline would.
final class _FakeHttp {
  _FakeHttp(this.bodies);

  final Map<String, String> bodies;
  final requested = <String>[];

  Future<String> call(Uri url) async {
    requested.add(url.toString());
    for (final MapEntry(:key, :value) in bodies.entries) {
      if (url.path.contains('/$key/')) {
        return value;
      }
    }
    throw Exception('404 $url');
  }
}

void main() {
  group('HadithBookRemoteDataSource — fawazahmed0 editions', () {
    test(
      'en: zips Arabic + English, parses grades, skips malformed rows',
      () async {
        final http = _FakeHttp({
          'ara-tirmidhi': _edition({1: 'ar1', 2: 'ar2'}, grade: 'Hasan'),
          'eng-tirmidhi': _edition({1: ' en1 ', 2: 'en2'}),
        });
        final hadith = await HadithBookRemoteDataSource(
          http.call,
        ).fetchSection(_book(), _section, 'en');

        expect(http.requested, [
          'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/ara-tirmidhi/sections/3.min.json',
          'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions/eng-tirmidhi/sections/3.min.json',
        ]);
        expect(hadith.map((h) => h.number), [1, 2]);
        expect(hadith.first.arabic, 'ar1');
        expect(hadith.first.translation, 'en1');
        expect(hadith.first.grade, 'Hasan');
        expect(hadith.first.reference, "Jami' at-Tirmidhi 1");
        expect(hadith.any((h) => h.fallbackTranslation), isFalse);
      },
    );

    test(
      'bn: gaps in the Bengali edition fall back to English, flagged',
      () async {
        final http = _FakeHttp({
          'ara-tirmidhi': _edition({1: 'ar1', 2: 'ar2'}),
          'ben-tirmidhi': _edition({1: 'bn1', 2: null}),
          'eng-tirmidhi': _edition({1: 'en1', 2: 'en2'}),
        });
        final hadith = await HadithBookRemoteDataSource(
          http.call,
        ).fetchSection(_book(), _section, 'bn');

        expect(hadith[0].translation, 'bn1');
        expect(hadith[0].fallbackTranslation, isFalse);
        expect(hadith[1].translation, 'en2');
        expect(hadith[1].fallbackTranslation, isTrue);
      },
    );

    test(
      'bn: a missing Bengali edition falls back wholly to English',
      () async {
        final http = _FakeHttp({
          'ara-tirmidhi': _edition({1: 'ar1'}),
          'eng-tirmidhi': _edition({1: 'en1'}),
        });
        final hadith = await HadithBookRemoteDataSource(
          http.call,
        ).fetchSection(_book(), _section, 'bn');

        expect(hadith.single.translation, 'en1');
        expect(hadith.single.fallbackTranslation, isTrue);
      },
    );

    test('bn: English fallback failing too is an error (offline)', () async {
      final http = _FakeHttp({
        'ara-tirmidhi': _edition({1: 'ar1'}),
      });
      await expectLater(
        HadithBookRemoteDataSource(
          http.call,
        ).fetchSection(_book(), _section, 'bn'),
        throwsException,
      );
    });

    test('a body without a hadiths list parses to no hadith', () async {
      final http = _FakeHttp({
        'ara-tirmidhi': '[1, 2]',
        'eng-tirmidhi': '{"metadata": {}}',
      });
      final hadith = await HadithBookRemoteDataSource(
        http.call,
      ).fetchSection(_book(), _section, 'en');
      expect(hadith, isEmpty);
    });
  });

  group('HadithBookRemoteDataSource — hadithbangla chapters', () {
    test(
      'bn reads the chapter file, unwrapping {"hadith": {...}} entries',
      () async {
        final http = _FakeHttp({
          'Chapter': jsonEncode([
            {
              'hadith_id': 7,
              'ar': ' عربي ',
              'bn': ' বাংলা ',
              'narrator': 'আবূ হুরায়রা',
              'grade': 'সহিহ',
            },
            {
              'hadith': {'hadith_id': 8, 'bn': 'দুই'},
            },
            {'bn': 'no id'},
          ]),
        });
        final ds = HadithBookRemoteDataSource(http.call);
        final hadith = await ds.fetchSection(
          _book(bangla: true),
          _section,
          'bn',
        );

        expect(http.requested, [
          'https://raw.githubusercontent.com/azharcse14/hadithbangla/main/Tirmidhi/Chapter/3.json',
        ]);
        expect(hadith.map((h) => h.number), [7, 8]);
        expect(hadith[0].arabic, 'عربي');
        expect(hadith[0].translation, 'বাংলা');
        expect(hadith[0].narrator, 'আবূ হুরায়রা');
        expect(hadith[0].grade, 'সহিহ');
        expect(hadith[0].reference, 'জামে তিরমিজি 7');
        expect(hadith[1].arabic, '');
        expect(hadith[1].grade, ''); // graded book, no grade given

        // Cached: a second fetch makes no new request.
        await ds.fetchSection(_book(bangla: true), _section, 'bn');
        expect(http.requested, hasLength(1));
      },
    );

    test('a non-list chapter body parses to no hadith', () async {
      final http = _FakeHttp({'Chapter': '{"oops": true}'});
      final hadith = await HadithBookRemoteDataSource(
        http.call,
      ).fetchSection(_book(bangla: true), _section, 'bn');
      expect(hadith, isEmpty);
    });
  });
}
