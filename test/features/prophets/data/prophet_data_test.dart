import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/prophets/data/prophet_repository_impl.dart';
import 'package:productive_muslim/features/prophets/domain/entities/lineage.dart';

void main() {
  group('ProphetRepositoryImpl.parse', () {
    test('reads every field and drops malformed entries', () {
      final prophets = ProphetRepositoryImpl.parse(
        jsonEncode([
          {
            'id': 'ibrahim',
            'order': 6,
            'nameAr': 'إبراهيم',
            'nameEn': 'Ibrahim',
            'nameBn': 'ইবরাহিম',
            'titleEn': 'Khalilullah',
            'parent': null,
            'summaryEn': ['One.', 2],
            'quranMentions': ['14:35-41'],
            'hadithRefs': ['Bukhari 3364'],
            'storyIds': ['ibrahim_in_the_fire'],
          },
          {
            'id': 'ismail',
            'order': 8,
            'nameAr': 'إسماعيل',
            'nameEn': 'Ismail',
            'nameBn': 'ইসমাইল',
            'parent': 'ibrahim',
            'parentDistant': true,
          },
          {'id': 'no_names', 'order': 9},
          {'id': 'bad_order', 'order': '10', 'nameAr': '', 'nameEn': ''},
          'not a map',
        ]),
      );
      expect(prophets.map((p) => p.id), ['ibrahim', 'ismail']);
      final ibrahim = prophets.first;
      expect(ibrahim.titleFor('bn'), 'Khalilullah'); // falls back to English
      expect(ibrahim.parent, isNull);
      expect(ibrahim.summaryEn, ['One.']); // non-strings skipped
      expect(ibrahim.summaryFor('bn'), ['One.']);
      expect(ibrahim.quranMentions, ['14:35-41']);
      expect(ibrahim.hadithRefs, ['Bukhari 3364']);
      expect(ibrahim.storyIds, ['ibrahim_in_the_fire']);
      expect(prophets.last.parent, 'ibrahim');
      expect(prophets.last.parentDistant, isTrue);
      expect(prophets.last.nameFor('bn'), 'ইসমাইল');
    });

    test('a non-list document parses to nothing', () {
      expect(ProphetRepositoryImpl.parse('{}'), isEmpty);
    });
  });

  group('bundled prophets.json', () {
    final raw = File(ProphetRepositoryImpl.path).readAsStringSync();
    final prophets = ProphetRepositoryImpl.parse(raw);

    test('every entry parses: 25 prophets, orders 1..25, unique ids', () {
      expect((jsonDecode(raw) as List).length, 25);
      expect(prophets, hasLength(25));
      expect(prophets.map((p) => p.order).toList()..sort(), [
        for (var i = 1; i <= 25; i++) i,
      ]);
      expect(prophets.map((p) => p.id).toSet(), hasLength(25));
      final sorted = [...prophets]..sort((a, b) => a.order.compareTo(b.order));
      expect(sorted.first.id, 'adam');
      expect(sorted.last.id, 'muhammad');
    });

    test('names are filled in all three languages', () {
      for (final p in prophets) {
        expect(p.nameAr, isNotEmpty, reason: p.id);
        expect(p.nameEn, isNotEmpty, reason: p.id);
        expect(p.nameBn, isNotEmpty, reason: p.id);
      }
    });

    test('summaries are filled in both languages', () {
      for (final p in prophets) {
        for (final summary in [p.summaryEn, p.summaryBn]) {
          expect(summary, isNotEmpty, reason: p.id);
          for (final paragraph in summary) {
            expect(paragraph.trim(), isNotEmpty, reason: p.id);
          }
        }
      }
    });

    test('every parent resolves to an earlier prophet', () {
      final orderOf = {for (final p in prophets) p.id: p.order};
      for (final p in prophets) {
        if (p.parent case final parent?) {
          expect(orderOf[parent], isNotNull, reason: p.id);
          expect(orderOf[parent]!, lessThan(p.order), reason: p.id);
        }
      }
    });

    test('Quran mentions are surah:ayah or surah:ayah-ayah', () {
      final pattern = RegExp(r'^\d+:\d+(-\d+)?$');
      for (final p in prophets) {
        expect(p.quranMentions, isNotEmpty, reason: p.id);
        for (final m in p.quranMentions) {
          expect(pattern.hasMatch(m), isTrue, reason: '${p.id}: $m');
        }
      }
    });

    test('storyIds point at bundled Quran stories', () {
      final storyIds = {
        for (final s
            in jsonDecode(
                  File('assets/data/quran_stories.json').readAsStringSync(),
                )
                as List)
          (s as Map)['id'],
      };
      for (final p in prophets) {
        for (final id in p.storyIds) {
          expect(storyIds, contains(id), reason: p.id);
        }
      }
    });

    test('only Adam is a root; links follow the Salasilah chart', () {
      final byId = {for (final p in prophets) p.id: p};
      expect(prophets.where((p) => p.parent == null).map((p) => p.id), [
        'adam',
      ]);
      // Direct (solid) links: father → son.
      for (final (child, parent) in [
        ('ismail', 'ibrahim'),
        ('ishaq', 'ibrahim'),
        ('yaqub', 'ishaq'),
        ('yusuf', 'yaqub'),
        ('dhulkifl', 'ayyub'),
        ('sulaiman', 'dawud'),
        ('yahya', 'zakariya'),
      ]) {
        expect(byId[child]!.parent, parent, reason: child);
        expect(byId[child]!.parentDistant, isFalse, reason: child);
      }
      expect(byId['lut']!.parent, 'nuh', reason: 'nephew, not son, of Ibrahim');
      expect(byId['muhammad']!.parent, 'ismail');
      expect(byId['muhammad']!.parentDistant, isTrue);
    });

    test('the real tree stays narrow enough for a phone', () {
      final lanes = layoutLineage(prophets).fold(
        1,
        (n, r) => [
          n,
          r.column + 1,
          ...r.outgoing.keys.map((c) => c + 1),
        ].reduce((a, b) => a > b ? a : b),
      );
      expect(lanes, lessThanOrEqualTo(8));
    });

    test('the real tree puts no dot on a passing line', () {
      for (final row in layoutLineage(prophets)) {
        expect(
          row.through.keys,
          isNot(contains(row.column)),
          reason: row.prophet.id,
        );
      }
    });
  });
}
