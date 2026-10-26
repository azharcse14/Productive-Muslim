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

  test('one unreadable record is skipped, the rest kept, raw backed up',
      () async {
    final prefs = SharedPreferencesAsync();
    const raw = '[{"id":1,"amount":5,"category":"need",'
        '"date":"2026-10-01T10:00:00.000","note":""},'
        '{"id":2,"amount":9,"category":"zakat",'
        '"date":"2026-10-02T10:00:00.000","note":""}]';
    await prefs.setString('expenses_v1', raw);
    final s = store();
    await s.load();
    expect(s.entries.value.map((e) => e.id), [1]);
    await s.add(amount: 7, category: ExpenseCategory.want);
    expect(s.entries.value, hasLength(2), reason: 'history not wiped');
    expect(await prefs.getString('expenses_v1_unreadable'), raw);
  });

  test('a write before load finishes waits for it (no clobbering)',
      () async {
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
}
