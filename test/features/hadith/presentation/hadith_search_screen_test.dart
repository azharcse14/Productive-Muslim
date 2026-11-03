import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_search.dart';
import 'package:productive_muslim/features/hadith/domain/repositories/hadith_book_repository.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_search_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_section_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_section_store.dart';

const _section = HadithSection(
  number: 1,
  name: 'Revelation',
  first: 1,
  last: 7,
);

const _bukhari = HadithBook(
  id: 'bukhari',
  en: 'Sahih al-Bukhari',
  bn: 'সহিহ বুখারি',
  author: '',
  kind: 'sahih',
  total: 7,
  editionAr: 'ara-bukhari',
  editionEn: 'eng-bukhari',
  editionBn: 'ben-bukhari',
  sections: [_section],
);

HadithSearchHit _hit(int n) => HadithSearchHit(
  book: _bukhari,
  section: _section,
  languageCode: 'en',
  number: n,
  snippet: '…the prayer $n…',
  matchStart: 5,
  matchEnd: 11,
);

final class _FakeRepository implements HadithBookRepository {
  final queries = <String>[];
  bool released = false;

  @override
  Future<Result<List<HadithBook>>> books() async =>
      const Result.success([_bukhari]);

  @override
  Future<Result<List<BookHadith>>> section(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async => const Result.success([
    BookHadith(
      number: 3,
      arabic: '',
      translation: 'The prayer 3 in full',
      grade: 'Sahih',
      reference: 'Sahih al-Bukhari 3',
    ),
  ]);

  @override
  Future<Result<HadithSearchResults>> search(
    String query,
    String languageCode, {
    int limit = hadithSearchLimit,
  }) async {
    queries.add(query);
    return switch (query) {
      'fail' => const Result.failure(UnexpectedFailure('broken')),
      'prayer' => Result.success((
        hits: [for (var i = 1; i <= 3; i++) _hit(i)],
        truncated: true,
      )),
      _ => const Result.success((hits: [], truncated: false)),
    };
  }

  @override
  void releaseSearch() => released = true;
}

Future<_FakeRepository> _pump(WidgetTester tester) async {
  final repo = _FakeRepository();
  GetIt.I
    ..registerSingleton<HadithBookRepository>(repo)
    ..registerFactory<HadithSectionStore>(() => HadithSectionStore(repo));
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HadithSearchScreen(),
    ),
  );
  return repo;
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  tearDown(() => GetIt.I.reset());

  testWidgets('empty query shows the prompt and warms the corpus up', (
    tester,
  ) async {
    final repo = await _pump(tester);
    expect(find.textContaining('Search every collection'), findsOneWidget);
    expect(repo.queries, ['']);
  });

  testWidgets('results list matches, the cap note, and opens a hadith', (
    tester,
  ) async {
    final repo = await _pump(tester);
    await _type(tester, 'pra');
    await _type(tester, 'prayer');
    expect(repo.queries, ['', 'pra', 'prayer']);

    expect(find.text('Sahih al-Bukhari · 1'), findsOneWidget);
    expect(find.text('Sahih al-Bukhari · 3'), findsOneWidget);
    expect(find.text('Showing the first 3 matches'), findsOneWidget);

    await tester.tap(find.text('Sahih al-Bukhari · 3'));
    await tester.pumpAndSettle();
    expect(find.byType(HadithSectionScreen), findsOneWidget);
    expect(find.text('The prayer 3 in full'), findsOneWidget);
  });

  testWidgets('typing fast only searches the last query', (tester) async {
    final repo = await _pump(tester);
    await tester.enterText(find.byType(TextField), 'p');
    await tester.pump(const Duration(milliseconds: 100));
    await _type(tester, 'prayer');
    expect(repo.queries, ['', 'prayer']);
  });

  testWidgets('no match shows the no-results message', (tester) async {
    await _pump(tester);
    await _type(tester, 'zzz');
    expect(find.textContaining('No hadith matches'), findsOneWidget);
  });

  testWidgets('a failure offers retry; leaving releases the corpus', (
    tester,
  ) async {
    final repo = await _pump(tester);
    await _type(tester, 'fail');
    expect(find.text('Try again'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    expect(repo.released, isTrue);
  });
}
