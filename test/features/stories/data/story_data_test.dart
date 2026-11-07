import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/stories/data/story_asset_data_source.dart';
import 'package:productive_muslim/features/stories/data/story_repository_impl.dart';
import 'package:productive_muslim/features/stories/domain/entities/story.dart';

final class _Bundle extends AssetBundle {
  _Bundle(this.assets);

  final Map<String, String> assets;
  int loads = 0;

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    loads++;
    return assets[key] ?? (throw StateError('Asset not found: $key'));
  }
}

const _json = '''
[
  {"id": "yusuf", "titleEn": "Yusuf", "titleBn": "ইউসুফ",
   "bodyEn": ["One.", "Two."], "bodyBn": ["এক।"], "refs": ["Quran 12:4-101"]},
  {"id": "no_body", "titleEn": "Broken", "bodyEn": []},
  "not a map"
]
''';

void main() {
  group('StoryAssetDataSource.parse', () {
    test('keeps valid stories, skips malformed ones', () {
      final stories = StoryAssetDataSource.parse(_json);
      expect(stories.map((s) => s.id), ['yusuf']);
      final yusuf = stories.single;
      expect(yusuf.titleFor('bn'), 'ইউসুফ');
      expect(yusuf.titleFor('en'), 'Yusuf');
      expect(yusuf.bodyFor('en'), ['One.', 'Two.']);
      expect(yusuf.bodyFor('bn'), ['এক।']);
      expect(yusuf.refs, ['Quran 12:4-101']);
    });

    test('a non-array root parses to nothing', () {
      expect(StoryAssetDataSource.parse('{}'), isEmpty);
    });
  });

  group('StoryRepositoryImpl', () {
    test('loads per kind from its own asset, cached', () async {
      final bundle = _Bundle({
        StoryAssetDataSource.pathFor(StoryKind.quran): _json,
      });
      final repo = StoryRepositoryImpl(StoryAssetDataSource(bundle));
      expect(
        StoryAssetDataSource.pathFor(StoryKind.hadith),
        'assets/data/hadith_stories.json',
      );
      final first = await repo.stories(StoryKind.quran);
      await repo.stories(StoryKind.quran);
      expect(first.valueOrNull?.single.id, 'yusuf');
      expect(bundle.loads, 1);
      expect(
        await repo.stories(StoryKind.hadith),
        isA<FailureResult<List<Story>>>(),
      );
    });
  });

  // The real bundled files: every story is complete in both languages and
  // carries well-formed refs.
  final refFormats = {
    StoryKind.quran: RegExp(r'^Quran \d+:\d+(-\d+)?$'),
    StoryKind.hadith: RegExp(
      r'^(Bukhari|Muslim|Abu Dawud|Tirmidhi|Nasai|Ibn Majah|Muwatta Malik) '
      r'\d+(-\d+)?$',
    ),
  };
  for (final kind in StoryKind.values) {
    final file = File(StoryAssetDataSource.pathFor(kind));
    test('${file.path} is complete and well-referenced', () {
      final raw = file.readAsStringSync();
      final entries = (jsonDecode(raw) as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(entries, isNotEmpty);
      // Nothing is silently dropped by the parser.
      expect(StoryAssetDataSource.parse(raw), hasLength(entries.length));
      final ids = <String>{};
      for (final e in entries) {
        final id = e['id'] as String;
        expect(ids.add(id), isTrue, reason: 'duplicate id $id');
        for (final key in ['titleEn', 'titleBn']) {
          expect(
            e[key],
            isA<String>().having((s) => s.trim(), key, isNotEmpty),
            reason: '$id.$key',
          );
        }
        for (final key in ['bodyEn', 'bodyBn', 'refs']) {
          final list = (e[key] as List<Object?>?)?.cast<String>() ?? const [];
          expect(list, isNotEmpty, reason: '$id.$key');
          expect(
            list.every((s) => s.trim().isNotEmpty),
            isTrue,
            reason: '$id.$key has a blank entry',
          );
        }
        for (final ref in (e['refs']! as List<Object?>).cast<String>()) {
          expect(
            refFormats[kind]!.hasMatch(ref),
            isTrue,
            reason: '$id: bad ref "$ref"',
          );
          // Sahih Muslim is cited by Abd al-Baqi number (sunnah.com, the
          // in-app "go to"), which ends at 3033 — not the dataset's
          // sequential one (2766 is sequential 7008).
          if (ref.startsWith('Muslim ')) {
            expect(
              int.parse(ref.split(' ')[1].split('-').first),
              lessThanOrEqualTo(3033),
              reason: '$id: "$ref" looks like an internal number',
            );
          }
        }
      }
    }, skip: file.existsSync() ? false : '${file.path} not written yet');
  }
}
