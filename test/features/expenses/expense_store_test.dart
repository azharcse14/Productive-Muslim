import 'dart:convert';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/expenses/presentation/state/expense_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 10, 26, 10);
  ExpenseStore store({Locale device = const Locale('en', 'US')}) =>
      ExpenseStore(
        SharedPreferencesAsync(),
        now: () => now,
        deviceLocale: () => device,
      );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

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

  const good =
      '{"id":1,"amount":5,"category":"need",'
      '"date":"2026-10-01T10:00:00.000","note":""}';
  const zakat =
      '{"id":2,"amount":9,"category":"zakat",'
      '"date":"2026-10-02T10:00:00.000","note":""}';
  const sadaqahLater =
      '{"id":3,"amount":4,"category":"zakat2",'
      '"date":"2026-10-03T10:00:00.000","note":""}';

  test(
    'an unreadable record is skipped, kept aside, and survives saves',
    () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('expenses_v1', '[$good,$zakat]');
      final s = store();
      await s.load();
      expect(s.entries.value.map((e) => e.id), [1]);
      await s.add(amount: 7, category: ExpenseCategory.want);
      expect(s.entries.value, hasLength(2), reason: 'history not wiped');
      final kept = await prefs.getString('expenses_v1_unreadable_records');
      expect(kept, contains('zakat'));
    },
  );

  test('a second incident is kept too (not just the first)', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('expenses_v1', '[$good,$zakat]');
    await store().load();
    await prefs.setString('expenses_v1', '[$good,$sadaqahLater]');
    await store().load();
    final kept =
        jsonDecode((await prefs.getString('expenses_v1_unreadable_records'))!)
            as List<dynamic>;
    final categories = [
      for (final r in kept) (jsonDecode(r as String) as Map)['category'],
    ];
    expect(categories, ['zakat', 'zakat2']);
  });

  test('kept records rejoin once readable (re-ided on collision)', () async {
    final prefs = SharedPreferencesAsync();
    // Kept earlier with a category this build reads, e.g. after upgrading.
    const later =
        '{"id":1,"amount":9,"category":"family",'
        '"date":"2026-10-02T10:00:00.000","note":"back"}';
    await prefs.setString('expenses_v1', '[$good]');
    await prefs.setString(
      'expenses_v1_unreadable_records',
      '[${jsonEncode(later)}]',
    );
    final s = store();
    await s.load();
    expect(s.entries.value.map((e) => e.note), containsAll(['', 'back']));
    expect(s.entries.value.map((e) => e.id).toSet(), hasLength(2));
    expect(await prefs.getString('expenses_v1_unreadable_records'), '[]');
    expect(await prefs.getString('expenses_v1'), contains('back'));
  });

  test('a failed load is retried instead of blocking every write', () async {
    final prefs = _FlakyPrefs()..failReads = 1;
    SharedPreferencesAsyncPlatform.instance = prefs;
    final s = store();
    await expectLater(s.load(), throwsStateError);
    await s.add(amount: 10, category: ExpenseCategory.need);
    expect(s.entries.value, hasLength(1));
  });

  test('a failed write rolls back the list and rethrows', () async {
    final prefs = _FlakyPrefs();
    SharedPreferencesAsyncPlatform.instance = prefs;
    final s = store();
    await s.load();
    prefs.failWrites = true;
    await expectLater(
      s.add(amount: 10, category: ExpenseCategory.need),
      throwsStateError,
    );
    expect(s.entries.value, isEmpty, reason: 'never shows unsaved data');
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

    test('pre-decimal data means taka, whatever the device', () async {
      await SharedPreferencesAsync().setString('expenses_v1', '[$good]');
      final s = store();
      await s.ensureCurrency('en');
      expect(s.currency.value, 'BDT');
    });

    test('a failed BDT save defers the rewrite; next load still BDT', () async {
      final prefs = _FlakyPrefs()
        ..failKey = 'expense_currency_v1'
        ..failWriteCount = 1;
      SharedPreferencesAsyncPlatform.instance = prefs;
      const opts = SharedPreferencesOptions();
      await prefs.setString('expenses_v1', '[$good]', opts);
      final first = store();
      await first.ensureCurrency('en');
      expect(first.currency.value, 'BDT');
      expect(first.entries.value.single.amount, 500);
      expect(
        await prefs.getString('expenses_v1', opts),
        isNot(contains('amountMinor')),
        reason: 'legacy evidence kept until BDT is stored',
      );
      final second = store();
      await second.ensureCurrency('en');
      expect(second.currency.value, 'BDT');
      expect(await prefs.getString('expense_currency_v1', opts), 'BDT');
      expect(
        await prefs.getString('expenses_v1', opts),
        contains('amountMinor'),
      );
    });

    test('a legacy budget alone also means taka', () async {
      await SharedPreferencesAsync().setInt('expense_budget_v1', 50);
      final s = store();
      await s.ensureCurrency('en');
      expect(s.currency.value, 'BDT');
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

  group('minor-units migration', () {
    test('legacy records and budgets are ×100, idempotently', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('expenses_v1', '[$good]');
      await prefs.setInt('expense_budget_v1', 5000);
      await prefs.setString(
        'expense_category_budgets_v1',
        jsonEncode({'want': 700}),
      );
      for (var i = 0; i < 2; i++) {
        final s = store();
        await s.load();
        expect(s.entries.value.single.amount, 500);
        expect(s.budget.value, 500000);
        expect(s.categoryBudgets.value, {ExpenseCategory.want: 70000});
      }
      final stored = jsonDecode((await prefs.getString('expenses_v1'))!);
      expect(stored, [containsPair('amountMinor', 500)]);
      expect((stored as List).single, isNot(contains('amount')));
      // The v1 budgets are kept as they were.
      expect(await prefs.getInt('expense_budget_v1'), 5000);
    });

    test('a crash before the marker re-runs from v1, not ×10000', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('expense_budget_v1', 50);
      await store().load();
      await prefs.remove('expense_minor_units_migrated');
      final s = store();
      await s.load();
      expect(s.budget.value, 5000);
    });

    test('a cleared budget stays cleared after reload', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('expense_budget_v1', 50);
      final s = store();
      await s.setBudget(null);
      final fresh = store();
      await fresh.load();
      expect(fresh.budget.value, isNull);
    });

    test('a corrupt payload is kept untouched', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('expenses_v1', '[{not json');
      await prefs.setString('expense_category_budgets_v1', '{bad');
      final s = store();
      await s.load();
      expect(s.entries.value, isEmpty);
      expect(s.categoryBudgets.value, isEmpty);
      expect(await prefs.getString('expenses_v1'), '[{not json');
      expect(await prefs.getString('expense_category_budgets_v1'), '{bad');
      expect(
        await prefs.getString('expenses_v1_unreadable_records'),
        contains('not json'),
      );
    });

    for (final failing in [1, 2, 3]) {
      test('write $failing failing during load loses no record', () async {
        final prefs = _FlakyPrefs();
        SharedPreferencesAsyncPlatform.instance = prefs;
        const opts = SharedPreferencesOptions();
        await prefs.setString('expenses_v1', '[$good,$zakat]', opts);
        prefs.failOnWrite = prefs.writes + failing;
        try {
          await store().load();
        } on StateError {
          // The first write failing fails the load (retried next time).
        }
        final both =
            '${await prefs.getString('expenses_v1', opts)}'
            '${await prefs.getString('expenses_v1_unreadable_records', opts)}';
        expect(both, contains('zakat'));
        expect(both, contains('"id":1'));
      });
    }

    test('a failed legacy rewrite still shows converted amounts', () async {
      final prefs = _FlakyPrefs();
      SharedPreferencesAsyncPlatform.instance = prefs;
      await prefs.setString(
        'expenses_v1',
        '[$good]',
        const SharedPreferencesOptions(),
      );
      prefs.failWriteCount = 1;
      final s = store();
      await s.load();
      expect(s.entries.value.single.amount, 500);
      await s.add(amount: 1, category: ExpenseCategory.need);
      expect(
        await prefs.getString('expenses_v1', const SharedPreferencesOptions()),
        allOf(contains('"amountMinor":500'), isNot(contains('"amount"'))),
      );
    });

    test('a legacy record recovered later is converted too', () async {
      final prefs = SharedPreferencesAsync();
      const legacy =
          '{"id":4,"amount":12,"category":"want",'
          '"date":"2026-10-04T10:00:00.000","note":"old"}';
      await prefs.setString(
        'expenses_v1_unreadable_records',
        '[${jsonEncode(legacy)}]',
      );
      final s = store();
      await s.load();
      expect(s.entries.value.single.amount, 1200);
    });
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
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
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
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
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
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
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

    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
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
        SharedPreferencesAsync(),
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

  const rec7 =
      '{"id":7,"amount":9,"category":"family",'
      '"date":"2026-10-02T10:00:00.000","note":"kept"}';

  test('recovered records survive a failed save during load', () async {
    final prefs = _FlakyPrefs();
    SharedPreferencesAsyncPlatform.instance = prefs;
    await SharedPreferencesAsync().setString(
      'expenses_v1_unreadable_records',
      '[${jsonEncode(rec7)}]',
    );
    prefs.failWriteCount = 1;
    final s = store();
    await expectLater(s.load(), throwsStateError);
    await s.load();
    expect(s.entries.value.map((e) => e.note), ['kept']);
  });

  test('a record both stored and kept aside comes back once', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString('expenses_v1', '[$rec7]');
    await prefs.setString(
      'expenses_v1_unreadable_records',
      '[${jsonEncode(rec7)}]',
    );
    final s = store();
    await s.load();
    expect(s.entries.value.map((e) => e.id), [7]);
    expect(await prefs.getString('expenses_v1_unreadable_records'), '[]');
  });

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

  test('a failed write saved by a later one reports success', () async {
    final prefs = _FlakyPrefs();
    SharedPreferencesAsyncPlatform.instance = prefs;
    final s = store();
    await s.load();
    prefs.failWriteCount = 1;
    final first = s.add(amount: 1, category: ExpenseCategory.need);
    await s.add(amount: 2, category: ExpenseCategory.need);
    await first; // no throw: the later write stored it too
    final stored =
        jsonDecode(
              (await prefs.getString(
                'expenses_v1',
                const SharedPreferencesOptions(),
              ))!,
            )
            as List<dynamic>;
    expect(s.entries.value.map((e) => e.amount).toSet(), {
      for (final j in stored) (j as Map)['amountMinor'],
    }, reason: 'UI shows what is stored');
    expect(stored, hasLength(2));
  });

  test('an unknown budget category is kept, not wiping the rest', () async {
    await SharedPreferencesAsync().setString(
      'expense_category_budgets_v1',
      jsonEncode({'need': 5000, 'zakat': 100}),
    );
    final s = store();
    await s.load();
    // Migrated to minor units, the unknown one included.
    expect(s.categoryBudgets.value, {ExpenseCategory.need: 500000});
    await s.setCategoryBudget(ExpenseCategory.want, 700);
    expect(
      jsonDecode(
        (await SharedPreferencesAsync().getString(
          'expense_category_budgets_v2',
        ))!,
      ),
      {'need': 500000, 'zakat': 10000, 'want': 700},
    );
  });

  test('a failed category-budget write reverts and rethrows', () async {
    final prefs = _FlakyPrefs();
    SharedPreferencesAsyncPlatform.instance = prefs;
    final s = store();
    await s.load();
    prefs.failWrites = true;
    await expectLater(
      s.setCategoryBudget(ExpenseCategory.want, 2000),
      throwsStateError,
    );
    expect(s.categoryBudgets.value, isEmpty);
  });

  test('when the later write fails too, both report failure', () async {
    final prefs = _FlakyPrefs();
    SharedPreferencesAsyncPlatform.instance = prefs;
    final s = store();
    await s.load();
    prefs.failWriteCount = 2;
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

  test(
    'a retried load does not re-add a record it already recovered',
    () async {
      final prefs = _FlakyPrefs();
      SharedPreferencesAsyncPlatform.instance = prefs;
      // The user's own id 7 makes the recovered rec7 move to a new id.
      const mine =
          '{"id":7,"amount":1,"category":"need",'
          '"date":"2026-10-05T10:00:00.000","note":"mine"}';
      await SharedPreferencesAsync().setString('expenses_v1', '[$mine]');
      await SharedPreferencesAsync().setString(
        'expenses_v1_unreadable_records',
        '[${jsonEncode(rec7)}]',
      );
      prefs
        ..failKey = 'expenses_v1_unreadable_records'
        ..failWriteCount = 1;
      final s = store();
      await expectLater(s.load(), throwsStateError);
      await s.load();
      expect(
        s.entries.value.map((e) => e.note),
        unorderedEquals(['mine', 'kept']),
      );
    },
  );
}

/// In-memory prefs that can fail reads (a set number of times) or writes.
base class _FlakyPrefs extends InMemorySharedPreferencesAsync {
  _FlakyPrefs() : super.empty();

  int failReads = 0;
  bool failWrites = false;

  /// setString calls so far; the one numbered [failOnWrite] throws.
  int writes = 0;
  int? failOnWrite;

  /// Fails this many upcoming writes of [failKey], asynchronously like a
  /// platform call.
  int failWriteCount = 0;
  String failKey = 'expenses_v1';

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    if (failReads > 0) {
      failReads--;
      throw StateError('prefs down');
    }
    return super.getString(key, options);
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    if (failWrites || ++writes == failOnWrite) {
      throw StateError('disk full');
    }
    if (failWriteCount > 0 && key == failKey) {
      failWriteCount--;
      return Future<void>.delayed(
        Duration.zero,
      ).then((_) => throw StateError('disk full'));
    }
    return super.setString(key, value, options);
  }
}
