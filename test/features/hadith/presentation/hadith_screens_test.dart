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
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_section_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_sections_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_topic_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_books_store.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_section_store.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

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

/// Fails the first load, succeeds after.
final class _FlakyHadithRepository implements HadithRepository {
  int calls = 0;

  @override
  Future<Result<List<Hadith>>> all() async => calls++ == 0
      ? const Result.failure(UnexpectedFailure('broken'))
      : Result.success([_h('1', 'faith')]);
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
    HadithSection(number: 1, name: 'Revelation', first: 1, last: 7, count: 7),
  ],
);

final class _FakeBookRepository implements HadithBookRepository {
  _FakeBookRepository({this.fail = false});

  final bool fail;

  /// Language of every section fetch, in order.
  final languages = <String>[];

  @override
  Future<Result<List<HadithBook>>> books() async =>
      const Result.success([_bukhari]);

  @override
  Future<Result<List<BookHadith>>> section(
    HadithBook book,
    HadithSection section,
    String languageCode,
  ) async {
    languages.add(languageCode);
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

Widget _app(Widget home, {Locale? locale}) => MaterialApp(
  theme: AppTheme.light(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

Future<_FakeBookRepository> _register({bool failSection = false}) async {
  final store = HadithStore(_FakeHadithRepository());
  await store.load();
  final booksRepo = _FakeBookRepository(fail: failSection);
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final booksStore = HadithBooksStore(booksRepo, SharedPreferencesAsync());
  await booksStore.load();
  GetIt.I
    ..registerSingleton<HadithStore>(store)
    ..registerSingleton<HadithBooksStore>(booksStore)
    ..registerFactory<HadithSectionStore>(() => HadithSectionStore(booksRepo));
  return booksRepo;
}

void main() {
  tearDown(() => GetIt.I.reset());

  group('HadithScreen', () {
    testWidgets('shows the full-collections card and the topic grid', (
      tester,
    ) async {
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

  testWidgets('detail: a failed load offers retry, not "not found"', (
    tester,
  ) async {
    final store = HadithStore(_FlakyHadithRepository());
    await store.load();
    GetIt.I.registerSingleton<HadithStore>(store);
    await tester.pumpWidget(_app(const HadithDetailScreen(id: '1')));
    await tester.pump();

    expect(find.text("This hadith isn't available."), findsNothing);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('English 1'), findsOneWidget);
  });

  group('Hadith books browsing', () {
    testWidgets('books -> sections -> section reader fetches hadith', (
      tester,
    ) async {
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

    testWidgets('the last opened chapter is offered as Continue reading', (
      tester,
    ) async {
      await _register();
      await GetIt.I<HadithBooksStore>().markOpened(
        _bukhari,
        _bukhari.sections.first,
        'en',
      );
      // A fresh store restores it from prefs.
      final restored = HadithBooksStore(
        _FakeBookRepository(),
        SharedPreferencesAsync(),
      );
      await restored.load();
      expect(restored.resumeFor('en')?.$2.name, 'Revelation');
      expect(restored.resumeFor('bn'), isNull); // other numbering

      await tester.pumpWidget(_app(const HadithBooksScreen()));
      await tester.pump();
      await tester.tap(find.text('Continue reading'));
      await tester.pumpAndSettle();
      expect(find.byType(HadithSectionScreen), findsOneWidget);
    });

    test('the reading offset persists and survives reopening', () async {
      await _register();
      final store = GetIt.I<HadithBooksStore>();
      final section = _bukhari.sections.first;
      await store.saveOffset(_bukhari, section, 'en', 1234.4);
      // Reopening the same chapter keeps its offset.
      await store.markOpened(_bukhari, section, 'en');

      final restored = HadithBooksStore(
        _FakeBookRepository(),
        SharedPreferencesAsync(),
      );
      await restored.load();
      expect(restored.savedOffset(_bukhari, section, 'en'), 1234);
      expect(restored.savedOffset(_bukhari, section, 'bn'), 0);

      // A value saved before offsets existed still resumes, at the top.
      await SharedPreferencesAsync().setString(
        'hadith_last_section',
        '${_bukhari.id}|en|${section.number}',
      );
      await restored.load();
      expect(restored.resumeFor('en')?.$2.name, 'Revelation');
      expect(restored.savedOffset(_bukhari, section, 'en'), 0);
    });

    testWidgets('hadith-number lookup opens just that hadith', (tester) async {
      await _register();
      await tester.pumpWidget(_app(const HadithSectionsScreen(book: _bukhari)));
      await tester.tap(find.byTooltip('Go to hadith number'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '১'); // Bengali digit
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.byType(HadithSectionScreen), findsOneWidget);
      expect(find.text('Actions are by intentions'), findsOneWidget);
      // A lookup isn't reading: "Continue reading" stays untouched.
      expect(GetIt.I<HadithBooksStore>().lastOpened.value, isNull);
    });

    testWidgets('a failed fetch shows the retry affordance', (tester) async {
      await _register(failSection: true);
      await tester.pumpWidget(
        _app(
          const HadithSectionScreen(
            book: _bukhari,
            section: HadithSection(
              number: 1,
              name: 'Revelation',
              first: 1,
              last: 7,
              count: 7,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('retry after a language switch refetches the opened '
        "language's chapter", (tester) async {
      final repo = await _register(failSection: true);
      const screen = HadithSectionScreen(
        book: _bukhari,
        section: HadithSection(
          number: 1,
          name: 'Revelation',
          first: 1,
          last: 7,
          count: 7,
        ),
      );
      await tester.pumpWidget(_app(screen, locale: const Locale('bn')));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(screen, locale: const Locale('en')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      // Section numbers differ between the bn and en lists, so the
      // section must keep coming from the language it was opened in.
      expect(repo.languages, ['bn', 'bn']);
    });
  });
}
