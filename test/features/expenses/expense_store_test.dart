import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/expenses/presentation/state/expense_store.dart';

import 'fake_expense_repository.dart';

void main() {
  final now = DateTime.utc(2026, 10, 26, 10);
  late FakeExpenseRepository repo;
  ExpenseStore store({Locale device = const Locale('en', 'US')}) =>
      ExpenseStore(repo, now: () => now, deviceLocale: () => device);

  setUp(() => repo = FakeExpenseRepository());

  test('spendingOf leaves sadaqah out of spending', () {
    Expense e(int amount, ExpenseCategory c) =>
        Expense(id: 0, amount: amount, category: c, date: now);
    expect(
      ExpenseStore.spendingOf([
        e(500, ExpenseCategory.need),
        e(1000, ExpenseCategory.sadaqah),
        e(200, ExpenseCategory.want),
      ]),
      700,
    );
    expect(ExpenseStore.spendingOf([e(50, ExpenseCategory.sadaqah)]), 0);
  });

  test(
    'add/remove, monthly totals per category, persists across loads',
    () async {
      final s = store();
      await s.load();
      await s.add(amount: 500, category: ExpenseCategory.need);
      await s.add(
        amount: 200,
        category: ExpenseCategory.sadaqah,
        note: ' zakat ',
      );
      await s.add(amount: 300, category: ExpenseCategory.need);
      await s.add(
        amount: 999,
        category: ExpenseCategory.want,
        date: DateTime.utc(2026, 9, 30),
      );
      await s.add(amount: 0, category: ExpenseCategory.want);

      final totals = s.totalsFor(s.month());
      expect(totals[ExpenseCategory.need], 800);
      expect(totals[ExpenseCategory.sadaqah], 200);
      expect(totals[ExpenseCategory.want], 0);
      expect(s.totalsFor(s.month(-1))[ExpenseCategory.want], 999);
      expect(s.entries.value.where((e) => e.note == 'zakat'), hasLength(1));

      final fresh = store();
      await fresh.load();
      expect(fresh.entries.value, hasLength(4));

      await fresh.remove(fresh.entries.value.last.id);
      expect(fresh.inMonth(fresh.month(-1)), isEmpty);
    },
  );

  test(
    'update moves an entry to a new date; budget persists and clears',
    () async {
      final s = store();
      await s.load();
      await s.add(amount: 100, category: ExpenseCategory.need);
      final id = s.entries.value.single.id;
      await s.update(
        id,
        amount: 150,
        category: ExpenseCategory.family,
        date: DateTime.utc(2026, 9, 5),
      );
      expect(s.inMonth(s.month()), isEmpty);
      expect(s.totalsFor(s.month(-1))[ExpenseCategory.family], 150);

      await s.setBudget(5000);
      final fresh = store();
      await fresh.load();
      expect(fresh.budget.value, 5000);
      await fresh.setBudget(0);
      expect(fresh.budget.value, isNull);
      final again = store();
      await again.load();
      expect(again.budget.value, isNull);
    },
  );

  test('category budgets persist independently and clear', () async {
    final s = store();
    await s.load();
    await s.setCategoryBudget(ExpenseCategory.want, 2000);
    await s.setCategoryBudget(ExpenseCategory.sadaqah, 500);
    await s.setCategoryBudget(ExpenseCategory.want, null);

    final fresh = store();
    await fresh.load();
    expect(fresh.categoryBudgets.value, {ExpenseCategory.sadaqah: 500});
  });

  test('a failed load is retried instead of blocking every write', () async {
    repo.failLoads = 1;
    final s = store();
    await expectLater(s.load(), throwsStateError);
    await s.add(amount: 10, category: ExpenseCategory.need);
    expect(s.entries.value, hasLength(1));
  });

  test('a failed write rolls back the list and rethrows', () async {
    final s = store();
    await s.load();
    repo.failWrites = true;
    await expectLater(
      s.add(amount: 10, category: ExpenseCategory.need),
      throwsStateError,
    );
    expect(s.entries.value, isEmpty, reason: 'never shows unsaved data');
  });

  test('a failed remove or update puts the old entry back', () async {
    final s = store();
    await s.add(amount: 10, category: ExpenseCategory.need, note: 'a');
    final e = s.entries.value.single;
    repo.failWrites = true;
    await expectLater(s.remove(e.id), throwsStateError);
    expect(s.entries.value.single.note, 'a');
    await expectLater(
      s.update(e.id, amount: 20, category: e.category, date: e.date),
      throwsStateError,
    );
    expect(s.entries.value.single.amount, 10);
  });

  test('a failed write undoes only itself, not a later saved one', () async {
    final s = store();
    await s.load();
    repo
      ..writeDelay = const Duration(milliseconds: 5)
      ..failWriteCount = 1;
    final first = expectLater(
      s.add(amount: 1, category: ExpenseCategory.need),
      throwsStateError,
    );
    await s.add(amount: 2, category: ExpenseCategory.need);
    await first;
    expect(s.entries.value.map((e) => e.amount), [2]);
    expect(repo.rows.values.map((e) => e.amount), [2], reason: 'UI = stored');
  });

  test('when the later write fails too, both report failure', () async {
    final s = store();
    await s.load();
    repo.failWriteCount = 2;
    final first = expectLater(
      s.add(amount: 1, category: ExpenseCategory.need),
      throwsStateError,
    );
    await expectLater(
      s.add(amount: 2, category: ExpenseCategory.need),
      throwsStateError,
    );
    await first;
    expect(s.entries.value, isEmpty);
  });

  test('a failed category-budget write reverts and rethrows', () async {
    final s = store();
    await s.load();
    repo.failWrites = true;
    await expectLater(
      s.setCategoryBudget(ExpenseCategory.want, 2000),
      throwsStateError,
    );
    expect(s.categoryBudgets.value, isEmpty);
  });

  test('undo after a later add reuses no id — both entries kept', () async {
    final s = store();
    await s.add(amount: 30, category: ExpenseCategory.family, note: 'A');
    final a = s.entries.value.single;
    await s.remove(a.id);
    await s.add(amount: 40, category: ExpenseCategory.want, note: 'B');
    await s.restore(a);
    expect(s.entries.value.map((e) => e.note), containsAll(['A', 'B']));
    expect(s.entries.value.map((e) => e.id).toSet(), hasLength(2));
  });

  test('a write before load finishes waits for it (no clobbering)', () async {
    final first = store();
    await first.load();
    await first.add(amount: 100, category: ExpenseCategory.need);
    final s = store(); // fresh: nothing loaded yet
    await s.add(amount: 50, category: ExpenseCategory.want);
    expect(s.entries.value.map((e) => e.amount), containsAll([100, 50]));
  });

  test('parseAmount: minor units from decimals, digits, separators', () {
    expect(ExpenseStore.parseAmount('১,২০০'), 120000);
    expect(ExpenseStore.parseAmount('150.50'), 15050);
    expect(ExpenseStore.parseAmount('12.5'), 1250);
    expect(ExpenseStore.parseAmount('12,50'), 1250, reason: 'decimal comma');
    expect(ExpenseStore.parseAmount('১২.৫০'), 1250);
    expect(ExpenseStore.parseAmount('1,234.56'), 123456);
    expect(ExpenseStore.parseAmount('1.234,56'), 123456);
    expect(ExpenseStore.parseAmount('.5'), 50);
    expect(ExpenseStore.parseAmount('12.'), 1200);
    expect(ExpenseStore.parseAmount(' 0.01 '), 1);
    expect(ExpenseStore.parseAmount('1.005'), isNull, reason: '3 decimals');
    expect(ExpenseStore.parseAmount('0'), isNull);
    expect(ExpenseStore.parseAmount('0.00'), isNull);
    expect(ExpenseStore.parseAmount('.'), isNull);
    expect(ExpenseStore.parseAmount('-5'), isNull);
    expect(ExpenseStore.parseAmount('999999999999.99'), ExpenseStore.maxAmount);
    expect(ExpenseStore.parseAmount('1000000000000'), isNull);
    expect(ExpenseStore.parseAmount('9' * 30), isNull);
    expect(ExpenseStore.parseAmount('0x10'), isNull, reason: 'no hex');
  });

  test('amountText and formatAmount', () {
    expect(ExpenseStore.amountText(1250), '12.50');
    expect(ExpenseStore.amountText(1205), '12.05');
    expect(ExpenseStore.amountText(1200), '12');
    expect(ExpenseStore.formatAmount(1250, 'USD', 'en'), r'$12.50');
    expect(ExpenseStore.formatAmount(120000, 'USD', 'en'), r'$1,200.00');
    expect(ExpenseStore.formatAmount(1250, 'BDT', 'bn'), contains('১২.৫০'));
    expect(ExpenseStore.formatAmount(1250, 'BDT', 'bn'), contains('৳'));
    expect(ExpenseStore.formatAmount(1250, 'EUR', 'en'), contains('€'));
  });

  test('currencyFor: region, then Bangla, then intl, then USD', () {
    String f(Locale l, [String app = 'en']) => ExpenseStore.currencyFor(l, app);
    expect(f(const Locale('en', 'BD')), 'BDT', reason: 'intl says USD');
    expect(f(const Locale('bn', 'IN')), 'INR', reason: 'region first');
    expect(f(const Locale('en', 'DE')), 'EUR');
    expect(f(const Locale('en')), 'USD');
    expect(f(const Locale('en'), 'bn'), 'BDT');
    expect(f(const Locale('bn')), 'BDT');
    expect(f(const Locale('ja', 'JP')), 'JPY', reason: 'via intl');
    expect(f(const Locale('xx', 'YY')), 'USD');
  });

  group('ensureCurrency', () {
    test('stores the device-region default once (en-BD → BDT)', () async {
      final s = store(device: const Locale('en', 'BD'));
      await s.ensureCurrency('en');
      expect(s.currency.value, 'BDT');
      // Persisted: a later device/app language change doesn't move it.
      final fresh = store();
      await fresh.ensureCurrency('en');
      expect(fresh.currency.value, 'BDT');
    });

    test('a chosen currency is kept', () async {
      final s = store();
      await s.setCurrency('SAR');
      final fresh = store(device: const Locale('en', 'BD'));
      await fresh.ensureCurrency('bn');
      expect(fresh.currency.value, 'SAR');
    });

    test('no legacy data: device default (en-US → USD)', () async {
      final s = store();
      await s.ensureCurrency('en');
      expect(s.currency.value, 'USD');
    });
  });

  test('currency persists across loads', () async {
    final s = store();
    await s.load();
    expect(s.currency.value, isNull);
    await s.setCurrency('SAR');
    final fresh = store();
    await fresh.load();
    expect(fresh.currency.value, 'SAR');
  });

  test('CSV: old whole-number and new decimal files both import', () async {
    final s = store();
    const old =
        'date,category,amount,note\n'
        '2026-10-01T10:00:00.000,need,120,"rice"';
    const decimal =
        'date,category,amount,note\n'
        '2026-10-02T10:00:00.000,want,12.50,"tea"';
    expect(await s.importCsv(old), 1);
    expect(await s.importCsv(decimal), 1);
    expect(s.entries.value.map((e) => e.amount), [1250, 12000]);
    final csv = await s.toCsv();
    expect(csv, contains(',need,120,'));
    expect(csv, contains(',want,12.50,'));
    expect(await s.importCsv(csv), 0, reason: 'same entries');
    repo = FakeExpenseRepository();
    final restored = store();
    expect(await restored.importCsv(csv), 2);
    expect(restored.entries.value.map((e) => e.amount), [1250, 12000]);
    expect(
      await restored.importCsv(
        'date,category,amount,note\n2026-10-03T10:00:00.000,need,1.005,""',
      ),
      isNull,
    );
  });

  test('restore puts a removed entry back unchanged', () async {
    final s = store();
    await s.add(amount: 30, category: ExpenseCategory.family, note: 'x');
    final e = s.entries.value.single;
    await s.remove(e.id);
    await s.restore(e);
    expect(s.entries.value.single.id, e.id);
    expect(s.entries.value.single.note, 'x');
  });

  test('CSV neutralises formula notes and round-trips them', () async {
    final first = store();
    for (final note in ['=HYPERLINK("x")', '+1', "'=already"]) {
      await first.add(amount: 1, category: ExpenseCategory.need, note: note);
    }
    final csv = await first.toCsv();
    expect(csv, contains('"\'=HYPERLINK'));
    expect(csv, contains('"\'+1"'));
    repo = FakeExpenseRepository();
    final restored = store();
    expect(await restored.importCsv(csv), 3);
    expect(
      restored.entries.value.map((e) => e.note),
      containsAll(['=HYPERLINK("x")', '+1', "'=already"]),
    );
  });

  test('CSV neutralises notes starting with tab or CR', () async {
    final first = store();
    // Notes are trimmed on add, so these can only arrive via import.
    const csv =
        'date,category,amount,note\n'
        '2026-10-01T10:00:00.000,need,1,"\t=x"\n'
        '2026-10-02T10:00:00.000,need,1,"\r=y"';
    expect(await first.importCsv(csv), 2);
    final out = await first.toCsv();
    expect(out, contains('"\'\t=x"'));
    expect(out, contains('"\'\r=y"'));
    repo = FakeExpenseRepository();
    final restored = store();
    expect(await restored.importCsv(out), 2);
    expect(
      restored.entries.value.map((e) => e.note),
      containsAll(['\t=x', '\r=y']),
    );
  });

  test('CSV round-trips; import before load merges, never clobbers', () async {
    final first = store();
    await first.add(
      amount: 100,
      category: ExpenseCategory.need,
      note: 'a, "b"',
    );
    await first.add(
      amount: 50,
      category: ExpenseCategory.sadaqah,
      date: now.subtract(const Duration(days: 1)),
    );
    final csv = await first.toCsv();

    final s = store(); // fresh: nothing loaded yet
    expect(await s.importCsv(csv), 0, reason: 'same entries already stored');
    expect(s.entries.value, hasLength(2));
    expect(s.entries.value.map((e) => e.note), contains('a, "b"'));

    repo = FakeExpenseRepository();
    final restored = store();
    expect(await restored.importCsv(csv), 2);
    expect(await restored.toCsv(), csv);
  });

  test('importCsv rejects amounts above maxAmount', () async {
    final s = store();
    const csv =
        'date,category,amount,note\n2026-10-01T10:00:00.000,need,'
        '${ExpenseStore.maxAmount + 1},""';
    expect(await s.importCsv(csv), isNull);
    expect(s.entries.value, isEmpty);
  });

  test(
    'onSadaqah: failure keeps the save; fires only on real changes',
    () async {
      final marked = <DateTime>[];
      var fail = true;
      final s = ExpenseStore(
        repo,
        now: () => now,
        onSadaqah: (d) async {
          if (fail) throw StateError('muhasaba down');
          marked.add(d);
        },
      );
      await s.add(amount: 10, category: ExpenseCategory.sadaqah);
      expect(s.entries.value, hasLength(1), reason: 'saved despite hook error');

      fail = false;
      final e = s.entries.value.single;
      await s.update(e.id, amount: 20, category: e.category, date: e.date);
      expect(marked, isEmpty, reason: 'same day and category: no re-tick');

      await s.update(
        99,
        amount: 5,
        category: ExpenseCategory.sadaqah,
        date: now,
      );
      expect(marked, isEmpty, reason: 'unknown id: nothing to mark');

      final later = now.add(const Duration(days: 1));
      await s.update(e.id, amount: 20, category: e.category, date: later);
      expect(marked, [later]);
    },
  );

  test(
    'restore of an entry still present (failed remove) is a no-op',
    () async {
      final s = store();
      await s.add(amount: 30, category: ExpenseCategory.need);
      final e = s.entries.value.single;
      await s.restore(e);
      expect(s.entries.value, hasLength(1));
    },
  );

  test('import keeps identical rows; re-import adds nothing', () async {
    final s = store();
    const csv =
        'date,category,amount,note\n'
        '2026-10-01T10:00:00.000,need,50,"tea"\n'
        '2026-10-01T10:00:00.000,need,50,"tea"';
    expect(await s.importCsv(csv), 2);
    expect(await s.importCsv(csv), 0);
    expect(s.entries.value, hasLength(2));
  });

  test('import rejects hex amounts', () async {
    final s = store();
    expect(
      await s.importCsv(
        'date,category,amount,note\n2026-10-01T10:00:00.000,need,0x10,""',
      ),
      isNull,
    );
    expect(s.entries.value, isEmpty);
  });

  test('import reads old (local) and new (floating) backups alike', () async {
    final s = store();
    // A new backup's floating time keeps its wall-clock fields.
    expect(
      await s.importCsv(
        'date,category,amount,note\n2026-10-31T23:00:00.000Z,need,5,""',
      ),
      1,
    );
    expect(s.entries.value.single.date, DateTime.utc(2026, 10, 31, 23));
    // The same entry from an old device-local backup is a duplicate.
    expect(
      await s.importCsv(
        'date,category,amount,note\n2026-10-31T23:00:00.000,need,5,""',
      ),
      0,
    );
  });

  test('import tolerates blank lines and a loosely typed header', () async {
    final s = store();
    expect(
      await s.importCsv(
        'Date, Category ,Amount,Note\r\n\r\n'
        '2026-10-01T10:00:00.000,need,5,""\r\n,,,\r\n\r\n',
      ),
      1,
    );
  });
}
