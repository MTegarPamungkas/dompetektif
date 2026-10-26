import 'dart:math' as math;

import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';

/// Pure Dart calculations for balances, budgets, charts, and anomalies.
///
/// Keeping this outside the blocs makes every number in the UI testable.
class LedgerAnalytics {
  const LedgerAnalytics();

  List<WalletBalance> walletBalances({
    required List<Wallet> wallets,
    required List<Transaction> transactions,
    DateTime? now,
    Map<String, WalletRole> roles = const {},
  }) {
    final anchor = now ?? DateTime.now();
    final monthStart = CaseDates.monthStart(anchor);
    final monthEnd = CaseDates.monthEnd(anchor);

    return wallets
        .where((wallet) => !wallet.isDeleted)
        .map((wallet) {
          var balance = wallet.openingBalance.amountMinor;
          var monthIncome = 0;
          var monthExpense = 0;

          for (final transaction in transactions) {
            if (transaction.isDeleted) continue;
            final amount = transaction.amount.amountMinor;

            if (transaction.type == TransactionType.expense &&
                transaction.walletId == wallet.id) {
              balance -= amount;
            } else if (transaction.type == TransactionType.income &&
                transaction.walletId == wallet.id) {
              balance += amount;
            } else if (transaction.type == TransactionType.transfer) {
              if (transaction.walletId == wallet.id) balance -= amount;
              if (transaction.toWalletId == wallet.id) balance += amount;
            }

            if (!transaction.occurredAt.isBefore(monthStart) &&
                !transaction.occurredAt.isAfter(monthEnd)) {
              if (transaction.type == TransactionType.income &&
                  transaction.walletId == wallet.id) {
                monthIncome += amount;
              }
              if (transaction.type == TransactionType.expense &&
                  transaction.walletId == wallet.id) {
                monthExpense += amount;
              }
            }
          }

          return WalletBalance(
            wallet: wallet,
            balance: Money(balance, currency: wallet.openingBalance.currency),
            monthIncome: Money(
              monthIncome,
              currency: wallet.openingBalance.currency,
            ),
            monthExpense: Money(
              monthExpense,
              currency: wallet.openingBalance.currency,
            ),
            role: roles[wallet.id] ?? WalletRole.owner,
          );
        })
        .toList(growable: false);
  }

  LedgerTotals totals({
    required List<Transaction> transactions,
    DateTime? month,
    String? walletId,
  }) {
    final anchor = month ?? DateTime.now();
    final start = CaseDates.monthStart(anchor);
    final end = CaseDates.monthEnd(anchor);
    var income = 0;
    var expense = 0;

    for (final transaction in transactions) {
      if (transaction.isDeleted) continue;
      if (transaction.occurredAt.isBefore(start) ||
          transaction.occurredAt.isAfter(end)) {
        continue;
      }
      if (walletId != null && transaction.walletId != walletId) continue;
      if (transaction.type == TransactionType.income) {
        income += transaction.amount.amountMinor;
      } else if (transaction.type == TransactionType.expense) {
        expense += transaction.amount.amountMinor;
      }
    }

    return LedgerTotals(income: Money(income), expense: Money(expense));
  }

  List<CashflowPoint> cashflow({
    required List<Transaction> transactions,
    int months = 6,
    DateTime? end,
    String? walletId,
  }) {
    final anchors = CaseDates.lastMonths(months, end: end);
    return anchors
        .map((month) {
          final totals = this.totals(
            transactions: transactions,
            month: month,
            walletId: walletId,
          );
          return CashflowPoint(
            month: month,
            income: totals.income,
            expense: totals.expense,
          );
        })
        .toList(growable: false);
  }

