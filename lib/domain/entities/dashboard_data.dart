import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:equatable/equatable.dart';

enum AnomalySeverity {
  watch,
  alert;

  static AnomalySeverity fromKey(String? value) =>
      value == 'alert' ? AnomalySeverity.alert : AnomalySeverity.watch;
}

enum AnomalyKind { categoryLeak, unusualAmount }

class Anomaly extends Equatable {
  const Anomaly({
    required this.entry,
    required this.kind,
    required this.severity,
    this.deviation = 0,
    this.categoryName,
  });

  final LedgerEntry entry;
  final AnomalyKind kind;
  final AnomalySeverity severity;
  final double deviation;
  final String? categoryName;

  @override
  List<Object?> get props => [entry, kind, severity, deviation, categoryName];
}

class LedgerTotals extends Equatable {
  const LedgerTotals({required this.income, required this.expense});

  final Money income;
  final Money expense;

  Money get net => income - expense;

  @override
  List<Object?> get props => [income, expense];
}

class MerchantSpend extends Equatable {
  const MerchantSpend({
    required this.name,
    required this.amount,
    required this.count,
  });

  final String name;
  final Money amount;
  final int count;

  @override
  List<Object?> get props => [name, amount, count];
}

class CashflowPoint extends Equatable {
  const CashflowPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final Money income;
  final Money expense;

  Money get net => income - expense;

  @override
  List<Object?> get props => [month, income, expense];
}

class CategorySpend extends Equatable {
  const CategorySpend({
    required this.category,
    required this.amount,
    required this.ratio,
  });

  final Category category;
  final Money amount;
  final double ratio;

  @override
  List<Object?> get props => [category, amount, ratio];
}

class DashboardData extends Equatable {
  const DashboardData({
    required this.totalBalance,
    required this.monthIncome,
    required this.monthExpense,
    required this.monthNet,
    required this.wallets,
    required this.recentEntries,
    required this.budgetProgress,
    required this.anomalies,
    required this.cashflow,
    required this.categorySpend,
    required this.recentReceipts,
    required this.teamActivity,
    required this.monthExpenseChange,
    required this.activeWalletId,
  });

  const DashboardData.empty()
    : totalBalance = Money.zero,
      monthIncome = Money.zero,
      monthExpense = Money.zero,
      monthNet = Money.zero,
      wallets = const [],
      recentEntries = const [],
      budgetProgress = const [],
      anomalies = const [],
      cashflow = const [],
      categorySpend = const [],
      recentReceipts = const [],
      teamActivity = const [],
      monthExpenseChange = 0,
      activeWalletId = null;

  final Money totalBalance;
  final Money monthIncome;
  final Money monthExpense;
  final Money monthNet;
  final List<WalletBalance> wallets;
  final List<LedgerEntry> recentEntries;
  final List<BudgetProgress> budgetProgress;
  final List<Anomaly> anomalies;
  final List<CashflowPoint> cashflow;
  final List<CategorySpend> categorySpend;
  final List<Receipt> recentReceipts;
  final List<CaseNote> teamActivity;
  final double monthExpenseChange;
  final String? activeWalletId;

  WalletBalance? get activeWallet {
    if (activeWalletId == null) return null;
    for (final wallet in wallets) {
      if (wallet.wallet.id == activeWalletId) return wallet;
    }
    return null;
  }

  List<BudgetProgress> get budgetAlerts {
    return budgetProgress
        .where((progress) => progress.status != BudgetStatus.safe)
        .toList(growable: false);
  }

  @override
  List<Object?> get props => [
    totalBalance,
    monthIncome,
    monthExpense,
    monthNet,
    wallets,
    recentEntries,
    budgetProgress,
    anomalies,
    cashflow,
    categorySpend,
    recentReceipts,
    teamActivity,
    monthExpenseChange,
    activeWalletId,
  ];
}
