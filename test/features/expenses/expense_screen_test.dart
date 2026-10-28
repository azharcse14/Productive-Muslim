import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/expenses/presentation/screens/expense_screen.dart';
import 'package:productive_muslim/features/expenses/presentation/state/expense_store.dart';
import 'package:productive_muslim/shared/widgets/q_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Prefs whose writes take a while, like a real platform channel.
base class _SlowPrefs extends InMemorySharedPreferencesAsync {
  _SlowPrefs() : super.empty();

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return super.setString(key, value, options);
  }
}

Widget _app() => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const ExpenseScreen(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ExpenseStore store;

  void register() {
    store = ExpenseStore(
      SharedPreferencesAsync(),
      now: () => DateTime(2026, 10, 26, 10),
    );
    GetIt.I.registerSingleton<ExpenseStore>(store);
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('double-tapping Save adds once and keeps the screen', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance = _SlowPrefs();
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '120');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Save'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(store.entries.value, hasLength(1));
    expect(find.byType(ExpenseScreen), findsOneWidget);
  });

  testWidgets('budget dialog saves without a disposed-controller error', (
    tester,
  ) async {
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Monthly budget'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '5000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(store.budget.value, 5000);
  });

  testWidgets('editor Delete removes the entry and Undo restores it', (
    tester,
  ) async {
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('tea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('tea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(store.entries.value, isEmpty);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.entries.value.single.note, 'tea');
  });

  testWidgets('compares with the same span of last month; groups by day', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    register();
    Future<void> add(int amount, DateTime date) => store.add(
      amount: amount,
      category: ExpenseCategory.want,
      note: 'n$amount',
      date: date,
    );
    await add(100, DateTime(2026, 9, 10));
    await add(500, DateTime(2026, 9, 28)); // after "now"'s day: not counted
    await add(80, DateTime(2026, 10, 26, 9));
    await add(50, DateTime(2026, 10, 25));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('30 more than this time last month'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
  });

  testWidgets('day headers count calendar days, not 24h spans (DST)', (
    tester,
  ) async {
    // US clocks spring forward on Mar 8 2026: midnight-to-midnight is 23h,
    // so a duration diff called yesterday "Today" (run with
    // TZ=America/New_York to exercise it).
    store = ExpenseStore(
      SharedPreferencesAsync(),
      now: () => DateTime(2026, 3, 9, 10),
    );
    GetIt.I.registerSingleton<ExpenseStore>(store);
    await store.add(
      amount: 50,
      category: ExpenseCategory.want,
      date: DateTime(2026, 3, 8, 12),
    );
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('tapping a category filters the list; tapping again clears', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await store.add(amount: 90, category: ExpenseCategory.need, note: 'rice');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    // The category row (first); entry rows below also name their category.
    await tester.tap(find.text('Wants').first);
    await tester.pumpAndSettle();
    expect(find.text('tea'), findsOneWidget);
    expect(find.text('rice'), findsNothing);
    await tester.tap(find.text('Wants').first);
    await tester.pumpAndSettle();
    expect(find.text('rice'), findsOneWidget);
  });

  testWidgets('a past note is suggested and brings its category back', (
    tester,
  ) async {
    register();
    await store.add(amount: 80, category: ExpenseCategory.family, note: 'Gift');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'gi');
    await tester.pump();
    await tester.tap(find.widgetWithText(QChip, 'Gift'));
    await tester.enterText(find.byType(TextField).first, '50');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final added = store.entries.value.firstWhere((e) => e.amount == 50);
    expect((added.note, added.category), ('Gift', ExpenseCategory.family));
  });

  testWidgets('a decimal amount shows an error instead of silently failing', (
    tester,
  ) async {
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '150.50');
    await tester.pump();
    expect(find.text('Enter a whole amount'), findsOneWidget);
  });

  testWidgets('swipe deletes; the Undo SnackBar restores and does not linger', (
    tester,
  ) async {
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
    await tester.ensureVisible(find.text('tea'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('tea'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(store.entries.value, isEmpty);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isFalse);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.entries.value.single.note, 'tea');
  });

  testWidgets('a second swipe while the first row shrinks still deletes', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    register();
    await store.add(amount: 1, category: ExpenseCategory.want, note: 'upper');
    await store.add(
      amount: 2,
      category: ExpenseCategory.want,
      note: 'lower',
      date: DateTime(2026, 10, 2),
    );
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.drag(find.text('lower'), const Offset(-600, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250)); // mid-resize
    await tester.drag(find.text('upper'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(store.entries.value, isEmpty);
  });

  testWidgets('a failed swipe-delete puts the row back and drops Undo', (
    tester,
  ) async {
    final prefs = _FailingWrites();
    SharedPreferencesAsyncPlatform.instance = prefs;
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('tea'));
    await tester.pumpAndSettle();
    prefs.fail = true;
    await tester.drag(find.text('tea'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(store.entries.value, hasLength(1));
    expect(find.text('tea'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
  });

  testWidgets('a failed save keeps the sheet open with Save re-enabled', (
    tester,
  ) async {
    final prefs = _FailingWrites();
    SharedPreferencesAsyncPlatform.instance = prefs;
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '120');
    await tester.pump();
    prefs.fail = true;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(store.entries.value, isEmpty);
    prefs.fail = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.entries.value, hasLength(1));
  });
}

base class _FailingWrites extends InMemorySharedPreferencesAsync {
  _FailingWrites() : super.empty();

  bool fail = false;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    if (fail) {
      throw StateError('disk full');
    }
    return super.setString(key, value, options);
  }
}
