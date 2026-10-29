import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodCall, SystemChannels;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/quran/domain/entities/ayah.dart';
import 'package:productive_muslim/features/quran/domain/entities/surah.dart';
import 'package:productive_muslim/features/quran/domain/repositories/quran_repository.dart';
import 'package:productive_muslim/features/quran/presentation/screens/quran_reader_screen.dart';
import 'package:productive_muslim/features/quran/presentation/screens/quran_screen.dart';
import 'package:productive_muslim/features/quran/presentation/state/quran_store.dart';
import 'package:productive_muslim/shared/widgets/q_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// In-memory [QuranRepository] — 3 surahs with a few ayahs each.
final class FakeQuranRepository implements QuranRepository {
  static const surahsData = [
    Surah(
      id: 1,
      nameArabic: 'الفاتحة',
      transliteration: 'Al-Faatiha',
      translationEn: 'The Opening',
      ayahCount: 2,
      revelation: 'meccan',
    ),
    Surah(
      id: 2,
      nameArabic: 'البقرة',
      transliteration: 'Al-Baqara',
      translationEn: 'The Cow',
      ayahCount: 2,
      revelation: 'medinan',
    ),
    Surah(
      id: 3,
      nameArabic: 'آل عمران',
      transliteration: 'Aal-i-Imraan',
      translationEn: 'The Family of Imraan',
      ayahCount: 1,
      revelation: 'medinan',
    ),
  ];

  static const ayahsData = {
    1: [
      Ayah(
        id: 1,
        surah: 1,
        number: 1,
        arabic: 'بِسْمِ اللَّهِ',
        translationEn: 'In the name of Allah',
        translationBn: 'আল্লাহর নামে',
      ),
      Ayah(
        id: 2,
        surah: 1,
        number: 2,
        arabic: 'الْحَمْدُ لِلَّهِ',
        translationEn: 'All praise is due to Allah',
        translationBn: 'সমস্ত প্রশংসা আল্লাহর',
      ),
    ],
    2: [
      Ayah(
        id: 8,
        surah: 2,
        number: 1,
        arabic: 'الم',
        translationEn: 'Alif Lam Meem',
        translationBn: '',
      ),
      Ayah(
        id: 9,
        surah: 2,
        number: 2,
        arabic: 'ذَٰلِكَ الْكِتَابُ',
        translationEn: 'This is the Book',
        translationBn: '',
      ),
    ],
    3: [
      Ayah(
        id: 294,
        surah: 3,
        number: 1,
        arabic: 'الم',
        translationEn: 'Alif Lam Meem',
        translationBn: '',
      ),
    ],
  };

  QuranPosition? storedLastRead;
  final storedBookmarks = <int>{};

  /// Per-test ayah overrides (e.g. a long surah for scroll tests).
  final extraAyahs = <int, List<Ayah>>{};

  /// Makes `ayahsOf` fail (a broken bundled DB).
  bool failAyahs = false;

  @override
  Future<Result<List<Surah>>> surahs() async =>
      const Result.success(surahsData);

  @override
  Future<Result<List<Ayah>>> ayahsOf(int surah) async => failAyahs
      ? const Result.failure(UnexpectedFailure('broken'))
      : Result.success(extraAyahs[surah] ?? ayahsData[surah] ?? const []);

