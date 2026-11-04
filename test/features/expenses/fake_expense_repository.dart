import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/expenses/domain/entities/expense.dart';
import 'package:productive_muslim/features/expenses/domain/repositories/expense_repository.dart';

/// In-memory [ExpenseRepository] that can fail loads/writes or answer
/// writes after [writeDelay] (like a real disk).
final class FakeExpenseRepository implements ExpenseRepository {
  final rows = <int, Expense>{};
  int? budget;
  final categoryBudgets = <ExpenseCategory, int>{};
  String? currency;

  int failLoads = 0;
  bool failWrites = false;

  /// Fails this many upcoming writes.
  int failWriteCount = 0;
  Duration writeDelay = Duration.zero;

  static const _failure = Result<Never>.failure(UnexpectedFailure('disk full'));

  Future<Result<void>> _write(void Function() apply) async {
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    if (failWrites || failWriteCount > 0) {
      if (failWriteCount > 0) failWriteCount--;
      return _failure;
    }
    apply();
    return const Result.success(null);
  }

  @override
  Future<Result<ExpenseData>> load() async {
    if (failLoads > 0) {
      failLoads--;
      return const Result.failure(UnexpectedFailure('db down'));
    }
    return Result.success((
      expenses: rows.values.toList()..sort((a, b) => b.date.compareTo(a.date)),
      budget: budget,
      categoryBudgets: Map.of(categoryBudgets),
      currency: currency,
    ));
  }

  @override
  Future<Result<void>> save(List<Expense> expenses) => _write(() {
    for (final e in expenses) {
      rows[e.id] = e;
    }
  });

  @override
  Future<Result<void>> delete(int id) => _write(() => rows.remove(id));

  @override
  Future<Result<void>> setBudget(int? amount) => _write(() => budget = amount);

  @override
  Future<Result<void>> setCategoryBudget(
    ExpenseCategory category,
    int? amount,
  ) => _write(
    () => amount == null
        ? categoryBudgets.remove(category)
        : categoryBudgets[category] = amount,
  );

  @override
  Future<Result<void>> setCurrency(String code) =>
      _write(() => currency = code);
}
