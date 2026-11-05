import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/expenses/presentation/screens/expense_screen.dart';
import 'package:productive_muslim/features/expenses/presentation/state/expense_store.dart';
import 'package:productive_muslim/shared/widgets/q_chip.dart';

import '../../helpers/tracker_screen_matrix.dart';
import 'fake_expense_repository.dart';

Widget _app({Locale? locale}) => MaterialApp(
  locale: locale,
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const ExpenseScreen(),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ExpenseStore store;
  late FakeExpenseRepository repo;

  void register({Locale device = const Locale('en', 'US')}) {
    store = ExpenseStore(
      repo,
      now: () => DateTime.utc(2026, 10, 26, 10),
      deviceLocale: () => device,
    );
    GetIt.I.registerSingleton<ExpenseStore>(store);
  }

  setUp(() {
    repo = FakeExpenseRepository();
    // Pinned: the default currency (USD here) follows the device locale.
    TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
        const Locale('en', 'US');
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearLocaleTestValue();
    return GetIt.I.reset();
  });

  testWidgets('double-tapping Save adds once and keeps the screen', (
    tester,
  ) async {
    repo.writeDelay = const Duration(milliseconds: 300);
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
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(store.budget.value, 500000, reason: 'minor units');
  });

  testWidgets('editor Delete removes the entry and Undo restores it', (
    tester,
  ) async {
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    // Built lazily below the summary card; scroll it into the tree.
    await tester.scrollUntilVisible(
      find.text('tea'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('tea'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
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
    await add(10000, DateTime.utc(2026, 9, 10));
    await add(
      50000,
      DateTime.utc(2026, 9, 28),
    ); // after "now"'s day: not counted
    await add(8000, DateTime.utc(2026, 10, 26, 9));
    await add(5000, DateTime.utc(2026, 10, 25));
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(find.text(r'$30.00 more than this time last month'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
  });

  testWidgets('day headers count calendar days, not 24h spans (DST)', (
    tester,
  ) async {
    // US clocks spring forward on Mar 8 2026: midnight-to-midnight is 23h,
    // so a duration diff called yesterday "Today" (run with
    // TZ=America/New_York to exercise it).
    store = ExpenseStore(repo, now: () => DateTime.utc(2026, 3, 9, 10));
    GetIt.I.registerSingleton<ExpenseStore>(store);
    await store.add(
      amount: 50,
      category: ExpenseCategory.want,
      date: DateTime.utc(2026, 3, 8, 12),
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
    final added = store.entries.value.firstWhere((e) => e.amount == 5000);
    expect((added.note, added.category), ('Gift', ExpenseCategory.family));
  });

  testWidgets('three decimals show an error instead of silently failing', (
    tester,
  ) async {
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '150.505');
    await tester.pump();
    expect(
      find.text(
        'Enter an amount above 0, up to 2 decimals (e.g. 250 or 12.50)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('entering 12.50 saves 1250 minor units and shows \$12.50', (
    tester,
  ) async {
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '12.50');
    await tester.enterText(find.byType(TextField).at(1), 'lunch');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.entries.value.single.amount, 1250);
    await tester.scrollUntilVisible(
      find.text('lunch'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'lunch'),
        matching: find.text(r'$12.50'),
      ),
      findsOneWidget,
    );
    // Editing shows it back as typed.
    await tester.tap(find.text('lunch'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '12.50'), findsOneWidget);
  });

  testWidgets('Bangla on a BD phone shows taka in Bangla digits', (
    tester,
  ) async {
    register(device: const Locale('bn', 'BD'));
    await store.add(amount: 1250, category: ExpenseCategory.need, note: 'x');
    await tester.pumpWidget(_app(locale: const Locale('bn')));
    await tester.pumpAndSettle();
    expect(store.currency.value, 'BDT');
    final amount = find.descendant(
      of: find.widgetWithText(ListTile, 'x'),
      matching: find.textContaining('১২.৫০'),
    );
    await tester.scrollUntilVisible(
      find.text('x'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(amount, findsOneWidget);
    expect(tester.widget<Text>(amount).data, contains('৳'));
  });

  testWidgets('the currency picker switches the display currency', (
    tester,
  ) async {
    register();
    await store.add(amount: 1250, category: ExpenseCategory.need);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('EUR'));
    await tester.pumpAndSettle();
    expect(store.currency.value, 'EUR');
    expect(find.text('€12.50'), findsWidgets);
  });

  testWidgets('swipe deletes; the Undo SnackBar restores and does not linger', (
    tester,
  ) async {
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
    // Built lazily below the summary card; scroll it into the tree.
    await tester.scrollUntilVisible(
      find.text('tea'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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
      date: DateTime.utc(2026, 10, 2),
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
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    // Built lazily below the summary card; scroll it into the tree.
    await tester.scrollUntilVisible(
      find.text('tea'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    repo.failWrites = true;
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
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '120');
    await tester.pump();
    repo.failWrites = true;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(store.entries.value, isEmpty);
    repo.failWrites = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.entries.value, hasLength(1));
  });

  testWidgets('a failed CSV restore shows an error snackbar', (tester) async {
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? {
              'text':
                  'date,category,amount,note\n'
                  '2026-10-01T10:00:00.000,need,5,"x"',
            }
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    repo.failWrites = true;
    await tester.tap(find.byTooltip('Backup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore from copied CSV'));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't restore the backup. Please try again."),
      findsOneWidget,
    );
    expect(store.entries.value, isEmpty);
  });

  testWidgets('a filter with no entries offers Show all', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family').first);
    await tester.pumpAndSettle();
    expect(find.text('No Family entries this month.'), findsOneWidget);
    expect(find.text('tea'), findsNothing);

    await tester.ensureVisible(find.widgetWithText(QChip, 'Show all'));
    await tester.tap(find.widgetWithText(QChip, 'Show all'));
    await tester.pumpAndSettle();
    // Built lazily below the summary card; scroll it into the tree.
    await tester.scrollUntilVisible(
      find.text('tea'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('tea'), findsOneWidget);
  });

  testWidgets('category pencil opens its budget dialog; Save waits for input', (
    tester,
  ) async {
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Wants budget'));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(TextButton, 'Save');
    expect(tester.widget<TextButton>(save).onPressed, isNull);
    await tester.enterText(find.byType(TextField), '900');
    await tester.pump();
    expect(tester.widget<TextButton>(save).onPressed, isNotNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.categoryBudgets.value[ExpenseCategory.want], isNull);
  });

  testWidgets('a new entry is stamped when saved, not when the sheet opened', (
    tester,
  ) async {
    var clock = DateTime.utc(2026, 10, 26, 10);
    store = ExpenseStore(repo, now: () => clock);
    GetIt.I.registerSingleton<ExpenseStore>(store);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '120');
    await tester.pump();
    clock = DateTime.utc(2026, 10, 26, 10, 45);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.entries.value.single.date, DateTime.utc(2026, 10, 26, 10, 45));
  });

  testWidgets('re-dating an evening entry to today never lands after now', (
    tester,
  ) async {
    register(); // now = Oct 26, 10:00
    await store.add(
      amount: 80,
      category: ExpenseCategory.want,
      note: 'tea',
      date: DateTime.utc(2026, 10, 25, 21, 30),
    );
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('tea'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('tea'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('26'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(store.entries.value.single.date, DateTime.utc(2026, 10, 26, 10));
  });

  testWidgets('re-dating a morning entry to today keeps its wall time', (
    tester,
  ) async {
    register(); // now = Oct 26, 10:00 (floating)
    await store.add(
      amount: 80,
      category: ExpenseCategory.want,
      note: 'tea',
      date: DateTime.utc(2026, 10, 25, 8),
    );
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('tea'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('tea'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('26'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    // Not clamped by a device-offset comparison, and stored floating.
    expect(store.entries.value.single.date, DateTime.utc(2026, 10, 26, 8));
  });

  testWidgets('the editor close button asks before dropping an amount', (
    tester,
  ) async {
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '120');
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(store.entries.value, isEmpty);
  });

  testWidgets('category rows are buttons that say what a tap does', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final handle = tester.ensureSemantics();
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(find.text('Wants').first),
      isSemantics(
        isButton: true,
        hasTapAction: true,
        onTapHint: 'show only this category',
      ),
    );
    handle.dispose();
  });

  group('polish matrix', () {
    setUp(() async {
      register();
      await store.setBudget(500000);
      await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
      await store.add(
        amount: 12500,
        category: ExpenseCategory.need,
        note: 'Groceries for the whole week at the bazaar',
      );
    });
    screenMatrix('ExpenseScreen', () => const ExpenseScreen());
    screenMatrix(
      'ExpenseScreen editor',
      () => const ExpenseScreen(),
      afterPump: (tester) async {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget);
      },
    );
  });
}
