import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/expenses/presentation/state/expense_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 10, 26, 10);
  ExpenseStore store() =>
      ExpenseStore(SharedPreferencesAsync(), now: () => now);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
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
        date: DateTime(2026, 9, 30),
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
        date: DateTime(2026, 9, 5),
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

  test('parseAmount: localized digits and grouping; rejects bad input', () {
    expect(ExpenseStore.parseAmount('১,২০০'), 1200);
    expect(ExpenseStore.parseAmount('150.50'), isNull);
    expect(ExpenseStore.parseAmount('0'), isNull);
    expect(ExpenseStore.parseAmount('9999999999999'), isNull);
    expect(ExpenseStore.parseAmount('0x10'), isNull, reason: 'no hex');
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

  test('a failed write never hides a later one that succeeded', () async {
    final prefs = _FlakyPrefs();
    SharedPreferencesAsyncPlatform.instance = prefs;
    final s = store();
    await s.load();
    prefs.failWriteCount = 1;
    final first = expectLater(
      s.add(amount: 1, category: ExpenseCategory.need),
      throwsStateError,
    );
    await s.add(amount: 2, category: ExpenseCategory.need);
    await first;
    final stored =
        jsonDecode(
              (await prefs.getString(
                'expenses_v1',
                const SharedPreferencesOptions(),
              ))!,
            )
            as List<dynamic>;
    expect(s.entries.value.map((e) => e.amount).toSet(), {
      for (final j in stored) (j as Map)['amount'],
    }, reason: 'UI shows what is stored');
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

  test('import rejects hex amounts and UTC dates', () async {
    final s = store();
    expect(
      await s.importCsv(
        'date,category,amount,note\n2026-10-01T10:00:00.000,need,0x10,""',
      ),
      isNull,
    );
    expect(
      await s.importCsv(
        'date,category,amount,note\n2026-10-31T23:00:00.000Z,need,5,""',
      ),
      isNull,
    );
    expect(s.entries.value, isEmpty);
  });

  test('import tolerates blank lines and a loosely typed header', () async {
    final s = store();
    expect(
      await s.importCsv(
        'Date, Category ,Amount,Note\r\n\r\n'
        '2026-10-01T10:00:00.000,need,5,""\r\n\r\n',
      ),
      1,
    );
  });
}

/// In-memory prefs that can fail reads (a set number of times) or writes.
base class _FlakyPrefs extends InMemorySharedPreferencesAsync {
  _FlakyPrefs() : super.empty();

  int failReads = 0;
  bool failWrites = false;

  /// Fails this many upcoming writes of the expense list, asynchronously
  /// like a platform call.
  int failWriteCount = 0;

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
    if (failWrites) {
      throw StateError('disk full');
    }
    if (failWriteCount > 0 && key == 'expenses_v1') {
      failWriteCount--;
      return Future<void>.delayed(
        Duration.zero,
      ).then((_) => throw StateError('disk full'));
    }
    return super.setString(key, value, options);
  }
}
