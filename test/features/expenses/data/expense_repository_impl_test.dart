import 'dart:convert';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/expenses/data/expense_repository_impl.dart';
import 'package:productive_muslim/features/expenses/data/legacy_expense_import.dart';
import 'package:productive_muslim/features/expenses/domain/entities/expense.dart';
import 'package:productive_muslim/features/expenses/domain/repositories/expense_repository.dart';
import 'package:productive_muslim/features/muhasaba/data/database/muhasaba_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late MuhasabaDatabase db;
  late SharedPreferencesAsync prefs;
  ExpenseRepositoryImpl repo() => ExpenseRepositoryImpl(db, prefs);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
    db = MuhasabaDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<ExpenseData> load() async => switch (await repo().load()) {
    Success(:final value) => value,
    FailureResult(:final failure) => fail(failure.message),
  };

  final day = DateTime.utc(2026, 10, 1, 10);

  test('round-trip: save, replace, delete, budgets, currency', () async {
    final r = repo();
    final a = Expense(
      id: 1,
      amount: 1250,
      category: ExpenseCategory.need,
      date: day,
      note: 'rice, "basmati"',
    );
    final b = Expense(
      id: 2,
      amount: 99,
      category: ExpenseCategory.sadaqah,
      date: day.add(const Duration(days: 1, microseconds: 7)),
    );
    expect((await r.save([a, b])).isSuccess, isTrue);
    expect((await r.save([a.withId(2)])).isSuccess, isTrue, reason: 'replace');
    await r.save([b.withId(3)]);
    await r.delete(1);
    await r.setBudget(5000);
    await r.setCategoryBudget(ExpenseCategory.want, 700);
    await r.setCategoryBudget(ExpenseCategory.need, 100);
    await r.setCategoryBudget(ExpenseCategory.need, null);
    await r.setCurrency('SAR');

    final data = await load();
    expect(data.expenses.map((e) => e.id), [3, 2], reason: 'newest first');
    expect(data.expenses.last.fields, a.fields);
    expect(data.expenses.first.fields, b.fields);
    expect(data.expenses.first.date.isUtc, isTrue);
    expect(data.budget, 5000);
    expect(data.categoryBudgets, {ExpenseCategory.want: 700});
    expect(data.currency, 'SAR');

    await r.setBudget(null);
    expect((await load()).budget, isNull);
  });

  test('rows of an unknown category stay stored, unshown', () async {
    await db.customStatement(
      "INSERT INTO expenses VALUES (9, 5, 'zakat', 0, '')",
    );
    await db.customStatement("INSERT INTO expense_budgets VALUES ('zakat', 5)");
    final data = await load();
    expect(data.expenses, isEmpty);
    expect(data.categoryBudgets, isEmpty);
    expect(data.maxId, 9, reason: 'new ids must go above hidden rows');
  });

  group('legacy import', () {
    const good =
        '{"id":1,"amountMinor":550,"category":"need",'
        '"date":"2026-10-01T10:00:00.000","note":"rice"}';
    const legacy =
        '{"id":2,"amount":5,"category":"want",'
        '"date":"2026-10-02T10:00:00.000","note":""}';
    const zakat =
        '{"id":3,"amount":9,"category":"zakat",'
        '"date":"2026-10-03T10:00:00.000","note":""}';

    Future<Set<String>> keys() => prefs.getKeys();

    test('nothing stored: empty, no keys written', () async {
      final data = await load();
      expect(data.expenses, isEmpty);
      expect(data.budget, isNull);
      expect(data.currency, isNull);
      expect(await keys(), isEmpty);
    });

    test('v2 data moves into the tables; old keys removed', () async {
      await prefs.setString('expenses_v1', '[$good]');
      await prefs.setBool('expense_minor_units_migrated', true);
      await prefs.setInt('expense_budget_v2', 90000);
      await prefs.setString(
        'expense_category_budgets_v2',
        jsonEncode({'sadaqah': 500, 'zakat': 100}),
      );
      await prefs.setString('expense_currency_v1', 'USD');
      // Ignored once migrated.
      await prefs.setInt('expense_budget_v1', 1);

      final data = await load();
      final e = data.expenses.single;
      expect(
        (e.id, e.amount, e.category, e.note),
        (1, 550, ExpenseCategory.need, 'rice'),
      );
      expect(e.date, DateTime.utc(2026, 10, 1, 10), reason: 'floating');
      expect(data.budget, 90000);
      expect(data.categoryBudgets, {ExpenseCategory.sadaqah: 500});
      expect(data.currency, 'USD');
      expect(await keys(), {'expense_currency_v1'});
      // The unknown category's budget is kept as a row.
      final rows = await db.select(db.expenseBudgets).get();
      expect(rows.map((r) => r.key), contains('zakat'));
      // Idempotent: a second load changes nothing.
      expect((await load()).expenses, hasLength(1));
    });

    test('whole-unit records and v1 budgets are x100; means taka', () async {
      await prefs.setString('expenses_v1', '[$good,$legacy]');
      await prefs.setInt('expense_budget_v1', 50);
      await prefs.setString(
        'expense_category_budgets_v1',
        jsonEncode({'want': 7}),
      );
      final data = await load();
      expect(data.expenses.map((e) => e.amount), [500, 550]);
      expect(data.budget, 5000);
      expect(data.categoryBudgets, {ExpenseCategory.want: 700});
      expect(data.currency, 'BDT');
    });

    test('a legacy budget alone also means taka; a set one is kept', () async {
      await prefs.setInt('expense_budget_v1', 50);
      expect((await load()).currency, 'BDT');
      await prefs.setString('expense_currency_v1', 'EUR');
      await prefs.setString('expenses_v1', '[$legacy]');
      expect((await load()).currency, 'EUR');
    });

    test(
      'corrupt records and payloads are kept aside, rest imported',
      () async {
        await prefs.setString('expenses_v1', '[$good,$zakat]');
        await prefs.setString('expense_category_budgets_v1', '{bad');
        final data = await load();
        expect(data.expenses.map((e) => e.id), [1]);
        expect(data.categoryBudgets, isEmpty);
        final kept =
            (jsonDecode((await prefs.getString(unimportedExpensesKey))!)
                    as List)
                .cast<String>();
        expect(kept, hasLength(2));
        expect(kept.first, contains('"zakat"'));
        expect(kept.last, '{bad');
        expect(await keys(), {unimportedExpensesKey, 'expense_currency_v1'});

        await prefs.setString('expenses_v1', '[{not json');
        await load();
        expect(
          await prefs.getString(unimportedExpensesKey),
          allOf(contains('zakat'), contains('not json')),
          reason: 'appended, never overwritten',
        );
      },
    );

    test(
      'records kept aside earlier are retried, re-ided on a clash',
      () async {
        const back =
            '{"id":1,"amountMinor":9,"category":"family",'
            '"date":"2026-10-05T10:00:00.000","note":"back"}';
        await prefs.setString('expenses_v1', '[$good]');
        await prefs.setString(
          'expenses_v1_unreadable_records',
          jsonEncode([back, good, legacy, zakat]),
        );
        final data = await load();
        expect(
          {for (final e in data.expenses) e.note: e.id},
          {'rice': 1, 'back': 2, '': 3},
          reason: 'a record both stored and kept aside comes back once',
        );
        expect(
          data.expenses.firstWhere((e) => e.id == 3).amount,
          500,
          reason: 'a recovered legacy record is converted too',
        );
        expect(await prefs.getString(unimportedExpensesKey), contains('zakat'));
      },
    );

    test('a non-string kept-aside element is set aside alone', () async {
      await prefs.setString(
        'expenses_v1_unreadable_records',
        jsonEncode([good, 42, '{not json']),
      );
      final data = await load();
      expect(data.expenses.map((e) => e.id), [1]);
      expect(
        (jsonDecode((await prefs.getString(unimportedExpensesKey))!) as List)
            .cast<String>(),
        ['42', '{not json'],
        reason: 'the imported record is not also kept for recovery',
      );
    });

    test('a failed import keeps the prefs and is retried', () async {
      await prefs.setString('expenses_v1', '[$good]');
      await db.customStatement('DROP TABLE expenses');
      expect((await repo().load()).isSuccess, isFalse);
      expect(await prefs.getString('expenses_v1'), isNotNull);
      await db.customStatement(
        'CREATE TABLE expenses (id INTEGER NOT NULL PRIMARY KEY, '
        'amount INTEGER NOT NULL, category TEXT NOT NULL, '
        'date INTEGER NOT NULL, note TEXT NOT NULL)',
      );
      expect((await load()).expenses, hasLength(1));
      expect(await keys(), isEmpty);
    });

    test('a re-run after the commit only removes the leftover keys', () async {
      // An earlier run committed (id 1 is the kept-aside record, re-ided
      // to 2 there) but failed removing the kept-aside key.
      const back =
          '{"id":1,"amountMinor":9,"category":"family",'
          '"date":"2026-10-05T10:00:00.000","note":"back"}';
      await db.customStatement(
        "INSERT INTO expenses VALUES (1, 550, 'need', 0, 'rice'), "
        "(2, 9, 'family', 0, 'back')",
      );
      await prefs.setString(
        'expenses_v1_unreadable_records',
        jsonEncode([back]),
      );
      final data = await load();
      expect(
        {for (final e in data.expenses) e.id: e.note},
        {1: 'rice', 2: 'back'},
        reason: 'expense 1 must not be replaced by the kept-aside record',
      );
      expect(await keys(), isEmpty);
    });

    test('a category budget that is not a number is kept aside', () async {
      await prefs.setBool('expense_minor_units_migrated', true);
      await prefs.setString(
        'expense_category_budgets_v2',
        jsonEncode({'need': 5000, 'want': '12'}),
      );
      final data = await load();
      expect(data.categoryBudgets, {ExpenseCategory.need: 5000});
      expect(await prefs.getString(unimportedExpensesKey), contains('want'));
    });
  });
}