  List<CategorySpend> categorySpend({
    required List<Transaction> transactions,
    required List<Category> categories,
    DateTime? month,
    String? walletId,
  }) {
    final anchor = month ?? DateTime.now();
    final start = CaseDates.monthStart(anchor);
    final end = CaseDates.monthEnd(anchor);
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final amounts = <String, int>{};

    for (final transaction in transactions) {
      if (transaction.isDeleted ||
          transaction.type != TransactionType.expense ||
          transaction.categoryId == null) {
        continue;
      }
      if (transaction.occurredAt.isBefore(start) ||
          transaction.occurredAt.isAfter(end)) {
        continue;
      }
      if (walletId != null && transaction.walletId != walletId) continue;
      amounts.update(
        transaction.categoryId!,
        (value) => value + transaction.amount.amountMinor,
        ifAbsent: () => transaction.amount.amountMinor,
      );
    }

    final total = amounts.values.fold<int>(0, (sum, value) => sum + value);
    final result = <CategorySpend>[];
    for (final entry in amounts.entries) {
      final category = categoryById[entry.key];
      if (category == null) continue;
      result.add(
        CategorySpend(
          category: category,
          amount: Money(entry.value),
          ratio: total == 0 ? 0 : entry.value / total,
        ),
      );
    }
    result.sort((a, b) => b.amount.amountMinor.compareTo(a.amount.amountMinor));
    return result;
  }

  List<MerchantSpend> topMerchants({
    required List<Transaction> transactions,
    DateTime? month,
    String? walletId,
    int limit = 5,
  }) {
    final anchor = month ?? DateTime.now();
    final start = CaseDates.monthStart(anchor);
    final end = CaseDates.monthEnd(anchor);
    final amounts = <String, int>{};
    final counts = <String, int>{};

    for (final transaction in transactions) {
      if (transaction.isDeleted ||
          transaction.type != TransactionType.expense) {
        continue;
      }
      if (transaction.occurredAt.isBefore(start) ||
          transaction.occurredAt.isAfter(end)) {
        continue;
      }
      if (walletId != null && transaction.walletId != walletId) continue;
      final merchant = transaction.merchant.trim().isEmpty
          ? transaction.note.trim()
          : transaction.merchant.trim();
      if (merchant.isEmpty) continue;
      amounts.update(
        merchant,
        (value) => value + transaction.amount.amountMinor,
        ifAbsent: () => transaction.amount.amountMinor,
      );
      counts.update(merchant, (value) => value + 1, ifAbsent: () => 1);
    }

    final result = amounts.entries
        .map(
          (entry) => MerchantSpend(
            name: entry.key,
            amount: Money(entry.value),
            count: counts[entry.key] ?? 1,
          ),
        )
        .toList();
    result.sort((a, b) => b.amount.amountMinor.compareTo(a.amount.amountMinor));
    return result.take(limit).toList(growable: false);
  }

  List<BudgetProgress> budgetProgress({
    required List<Budget> budgets,
    required List<Category> categories,
    required List<Transaction> transactions,
    DateTime? month,
  }) {
    final anchor = month ?? DateTime.now();
    final monthStart = CaseDates.monthStart(anchor);
    final monthEnd = CaseDates.monthEnd(anchor);
    final categoryById = {
      for (final category in categories) category.id: category,
    };

    final progress = <BudgetProgress>[];
    for (final budget in budgets) {
      if (budget.isDeleted) continue;
      if (!CaseDates.sameMonth(budget.month, monthStart)) continue;
      final category = categoryById[budget.categoryId];
      if (category == null) continue;

      var spent = 0;
      for (final transaction in transactions) {
        if (transaction.isDeleted ||
            transaction.type != TransactionType.expense ||
            transaction.categoryId != budget.categoryId) {
          continue;
        }
        if (transaction.occurredAt.isBefore(monthStart) ||
            transaction.occurredAt.isAfter(monthEnd)) {
          continue;
        }
        if (budget.walletId != null &&
            transaction.walletId != budget.walletId) {
          continue;
        }
        spent += transaction.amount.amountMinor;
      }

      final ratio = budget.amount.amountMinor <= 0
          ? 1.0
          : spent / budget.amount.amountMinor;
      final status = ratio >= 1
          ? BudgetStatus.over
          : (ratio >= budget.alertThreshold
                ? BudgetStatus.warning
                : BudgetStatus.safe);

      progress.add(
        BudgetProgress(
          budget: budget,
          category: category,
          spent: Money(spent),
          ratio: ratio,
          status: status,
        ),
      );
    }
    progress.sort((a, b) => b.ratio.compareTo(a.ratio));
    return progress;
  }

