import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/result.dart';
import '../domain/entities/expense.dart';
import '../domain/repositories/expense_repository.dart';
import 'legacy_expense_import.dart';

/// [ExpenseRepository] over the user database's `expenses` and
/// `expense_budgets` tables (declared in `MuhasabaDatabase`, which owns
/// the schema and its migrations). Plain SQL on a [GeneratedDatabase] so
/// this feature never imports another feature's data layer. The currency
/// stays in prefs.
final class ExpenseRepositoryImpl implements ExpenseRepository {
  const ExpenseRepositoryImpl(this._db, this._prefs);

  final GeneratedDatabase _db;
  final SharedPreferencesAsync _prefs;

  static const _total = 'total';

  Future<Result<T>> _guard<T>(String what, Future<T> Function() run) async {
    try {
      return Result.success(await run());
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Expenses: $what failed', e));
    }
  }

  @override
  Future<Result<ExpenseData>> load() => _guard('load', () async {
    await importLegacyExpenses(_db, _prefs);
    final byName = ExpenseCategory.values.asNameMap();
    final rows = await _db
        .customSelect(
          'SELECT id, amount, category, date, note FROM expenses '
          'ORDER BY date DESC, id DESC',
        )
        .get();
    final budgets = await _db
        .customSelect('SELECT key, amount FROM expense_budgets')
        .get();
    int? budget;
    final categoryBudgets = <ExpenseCategory, int>{};
    for (final r in budgets) {
      final key = r.read<String>('key');
      if (key == _total) {
        budget = r.read<int>('amount');
      } else if (byName[key] case final c?) {
        categoryBudgets[c] = r.read<int>('amount');
      }
    }
    return (
      expenses: [
        for (final r in rows)
          // Unknown (newer) categories stay stored, unshown.
          if (byName[r.read<String>('category')] case final c?)
            Expense(
              id: r.read<int>('id'),
              amount: r.read<int>('amount'),
              category: c,
              date: DateTime.fromMicrosecondsSinceEpoch(
                r.read<int>('date'),
                isUtc: true,
              ),
              note: r.read<String>('note'),
            ),
      ],
      budget: budget,
      categoryBudgets: categoryBudgets,
      currency: await _prefs.getString(expenseCurrencyKey),
    );
  });

  @override
  Future<Result<void>> save(List<Expense> expenses) => _guard(
    'save',
    () => _db.transaction(() async {
      for (final e in expenses) {
        await insertExpense(_db, e);
      }
    }),
  );

  @override
  Future<Result<void>> delete(int id) => _guard(
    'delete',
    () => _db.customUpdate(
      'DELETE FROM expenses WHERE id = ?',
      variables: [Variable.withInt(id)],
      updateKind: UpdateKind.delete,
    ),
  );

  @override
  Future<Result<void>> setBudget(int? amount) =>
      _guard('budget', () => _setBudget(_total, amount));

  @override
  Future<Result<void>> setCategoryBudget(
    ExpenseCategory category,
    int? amount,
  ) => _guard('category budget', () => _setBudget(category.name, amount));

  Future<void> _setBudget(String key, int? amount) => amount == null
      ? _db.customUpdate(
          'DELETE FROM expense_budgets WHERE key = ?',
          variables: [Variable.withString(key)],
          updateKind: UpdateKind.delete,
        )
      : _db.customInsert(
          'INSERT OR REPLACE INTO expense_budgets (key, amount) VALUES (?, ?)',
          variables: [Variable.withString(key), Variable.withInt(amount)],
        );

  @override
  Future<Result<void>> setCurrency(String code) =>
      _guard('currency', () => _prefs.setString(expenseCurrencyKey, code));
}
