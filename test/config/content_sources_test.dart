import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/config/content_sources.dart';

void main() {
  test('remote hadith sources are pinned to full commit SHAs', () {
    final sha = RegExp(r'^[0-9a-f]{40}$');
    expect(ContentSources.hadithApiSha, matches(sha));
    expect(ContentSources.hadithBanglaSha, matches(sha));
    expect(
      ContentSources.hadithApiEditionsBase,
      contains('@${ContentSources.hadithApiSha}/'),
    );
    expect(
      ContentSources.hadithBanglaBase,
      endsWith('/${ContentSources.hadithBanglaSha}'),
    );
  });

  test('no source URL in the app or the DB tool uses a moving ref', () {
    final files = [
      File('lib/config/content_sources.dart'),
      File('lib/features/hadith/data/hadith_book_remote_data_source.dart'),
      File('tool/hadith_db_build.dart'),
    ];
    final url = RegExp(
      r'https?://[^\s'
      "'"
      ']+',
    );
    for (final file in files) {
      for (final m in url.allMatches(file.readAsStringSync())) {
        final u = m.group(0)!;
        expect(u, isNot(contains('@1')), reason: '${file.path}: $u');
        expect(u, isNot(contains('/main')), reason: '${file.path}: $u');
      }
    }
  });
}
