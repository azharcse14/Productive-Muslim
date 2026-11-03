import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/fasting/presentation/screens/fasting_screen.dart';
import 'package:productive_muslim/features/fasting/presentation/state/fasting_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    // 2026-06-15 is a Monday — a recommended fast.
    GetIt.I.registerSingleton<FastingStore>(
      FastingStore(
        SharedPreferencesAsync(),
        now: () => DateTime(2026, 6, 15, 10),
      ),
    );
  });

  tearDown(() => GetIt.I.reset());

  group('FastingScreen', () {
    testWidgets('shows the recommended-today card and a log button', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recommended fast today'), findsOneWidget);
      expect(find.text('Monday & Thursday'), findsWidgets);
      expect(find.text('Log today'), findsOneWidget);
    });

    testWidgets('tapping the log button records the fast', (tester) async {
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log today'));
      await tester.pumpAndSettle();

      expect(GetIt.I<FastingStore>().isLogged(DateTime(2026, 6, 15)), isTrue);
      expect(find.text('Logged for today'), findsOneWidget);
    });

    testWidgets('logging a fast toasts it with an undo', (tester) async {
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log today'));
      await tester.pumpAndSettle();
      expect(find.text('Logged Mon, Jun 15'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(GetIt.I<FastingStore>().isLogged(DateTime(2026, 6, 15)), isFalse);
    });

    testWidgets('tapping a past heatmap day logs it as qaza', (tester) async {
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();
      // Jun 10 2026 (a Wednesday, not recommended) via its cell label.
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Wed, Jun 10')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make-up (qaza)'));
      await tester.pumpAndSettle();
      final store = GetIt.I<FastingStore>();
      expect(store.isLogged(DateTime(2026, 6, 10)), isTrue);
      expect(store.isQaza(DateTime(2026, 6, 10)), isTrue);
    });

    testWidgets('renders the upcoming list', (tester) async {
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();
      // The log card grew (heatmap hint), so scroll the list down to it.
      await tester.scrollUntilVisible(
        find.text('Upcoming recommended fasts'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Upcoming recommended fasts'), findsOneWidget);
    });

    testWidgets('a forbidden day (Eid al-Adha) offers no log button', (
      tester,
    ) async {
      await GetIt.I.reset();
      GetIt.I.registerSingleton<FastingStore>(
        FastingStore(
          SharedPreferencesAsync(),
          now: () => DateTime(2026, 5, 27, 10), // 10 Dhul-Hijjah 1447
        ),
      );
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Fasting is not permitted today'), findsOneWidget);
      expect(find.text('Log a voluntary fast'), findsNothing);
      expect(find.text('Log today'), findsNothing);
    });

    testWidgets('a Ramadan day is the obligatory fast, not voluntary', (
      tester,
    ) async {
      await GetIt.I.reset();
      GetIt.I.registerSingleton<FastingStore>(
        FastingStore(
          SharedPreferencesAsync(),
          now: () => DateTime(2026, 3, 2, 10), // ~12 Ramadan 1447, a Monday
        ),
      );
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Ramadan — the obligatory fast'), findsOneWidget);
      expect(find.text('Log a voluntary fast'), findsNothing);
    });

    testWidgets('paging back to last month lets its fasts be logged', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsOneWidget);
      // No paging into the future.
      final next = find.widgetWithIcon(IconButton, Icons.chevron_right);
      expect(tester.widget<IconButton>(next).onPressed, isNull);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(find.text('May 2026'), findsOneWidget);
      // May 6 2026: a Wednesday, not a recommended day.
      await tester.ensureVisible(find.bySemanticsLabel(RegExp(r'^Wed, May 6')));
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Wed, May 6')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Make-up (qaza)'));
      await tester.pumpAndSettle();
      expect(GetIt.I<FastingStore>().isLogged(DateTime(2026, 5, 6)), isTrue);
      // The calendar's spoken summary names the shown month.
      expect(
        find.bySemanticsLabel('1 fast logged in May 2026'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
      expect(find.text('June 2026'), findsOneWidget);
    });

    testWidgets("tapping a future day says why it can't be logged", (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Sat, Jun 20')));
      await tester.pump();
      expect(
        find.text('You can log this fast once the day has come.'),
        findsOneWidget,
      );
      expect(GetIt.I<FastingStore>().isLogged(DateTime(2026, 6, 20)), isFalse);
    });

    testWidgets('tapping an Eid day says fasting is not permitted', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      // May 27 2026 = 10 Dhul-Hijjah 1447 (Eid al-Adha).
      await tester.tap(find.bySemanticsLabel(RegExp(r'^Wed, May 27')));
      await tester.pump();
      expect(
        find.text("Fasting isn't permitted on this day (Eid or Tashreeq)."),
        findsOneWidget,
      );
    });
  });
}
