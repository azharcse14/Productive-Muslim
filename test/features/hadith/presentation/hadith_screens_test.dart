import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';
import 'package:productive_muslim/features/hadith/domain/repositories/hadith_book_repository.dart';
import 'package:productive_muslim/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_books_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_section_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_sections_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_topic_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_books_store.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_section_store.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_store.dart';

Hadith _h(String id, String topic) => Hadith(
      id: id,
      topic: topic,
      grade: 'Sahih',
      arabic: 'عربي-$id',
      en: 'English $id',
      bn: '',
      narrator: 'Abu Hurairah (RA)',
      reference: 'Sahih Bukhari $id',
    );

final class _FakeHadithRepository implements HadithRepository {
  @override
  Future<Result<List<Hadith>>> all() async => Result.success([
        _h('1', 'faith'),
        _h('2', 'character'),
        _h('3', 'character'),
      ]);
}

const _bukhari = HadithBook(
  id: 'bukhari',
  en: 'Sahih al-Bukhari',
  bn: '',
  author: 'Imam al-Bukhari',
  kind: 'sahih',
  total: 7563,
  editionAr: 'ara-bukhari',
  editionEn: 'eng-bukhari',
  editionBn: 'ben-bukhari',
  sections: [
    HadithSection(number: 1, name: 'Revelation', count: 7),
  ],
);

final class _FakeBookRepository implements HadithBookRepository {
  _FakeBookRepository({this.fail = false});

  final bool fail;

  @override
  Future<Result<List<HadithBook>>> books() async =>
      const Result.success([_bukhari]);

  @override
  Future<Result<List<BookHadith>>> section(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async {
    if (fail) {
      return const Result.failure(UnexpectedFailure('offline'));
    }
    return const Result.success([
      BookHadith(
        number: 1,
        arabic: 'عربي-١',
        translation: 'Actions are by intentions',
        grade: 'Sahih',
        reference: 'Sahih al-Bukhari 1',
      ),
    ]);
  }
}

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

Future<void> _register({bool failSection = false}) async {
  final store = HadithStore(_FakeHadithRepository());
  await store.load();
  final booksRepo = _FakeBookRepository(fail: failSection);
  final booksStore = HadithBooksStore(booksRepo);
  await booksStore.load();
  GetIt.I
    ..registerSingleton<HadithStore>(store)
    ..registerSingleton<HadithBooksStore>(booksStore)
    ..registerFactory<HadithSectionStore>(() => HadithSectionStore(booksRepo));
}

void main() {
  tearDown(() => GetIt.I.reset());

  group('HadithScreen', () {
    testWidgets('shows the full-collections card and the topic grid',
        (tester) async {
      await _register();
      await tester.pumpWidget(_app(const HadithScreen()));
      await tester.pump();

      expect(find.text('Hadith collections'), findsOneWidget);
      expect(find.text('Faith'), findsOneWidget);
      expect(find.text('Character & manners'), findsOneWidget);
      expect(find.text('1 hadith'), findsOneWidget); // faith
      expect(find.text('2 hadith'), findsOneWidget); // character
    });

    testWidgets('tapping a topic opens its hadith list', (tester) async {
      await _register();
      await tester.pumpWidget(_app(const HadithScreen()));
      await tester.pump();

      await tester.tap(find.text('Character & manners'));
      await tester.pumpAndSettle();

      expect(find.byType(HadithTopicScreen), findsOneWidget);
      expect(find.text('English 2'), findsOneWidget);
      expect(find.text('Sahih'), findsWidgets);
    });
  });

  group('Hadith books browsing', () {
    testWidgets('books -> sections -> section reader fetches hadith',
        (tester) async {
      await _register();
      await tester.pumpWidget(_app(const HadithBooksScreen()));
      await tester.pump();

      expect(find.text('Sahih al-Bukhari'), findsOneWidget);
      expect(find.text('Every hadith authentic (Sahih)'), findsOneWidget);

      await tester.tap(find.text('Sahih al-Bukhari'));
      await tester.pumpAndSettle();
      expect(find.byType(HadithSectionsScreen), findsOneWidget);

      await tester.tap(find.text('Revelation'));
      await tester.pumpAndSettle();
      expect(find.byType(HadithSectionScreen), findsOneWidget);
      expect(find.text('Actions are by intentions'), findsOneWidget);
    });

    testWidgets('a failed fetch shows the retry affordance', (tester) async {
      await _register(failSection: true);
      await tester.pumpWidget(
        _app(const HadithSectionScreen(
          book: _bukhari,
          section: HadithSection(
            number: 1,
            name: 'Revelation',
            count: 7,
          ),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
