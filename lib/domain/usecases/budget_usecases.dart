import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/repositories/ledger_repository.dart';
import 'package:dompetektif/domain/repositories/wallet_repository.dart';
import 'package:dompetektif/domain/usecases/ledger_analytics.dart';

class WatchBudgets {
  const WatchBudgets(this._repository);

  final BudgetRepository _repository;

  Stream<List<Budget>> call({DateTime? month}) =>
      _repository.watchBudgets(month: month);
}

class SaveBudget {
  const SaveBudget(this._repository);

  final BudgetRepository _repository;

  Future<void> call(Budget budget) => _repository.saveBudget(budget);
}

class DeleteBudget {
  const DeleteBudget(this._repository);

  final BudgetRepository _repository;

  Future<void> call(String id) => _repository.deleteBudget(id);
}

class WatchBudgetProgress {
  const WatchBudgetProgress(
    this._budgets,
    this._categories,
    this._transactions, {
    LedgerAnalytics analytics = const LedgerAnalytics(),
  }) : _analytics = analytics;

  final BudgetRepository _budgets;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final LedgerAnalytics _analytics;

  Stream<List<BudgetProgress>> call({DateTime? month}) {
    final anchor = month ?? DateTime.now();
    return combineLatest3(
      _budgets.watchBudgets(month: anchor),
      _categories.watchCategories(),
      _transactions.watchTransactions(),
      (
        List<Budget> budgets,
        List<Category> categories,
        List<Transaction> transactions,
      ) {
        return _analytics.budgetProgress(
          budgets: budgets,
          categories: categories,
          transactions: transactions,
          month: anchor,
        );
      },
    );
  }
}
