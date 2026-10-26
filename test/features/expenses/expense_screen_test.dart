import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/expenses/presentation/screens/expense_screen.dart';
import 'package:productive_muslim/features/expenses/presentation/state/expense_store.dart';
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

  testWidgets('double-tapping Save adds once and keeps the screen',
      (tester) async {
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

  testWidgets('budget dialog saves without a disposed-controller error',
      (tester) async {
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

  testWidgets('editor Delete removes the entry and Undo restores it',
      (tester) async {
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
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

  testWidgets('a decimal amount shows an error instead of silently failing',
      (tester) async {
    register();
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '150.50');
    await tester.pump();
    expect(find.text('Enter a whole amount'), findsOneWidget);
  });

  testWidgets('swipe deletes; the Undo SnackBar restores and does not linger',
      (tester) async {
    register();
    await store.add(amount: 80, category: ExpenseCategory.want, note: 'tea');
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.drag(find.text('tea'), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(store.entries.value, isEmpty);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isFalse);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.entries.value.single.note, 'tea');
  });

  testWidgets('a failed save keeps the sheet open with Save re-enabled',
      (tester) async {
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
