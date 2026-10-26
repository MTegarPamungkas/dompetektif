import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/services/device_services.dart';
import 'package:dompetektif/domain/usecases/alert_usecases.dart';
import 'package:dompetektif/domain/usecases/recurring_usecases.dart';

/// Runs small, idempotent jobs that keep the case file current:
/// materializing recurring rules and surfacing budget threshold alerts.
class AppMaintenance {
  AppMaintenance(
    this._runDue,
    this._checkBudgetAlerts,
    this._sendBudgetAlert,
    this._notifications,
  );

  final RunDueRecurring _runDue;
  final CheckBudgetAlerts _checkBudgetAlerts;
  final SendBudgetAlert _sendBudgetAlert;
  final NotificationService _notifications;

  Future<void> run(AppLocalizations l10n) async {
    await _notifications.initialize();
    await _runDue();
    final alerts = await _checkBudgetAlerts();
    if (alerts.isEmpty) return;

    await _notifications.requestPermission();
    for (final item in alerts) {
      final category = localizedCategoryName(l10n, item.category);
      final body = item.status == BudgetStatus.over
          ? l10n.budgetOver(category)
          : l10n.budgetWarning(
              category,
              MoneyFormatter.percent(
                item.ratio,
                localeCode: l10n.locale.languageCode,
              ),
            );
      await _sendBudgetAlert(
        title: l10n.budgetAlertTitle,
        body: body,
        payload: 'budget:${item.budget.id}',
      );
    }
  }
}