  @override
  Future<Result<List<Surah>>> searchSurahs(String query) async {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return const Result.success(surahsData);
    }
    return Result.success([
      for (final s in surahsData)
        if (s.transliteration.toLowerCase().contains(needle) ||
            s.translationEn.toLowerCase().contains(needle))
          s,
    ]);
  }

  @override
  Future<Result<QuranPosition?>> lastRead() async =>
      Result.success(storedLastRead);

  @override
  Future<Result<void>> setLastRead(QuranPosition position) async {
    storedLastRead = position;
    return const Result.success(null);
  }

  @override
  Future<Result<Set<int>>> bookmarkedAyahIds() async =>
      Result.success({...storedBookmarks});

  @override
  Future<Result<void>> toggleBookmark(int ayahId) async {
    if (!storedBookmarks.remove(ayahId)) {
      storedBookmarks.add(ayahId);
    }
    return const Result.success(null);
  }
}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  late FakeQuranRepository repo;
  late QuranStore store;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repo = FakeQuranRepository();
    store = QuranStore(repo, SharedPreferencesAsync());
    await store.load();
    GetIt.I.registerSingleton<QuranStore>(store);
  });

  tearDown(() => GetIt.I.reset());

  /// Flushes the reader's 500ms mark-read debounce so no timer is pending
  /// when the test ends.
  Future<void> flushMarkRead(WidgetTester tester) =>
      tester.pump(const Duration(milliseconds: 600));

  group('QuranScreen', () {
    testWidgets('renders the surah index with first-open banner', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const QuranScreen()));
      await tester.pump();

      expect(find.text('Al-Faatiha'), findsOneWidget);
      expect(find.text('Al-Baqara'), findsOneWidget);
      expect(find.text('Aal-i-Imraan'), findsOneWidget);
      expect(find.text('2 ayahs · Meccan'), findsOneWidget);
      // No last-read position yet → quiet first-open banner, no resume card.
      expect(
        find.text(
          'Bismillah — start reading and Productive Muslim will remember '
          'where you left off.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continue reading'), findsNothing);
    });

    testWidgets('shows the resume card when a position is stored', (
      tester,
    ) async {
      repo.storedLastRead = const QuranPosition(2, 2);
      await store.load();
      await tester.pumpWidget(_app(const QuranScreen()));
      await tester.pump();

      expect(find.text('Continue reading'), findsOneWidget);
      expect(find.text('Al-Baqara · 2'), findsOneWidget);
    });

    testWidgets('search filters the list and empty results show a notice', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const QuranScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'cow');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Al-Baqara'), findsOneWidget);
      expect(find.text('Al-Faatiha'), findsNothing);
      expect(find.text('Aal-i-Imraan'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Al-Baqara'), findsNothing);
      expect(
        find.text('No matching surah — try another name or number'),
        findsOneWidget,
      );
    });

    testWidgets('bookmarks sheet lists saved ayahs and opens the reader', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const QuranScreen()));
      await tester.pump();

      await tester.tap(find.byTooltip('Bookmarks'));
      await tester.pumpAndSettle();
      expect(find.textContaining('No bookmarks yet'), findsOneWidget);
      Navigator.of(tester.element(find.byType(BottomSheet))).pop();
      await tester.pumpAndSettle();

      // Global id 4 = surah 2 (after Al-Faatiha's 2 ayahs), ayah 2.
      await store.toggleBookmark(4);
      await tester.tap(find.byTooltip('Bookmarks'));
      await tester.pumpAndSettle();
      // Reference plus a first-words preview of the ayah.
      expect(find.text('2:2 · This is the Book'), findsOneWidget);

      await tester.tap(find.textContaining('2:2'));
      await tester.pumpAndSettle();
      expect(find.byType(QuranReaderScreen), findsOneWidget);
      expect(find.text('This is the Book'), findsOneWidget);

      await flushMarkRead(tester);
    });

    testWidgets('swiping a bookmark away removes it, with undo', (
      tester,
    ) async {
      await store.toggleBookmark(4);
      await tester.pumpWidget(_app(const QuranScreen()));
      await tester.pump();
      await tester.tap(find.byTooltip('Bookmarks'));
      await tester.pumpAndSettle();

      await tester.drag(find.textContaining('2:2'), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(store.bookmarks.value, isEmpty);
      expect(find.text('Bookmark removed'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(store.bookmarks.value, {4});
      expect(find.textContaining('2:2'), findsOneWidget);
    });

    testWidgets('tapping a surah row opens the reader', (tester) async {
      await tester.pumpWidget(_app(const QuranScreen()));
      await tester.pump();

      await tester.tap(find.text('Al-Faatiha'));
      await tester.pumpAndSettle();

      expect(find.byType(QuranReaderScreen), findsOneWidget);
      expect(find.text('In the name of Allah'), findsOneWidget);

      await flushMarkRead(tester);
    });
  });

  group('QuranReaderScreen', () {
    testWidgets('renders arabic and translation per ayah', (tester) async {
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pump();

      expect(find.text('Al-Faatiha'), findsOneWidget); // app bar title
      expect(find.text('بِسْمِ اللَّهِ'), findsOneWidget);
      expect(find.text('In the name of Allah'), findsOneWidget);
      expect(find.text('الْحَمْدُ لِلَّهِ'), findsOneWidget);
      expect(find.text('All praise is due to Allah'), findsOneWidget);

      await flushMarkRead(tester);
      // Opening without scrolling must not overwrite last-read with ayah 1.
      expect(repo.storedLastRead, isNull);
    });

    testWidgets('settings sheet switch hides the translation', (tester) async {
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pump();
      expect(find.text('In the name of Allah'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(find.text('Show translation'), findsOneWidget);
      expect(find.text('Arabic text size'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(store.showTranslation.value, isFalse);
      expect(find.text('In the name of Allah'), findsNothing);

      await flushMarkRead(tester);
    });

    testWidgets('bookmark tap updates the store and fills the icon', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pump();

      expect(find.byIcon(Icons.bookmark_outline), findsNWidgets(2));
      await tester.tap(find.byIcon(Icons.bookmark_outline).first);
      await tester.pump();

      expect(store.bookmarks.value, contains(1));
      expect(repo.storedBookmarks, contains(1));
      expect(find.byIcon(Icons.bookmark), findsOneWidget);

      await flushMarkRead(tester);
    });

    testWidgets('copy shows the "Copied" snackbar', (tester) async {
      final clipboardCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          clipboardCalls.add(call);
          return null;
        },
      );
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.copy_outlined).first);
      await tester.pump();
      await tester.pump();

      expect(find.text('Copied'), findsOneWidget);
      expect(
        clipboardCalls.map((c) => c.method),
        contains('Clipboard.setData'),
      );

      await flushMarkRead(tester);
      // Let the snackbar finish so no timers leak past the test.
      await tester.pumpAndSettle();
    });

    testWidgets('after a user scroll, records the ayah at the top edge', (
      tester,
    ) async {
      repo.extraAyahs[1] = [
        for (var i = 1; i <= 40; i++)
          Ayah(
            id: 1000 + i,
            surah: 1,
            number: i,
            arabic: 'arabic $i',
            translationEn: 'translation $i',
            translationBn: 'অনুবাদ $i',
          ),
      ];
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pump();

      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pump();
      await flushMarkRead(tester);

      // Expected: the last built card whose top is at/above the list top.
      final listTop = tester.getTopLeft(find.byType(ListView)).dy;
      var expected = 0;
      for (var i = 1; i <= 40; i++) {
        final card = find.ancestor(
          of: find.text('arabic $i'),
          matching: find.byType(QCard),
        );
        if (card.evaluate().isNotEmpty &&
            tester.getTopLeft(card).dy <= listTop + 0.5) {
          expected = i;
        }
      }
      expect(expected, greaterThan(1));
      expect(repo.storedLastRead?.ayah, expected);
    });

    testWidgets('resume jump lands on the ayah despite uneven card heights', (
      tester,
    ) async {
      repo.extraAyahs[1] = [
        for (var i = 1; i <= 60; i++)
          Ayah(
            id: 1000 + i,
            surah: 1,
            number: i,
            arabic: 'arabic $i',
            // Every third card is much taller than the 180px guess.
            translationEn: 'translation $i ' * (i % 3 == 0 ? 60 : 1),
            translationBn: '',
          ),
      ];
      await tester.pumpWidget(
        _app(const QuranReaderScreen(surahId: 1, initialAyah: 45)),
      );
      await tester.pumpAndSettle();

      final listTop = tester.getTopLeft(find.byType(ListView)).dy;
      final card = find.ancestor(
        of: find.text('arabic 45'),
        matching: find.byType(QCard),
      );
      expect(card, findsOneWidget);
      expect((tester.getTopLeft(card).dy - listTop).abs(), lessThan(40));
      // The programmatic jump is not a read.
      expect(repo.storedLastRead, isNull);
    });

    testWidgets('a surah that fits on screen is recorded without a scroll', (
      tester,
    ) async {
      // Aal-i-Imraan has a single ayah here.
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 3)));
      await tester.pumpAndSettle();
      expect(repo.storedLastRead, const QuranPosition(3, 1));
    });

    testWidgets('go to ayah accepts localized digits and jumps there', (
      tester,
    ) async {
      repo.extraAyahs[1] = [
        for (var i = 1; i <= 40; i++)
          Ayah(
            id: 1000 + i,
            surah: 1,
            number: i,
            arabic: 'arabic $i',
            translationEn: 'translation $i',
            translationBn: '',
          ),
      ];
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pumpAndSettle();
      expect(find.text('arabic 30'), findsNothing);

      await tester.tap(find.byTooltip('Go to ayah'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '৪১'); // out of range
      await tester.tap(find.text('Go'));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.enterText(find.byType(TextField), '৩০');
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();
      expect(find.text('arabic 30'), findsOneWidget);
    });

    testWidgets('the last card opens the next surah, none after 114', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pumpAndSettle();
      expect(find.text('Next surah'), findsOneWidget);

      await tester.tap(find.text('Next surah'));
      await tester.pumpAndSettle();
      expect(find.text('Alif Lam Meem'), findsOneWidget);

      repo.extraAyahs[114] = FakeQuranRepository.ayahsData[3]!;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 114)));
      await tester.pumpAndSettle();
      expect(find.text('Next surah'), findsNothing);
    });

    testWidgets('a failed load shows a retry instead of an endless skeleton', (
      tester,
    ) async {
      repo.failAyahs = true;
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pump();
      expect(find.text('Try again'), findsOneWidget);

      repo.failAyahs = false;
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('In the name of Allah'), findsOneWidget);
      await flushMarkRead(tester);
    });

    testWidgets('an empty surah shows a retry, not an endless skeleton', (
      tester,
    ) async {
      repo.extraAyahs[1] = const [];
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pump();
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('records as soon as the scroll settles (leaving right after)', (
      tester,
    ) async {
      repo.extraAyahs[1] = [
        for (var i = 1; i <= 40; i++)
          Ayah(
            id: 1000 + i,
            surah: 1,
            number: i,
            arabic: 'arabic $i',
            translationEn: 'translation $i',
            translationBn: 'অনুবাদ $i',
          ),
      ];
      await tester.pumpWidget(_app(const QuranReaderScreen(surahId: 1)));
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      // Let the fling settle (well under the old 500ms debounce), then leave.
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpWidget(const SizedBox());
      expect(repo.storedLastRead?.ayah, greaterThan(1));
    });
  });
}
