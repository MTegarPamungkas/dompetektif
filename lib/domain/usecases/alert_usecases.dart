import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';
import 'package:dompetektif/domain/repositories/ledger_repository.dart';
import 'package:dompetektif/domain/repositories/wallet_repository.dart';
import 'package:dompetektif/domain/services/device_services.dart';
import 'package:dompetektif/domain/usecases/ledger_analytics.dart';

class CheckBudgetAlerts {
  CheckBudgetAlerts(
    this._budgets,
    this._categories,
    this._transactions,
    this._alerts, {
    LedgerAnalytics analytics = const LedgerAnalytics(),
  }) : _analytics = analytics;

  final BudgetRepository _budgets;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final AlertRepository _alerts;
  final LedgerAnalytics _analytics;

  Future<List<BudgetProgress>> call({DateTime? month}) async {
    final anchor = month ?? DateTime.now();
    final budgets = await _budgets.getBudgets(month: anchor);
    final categories = await _categories.getCategories();
    final transactions = await _transactions.getTransactions();
    final progress = _analytics.budgetProgress(
      budgets: budgets,
      categories: categories,
      transactions: transactions,
      month: anchor,
    );

    final fresh = <BudgetProgress>[];
    for (final item in progress) {
      if (item.status == BudgetStatus.safe) continue;
      final key =
          'budget:${item.budget.id}:${anchor.year}-${anchor.month}:${item.status.name}';
      if (await _alerts.wasSent(key)) continue;
      await _alerts.markSent(key);
      fresh.add(item);
    }
    return fresh;
  }
}

class SendBudgetAlert {
  const SendBudgetAlert(this._notifications);

  final NotificationService _notifications;

  Future<void> call({
    required String title,
    required String body,
    String? payload,
  }) {
    return _notifications.showBudgetAlert(
      title: title,
      body: body,
      payload: payload,
    );
  }
}

class SendCaseAlert {
  const SendCaseAlert(this._notifications);

  final NotificationService _notifications;

  Future<void> call({
    required String title,
    required String body,
    String? payload,
  }) {
    return _notifications.showCaseAlert(
      title: title,
      body: body,
      payload: payload,
    );
  }
}
