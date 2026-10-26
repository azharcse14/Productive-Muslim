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
}
