import '../../../../core/utils/result.dart';
import '../entities/expense.dart';

/// Everything the expense log persists.
typedef ExpenseData = ({
  List<Expense> expenses,
  int? budget,
  Map<ExpenseCategory, int> categoryBudgets,
  String? currency,

  /// Highest id stored, hidden rows (unknown categories) included; 0 when
  /// empty. New ids go above it so they never replace a stored row.
  int maxId,
});

/// Persistence for the expense log (hisab). Amounts are minor units.
abstract interface class ExpenseRepository {
  /// All stored data; brings in any pre-database data first (once).
  Future<Result<ExpenseData>> load();

  /// Inserts [expenses], replacing any stored under the same id — in one
  /// transaction.
  Future<Result<void>> save(List<Expense> expenses);

  Future<Result<void>> delete(int id);

  /// Monthly budget; null clears it.
  Future<Result<void>> setBudget(int? amount);

  /// [category]'s monthly budget; null clears it.
  Future<Result<void>> setCategoryBudget(ExpenseCategory category, int? amount);

  /// ISO 4217 code of the amounts.
  Future<Result<void>> setCurrency(String code);
}