  List<Anomaly> anomalies({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required List<Category> categories,
    DateTime? now,
    String? walletId,
    int limit = 3,
  }) {
    final anchor = now ?? DateTime.now();
    final monthStart = CaseDates.monthStart(anchor);
    final monthEnd = CaseDates.monthEnd(anchor);
    final historyStart = monthStart.subtract(const Duration(days: 90));
    final walletById = {for (final wallet in wallets) wallet.id: wallet};
    final categoryById = {
      for (final category in categories) category.id: category,
    };

    final historyByCategory = <String, List<int>>{};
    final allHistory = <int>[];
    for (final transaction in transactions) {
      if (transaction.isDeleted ||
          transaction.type != TransactionType.expense) {
        continue;
      }
      if (transaction.occurredAt.isBefore(historyStart)) continue;
      if (transaction.occurredAt.isAfter(monthEnd)) continue;
      final isCurrent = !transaction.occurredAt.isBefore(monthStart);
      if (isCurrent) continue;
      allHistory.add(transaction.amount.amountMinor);
      final categoryId = transaction.categoryId;
      if (categoryId != null) {
        historyByCategory
            .putIfAbsent(categoryId, () => <int>[])
            .add(transaction.amount.amountMinor);
      }
    }

    final overallAverage = allHistory.isEmpty
        ? 0
        : allHistory.fold<int>(0, (sum, value) => sum + value) ~/
              allHistory.length;

    final results = <Anomaly>[];
    for (final transaction in transactions) {
      if (transaction.isDeleted ||
          transaction.type != TransactionType.expense) {
        continue;
      }
      if (transaction.occurredAt.isBefore(monthStart) ||
          transaction.occurredAt.isAfter(monthEnd)) {
        continue;
      }
      if (walletId != null && transaction.walletId != walletId) continue;
      final wallet = walletById[transaction.walletId];
      if (wallet == null) continue;
      final category = transaction.categoryId == null
          ? null
          : categoryById[transaction.categoryId];
      final amount = transaction.amount.amountMinor;
      final history = transaction.categoryId == null
          ? null
          : historyByCategory[transaction.categoryId];

      double deviation = 0;
      AnomalyKind? kind;
      if (history != null && history.length >= 3) {
        final average =
            history.fold<int>(0, (sum, value) => sum + value) / history.length;
        if (average > 0) deviation = amount / average;
        if (deviation >= 2.5 && amount >= 100000) {
          kind = AnomalyKind.categoryLeak;
        }
      } else if (overallAverage > 0) {
        deviation = amount / overallAverage;
        if (deviation >= 4 && amount >= 250000) {
          kind = AnomalyKind.unusualAmount;
        }
      }

      if (kind == null) continue;
      results.add(
        Anomaly(
          entry: LedgerEntry(
            transaction: transaction,
            wallet: wallet,
            category: category,
          ),
          kind: kind,
          severity: deviation >= 4
              ? AnomalySeverity.alert
              : AnomalySeverity.watch,
          deviation: deviation,
          categoryName: category?.name,
        ),
      );
    }

    results.sort((a, b) => b.deviation.compareTo(a.deviation));
    return results.take(limit).toList(growable: false);
  }

  double monthChange({
    required List<Transaction> transactions,
    DateTime? now,
    String? walletId,
  }) {
    final anchor = now ?? DateTime.now();
    final current = totals(
      transactions: transactions,
      month: anchor,
      walletId: walletId,
    ).expense.amountMinor;
    final previous = totals(
      transactions: transactions,
      month: CaseDates.previousMonth(anchor),
      walletId: walletId,
    ).expense.amountMinor;
    if (previous == 0) return current == 0 ? 0 : 1;
    return (current - previous) / previous;
  }

