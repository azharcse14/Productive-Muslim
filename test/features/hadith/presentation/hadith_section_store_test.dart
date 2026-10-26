import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';
import 'package:productive_muslim/features/hadith/domain/repositories/hadith_book_repository.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_section_store.dart';

final class _SlowRepository implements HadithBookRepository {
  final pending = Completer<Result<List<BookHadith>>>();

  @override
  Future<Result<List<HadithBook>>> books() async => const Result.success([]);

  @override
  Future<Result<List<BookHadith>>> section(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) =>
      pending.future;
}

const _section = HadithSection(number: 1, name: 'Revelation', first: 1, last: 2);

const _book = HadithBook(
  id: 'bukhari',
  en: 'Sahih al-Bukhari',
  bn: 'বুখারি',
  author: 'Author',
  kind: 'sahih',
  total: 2,
  editionAr: 'ara',
  editionEn: 'eng',
  editionBn: 'ben',
  sections: [_section],
);

void main() {
  test('leaving before the section loads does not write disposed signals',
      () async {
    final repo = _SlowRepository();
    final store = HadithSectionStore(repo);
    final load = store.load(_book, _section, 'en');
    store.dispose(); // user popped the screen mid-load
    repo.pending.complete(const Result.success([]));
    await expectLater(load, completes);
  });
}
