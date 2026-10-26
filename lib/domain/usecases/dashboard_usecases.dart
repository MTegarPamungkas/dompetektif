import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';
import 'package:dompetektif/domain/repositories/ledger_repository.dart';
import 'package:dompetektif/domain/repositories/wallet_repository.dart';
import 'package:dompetektif/domain/usecases/ledger_analytics.dart';

class WatchDashboard {
  const WatchDashboard(
    this._settings,
    this._wallets,
    this._transactions,
    this._categories,
    this._budgets,
    this._receipts,
    this._team, {
    LedgerAnalytics analytics = const LedgerAnalytics(),
  }) : _analytics = analytics;

  final SettingsRepository _settings;
  final WalletRepository _wallets;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final BudgetRepository _budgets;
  final ReceiptRepository _receipts;
  final TeamRepository _team;
  final LedgerAnalytics _analytics;

  Stream<DashboardData> call() {
    return combineLatest7(
      _settings.watch(),
      _wallets.watchWallets(),
      _transactions.watchTransactions(),
      _categories.watchCategories(),
      _budgets.watchBudgets(),
      _receipts.watchReceipts(),
      _team.watchAllNotes(),
      (
        AppSettings settings,
        List<Wallet> wallets,
        List<Transaction> transactions,
        List<Category> categories,
        List<Budget> budgets,
        List<Receipt> receipts,
        List<CaseNote> notes,
      ) {
        return _analytics.dashboard(
          wallets: wallets,
          transactions: transactions,
          categories: categories,
          budgets: budgets,
          receipts: receipts,
          notes: notes,
          roles: const {},
          activeWalletId: settings.activeWalletId,
        );
      },
    );
  }
}
