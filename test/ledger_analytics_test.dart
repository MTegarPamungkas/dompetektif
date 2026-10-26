import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/ledger_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analytics = LedgerAnalytics();
  final now = DateTime(2026, 10, 20, 12);
  final created = DateTime(2026, 9, 25);

  Wallet wallet(
    String id, {
    int opening = 0,
    String name = 'Dompet',
    WalletType type = WalletType.cash,
  }) {
    return Wallet(
      id: id,
      ownerId: 'user-1',
      name: name,
      type: type,
      openingBalance: Money(opening),
      createdAt: created,
      updatedAt: created,
    );
  }

  Category category(
    String id,
    String name, {
    CategoryKind kind = CategoryKind.expense,
    List<String> keywords = const [],
  }) {
    return Category(
      id: id,
      name: name,
      kind: kind,
      keywords: keywords,
      createdAt: created,
      updatedAt: created,
    );
  }

  Transaction tx({
    required String id,
    required String walletId,
    required TransactionType type,
    required int amount,
    required DateTime occurredAt,
    String? categoryId,
    String? toWalletId,
    String merchant = '',
    DateTime? deletedAt,
  }) {
    return Transaction(
      id: id,
      walletId: walletId,
      userId: 'user-1',
      type: type,
      amount: Money(amount),
      categoryId: categoryId,
      toWalletId: toWalletId,
      occurredAt: occurredAt,
      merchant: merchant,
      createdAt: occurredAt,
      updatedAt: occurredAt,
      deletedAt: deletedAt,
    );
  }

  final food = category('food', 'Food & Drinks', keywords: ['kopi']);
  final transport = category('transport', 'Transport');
  final salary = category('salary', 'Salary', kind: CategoryKind.income);
  final wallets = [wallet('w1', opening: 1000000), wallet('w2', name: 'Bank')];

  final transactions = [
    tx(
      id: 'expense-food',
      walletId: 'w1',
      type: TransactionType.expense,
      amount: 200000,
      occurredAt: DateTime(2026, 10, 2),
      categoryId: food.id,
      merchant: 'Kopi Kenangan',
    ),
    tx(
      id: 'expense-transport',
      walletId: 'w1',
      type: TransactionType.expense,
      amount: 50000,
      occurredAt: DateTime(2026, 10, 8),
      categoryId: transport.id,
      merchant: 'Gojek',
    ),
    tx(
      id: 'income',
      walletId: 'w1',
      type: TransactionType.income,
      amount: 500000,
      occurredAt: DateTime(2026, 10, 1),
      categoryId: salary.id,
      merchant: 'Payroll',
    ),
    tx(
      id: 'transfer-out',
      walletId: 'w1',
      type: TransactionType.transfer,
      amount: 100000,
      occurredAt: DateTime(2026, 10, 12),
      toWalletId: 'w2',
    ),
    tx(
      id: 'deleted',
      walletId: 'w1',
      type: TransactionType.expense,
      amount: 999000,
      occurredAt: DateTime(2026, 10, 3),
      categoryId: food.id,
      deletedAt: DateTime(2026, 10, 4),
    ),
    tx(
      id: 'old',
      walletId: 'w1',
      type: TransactionType.expense,
      amount: 1000000,
      occurredAt: DateTime(2026, 9, 20),
      categoryId: food.id,
    ),
  ];

  group('walletBalances', () {
    test('applies opening balances, income, expenses, and transfers', () {
      final balances = analytics.walletBalances(
        wallets: wallets,
        transactions: transactions,
        now: now,
      );
      final w1 = balances.firstWhere((item) => item.wallet.id == 'w1');
      final w2 = balances.firstWhere((item) => item.wallet.id == 'w2');

      // 1.000.000 opening + 500.000 income - 250.000 current expenses
      // - 1.000.000 previous-month expense - 100.000 transfer out.
      expect(w1.balance.amountMinor, 150000);
      expect(w1.monthIncome.amountMinor, 500000);
      expect(w1.monthExpense.amountMinor, 250000);
      expect(w2.balance.amountMinor, 100000);
      expect(w2.monthIncome.amountMinor, 0);
    });

    test('attaches membership roles and hides deleted wallets', () {
      final withDeleted = [
        ...wallets,
        wallet('gone').copyWith(deletedAt: DateTime(2026, 10, 1)),
      ];
      final balances = analytics.walletBalances(
        wallets: withDeleted,
        transactions: transactions,
        now: now,
        roles: const {'w2': WalletRole.editor},
      );

      expect(balances, hasLength(2));
      expect(
        balances.firstWhere((item) => item.wallet.id == 'w2').role,
        WalletRole.editor,
      );
    });
  });

  group('totals and cashflow', () {
    test('totals only count the selected month and wallet', () {
      final all = analytics.totals(transactions: transactions, month: now);
      expect(all.income.amountMinor, 500000);
      expect(all.expense.amountMinor, 250000);
      expect(all.net.amountMinor, 250000);

      final w2 = analytics.totals(
        transactions: transactions,
        month: now,
        walletId: 'w2',
      );
      expect(w2.income.amountMinor, 0);
      expect(w2.expense.amountMinor, 0);
    });

    test('cashflow returns the requested month window in order', () {
      final points = analytics.cashflow(
        transactions: transactions,
        months: 6,
        end: now,
        walletId: 'w1',
      );

      expect(points, hasLength(6));
      expect(points.last.month, DateTime(2026, 10));
      expect(points.last.expense.amountMinor, 250000);
      expect(points.any((point) => point.month.month == 9), isTrue);
    });

    test('monthChange compares against the previous month', () {
      final change = analytics.monthChange(
        transactions: transactions,
        now: now,
        walletId: 'w1',
      );
      // Last month's expense is 1.000.000; this month is 250.000.
      expect(change, closeTo(-0.75, 0.0001));
    });
  });

  group('category and merchant analytics', () {
    test('ranks category spending with stable ratios', () {
      final spend = analytics.categorySpend(
        transactions: transactions,
        categories: [food, transport, salary],
        month: now,
        walletId: 'w1',
      );

      expect(spend, hasLength(2));
      expect(spend.first.category.id, food.id);
      expect(spend.first.amount.amountMinor, 200000);
      expect(spend.first.ratio, closeTo(0.8, 0.0001));
      expect(spend.last.category.id, transport.id);
      expect(spend.last.ratio, closeTo(0.2, 0.0001));
    });

    test('ranks merchants by spend and count', () {
      final merchants = analytics.topMerchants(
        transactions: transactions,
        month: now,
        walletId: 'w1',
      );

      expect(merchants.first.name, 'Kopi Kenangan');
      expect(merchants.first.amount.amountMinor, 200000);
      expect(merchants.first.count, 1);
      expect(merchants[1].name, 'Gojek');
    });
  });

  group('budget progress', () {
    Budget budget(String id, String categoryId, int amount) => Budget(
      id: id,
      ownerId: 'user-1',
      categoryId: categoryId,
      amount: Money(amount),
      month: DateTime(2026, 10, 1),
      createdAt: created,
      updatedAt: created,
    );

    test('marks safe, warning, and over budgets correctly', () {
      final categories = [food, transport, category('shopping', 'Shopping')];
      final progress = analytics.budgetProgress(
        budgets: [
          budget('b1', food.id, 250000),
          budget('b2', transport.id, 50000),
          budget('b3', 'shopping', 500000),
        ],
        categories: categories,
        transactions: transactions,
        month: now,
      );

      final byId = {for (final item in progress) item.budget.id: item};
      expect(byId['b1']!.status, BudgetStatus.warning);
      expect(byId['b1']!.ratio, closeTo(0.8, 0.001));
      expect(byId['b2']!.status, BudgetStatus.over);
      expect(byId['b2']!.isOver, isFalse);
      expect(byId['b3']!.status, BudgetStatus.safe);
      expect(progress.first.budget.id, 'b2');
    });
  });

  group('anomaly detection', () {
    test('flags a category expense several times above its history', () {
      final history = [
        for (var i = 0; i < 3; i++)
          tx(
            id: 'history-$i',
            walletId: 'w1',
            type: TransactionType.expense,
            amount: 50000,
            occurredAt: DateTime(2026, 9, 5 + i),
            categoryId: food.id,
            merchant: 'Kopi',
          ),
      ];
      final spike = tx(
        id: 'spike',
        walletId: 'w1',
        type: TransactionType.expense,
        amount: 300000,
        occurredAt: DateTime(2026, 10, 9),
        categoryId: food.id,
        merchant: 'Kopi Kenangan',
      );

      final anomalies = analytics.anomalies(
        transactions: [...history, spike],
        wallets: wallets,
        categories: [food],
        now: now,
      );

      expect(anomalies, hasLength(1));
      expect(anomalies.first.entry.transaction.id, 'spike');
      expect(anomalies.first.kind, AnomalyKind.categoryLeak);
      expect(anomalies.first.deviation, closeTo(6, 0.001));
      expect(anomalies.first.severity, AnomalySeverity.alert);
    });

    test(
      'returns nothing when history is too thin to establish a baseline',
      () {
        final anomalies = analytics.anomalies(
          transactions: [
            tx(
              id: 'only',
              walletId: 'w1',
              type: TransactionType.expense,
              amount: 2000000,
              occurredAt: DateTime(2026, 10, 9),
              categoryId: food.id,
            ),
          ],
          wallets: wallets,
          categories: [food],
          now: now,
        );

        expect(anomalies, isEmpty);
      },
    );
  });
}