  DashboardData dashboard({
    required List<Wallet> wallets,
    required List<Transaction> transactions,
    required List<Category> categories,
    required List<Budget> budgets,
    required List<Receipt> receipts,
    required List<CaseNote> notes,
    required Map<String, WalletRole> roles,
    DateTime? now,
    String? activeWalletId,
    String? sharedWalletId,
  }) {
    final anchor = now ?? DateTime.now();
    final balances = walletBalances(
      wallets: wallets,
      transactions: transactions,
      now: anchor,
      roles: roles,
    );
    final filteredBalances = activeWalletId == null
        ? balances
        : balances.where((item) => item.wallet.id == activeWalletId).toList();
    final totalBalance = filteredBalances.fold<int>(
      0,
      (sum, item) => sum + item.balance.amountMinor,
    );
    final totals = this.totals(
      transactions: transactions,
      month: anchor,
      walletId: activeWalletId,
    );
    final progress = budgetProgress(
      budgets: budgets,
      categories: categories,
      transactions: transactions,
      month: anchor,
    );
    final currentNotes =
        notes
            .where(
              (note) =>
                  !note.isDeleted &&
                  (sharedWalletId == null || note.walletId == sharedWalletId),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DashboardData(
      totalBalance: Money(totalBalance),
      monthIncome: totals.income,
      monthExpense: totals.expense,
      monthNet: totals.net,
      wallets: balances,
      recentEntries: _recentEntries(
        transactions: transactions,
        wallets: wallets,
        categories: categories,
        walletId: activeWalletId,
      ),
      budgetProgress: progress,
      anomalies: anomalies(
        transactions: transactions,
        wallets: wallets,
        categories: categories,
        now: anchor,
        walletId: activeWalletId,
      ),
      cashflow: cashflow(
        transactions: transactions,
        end: anchor,
        walletId: activeWalletId,
      ),
      categorySpend: categorySpend(
        transactions: transactions,
        categories: categories,
        month: anchor,
        walletId: activeWalletId,
      ),
      recentReceipts: _recentReceipts(receipts, walletId: activeWalletId),
      teamActivity: currentNotes.take(4).toList(growable: false),
      monthExpenseChange: monthChange(
        transactions: transactions,
        now: anchor,
        walletId: activeWalletId,
      ),
      activeWalletId: activeWalletId,
    );
  }

  List<LedgerEntry> _recentEntries({
    required List<Transaction> transactions,
    required List<Wallet> wallets,
    required List<Category> categories,
    String? walletId,
  }) {
    final walletById = {for (final wallet in wallets) wallet.id: wallet};
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final entries = <LedgerEntry>[];
    for (final transaction in transactions) {
      if (transaction.isDeleted) continue;
      if (walletId != null && transaction.walletId != walletId) continue;
      final wallet = walletById[transaction.walletId];
      if (wallet == null) continue;
      entries.add(
        LedgerEntry(
          transaction: transaction,
          wallet: wallet,
          toWallet: transaction.toWalletId == null
              ? null
              : walletById[transaction.toWalletId],
          category: transaction.categoryId == null
              ? null
              : categoryById[transaction.categoryId],
        ),
      );
    }
    entries.sort(
      (a, b) => b.transaction.occurredAt.compareTo(a.transaction.occurredAt),
    );
    return entries.take(6).toList(growable: false);
  }

  List<Receipt> _recentReceipts(List<Receipt> receipts, {String? walletId}) {
    final filtered =
        receipts
            .where(
              (receipt) =>
                  !receipt.isDeleted &&
                  (walletId == null || receipt.walletId == walletId),
            )
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return filtered.take(4).toList(growable: false);
  }

  static double standardDeviation(List<int> values) {
    if (values.length < 2) return 0;
    final mean =
        values.fold<int>(0, (sum, value) => sum + value) / values.length;
    final variance =
        values.fold<double>(
          0,
          (sum, value) => sum + math.pow(value - mean, 2),
        ) /
        values.length;
    return math.sqrt(variance);
  }
}
