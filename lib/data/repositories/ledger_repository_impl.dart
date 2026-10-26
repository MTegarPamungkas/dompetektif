import 'dart:typed_data';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/data/datasources/cloud_gateway.dart';
import 'package:dompetektif/data/mappers/entity_mappers.dart';
import 'package:dompetektif/data/repositories/local_repository_base.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/repositories/ledger_repository.dart';

class TransactionRepositoryImpl extends LocalRepositoryBase
    implements TransactionRepository {
  TransactionRepositoryImpl(super.store, super.sync, super.auth);

  @override
  Stream<List<Transaction>> watchTransactions() {
    return store.watch('transactions').map(_mapTransactions);
  }

  @override
  Stream<List<LedgerEntry>> watchLedger() {
    return combineLatest3(
      store.watch('transactions'),
      store.watch('wallets'),
      store.watch('categories'),
      (
        List<Map<String, dynamic>> transactionRows,
        List<Map<String, dynamic>> walletRows,
        List<Map<String, dynamic>> categoryRows,
      ) {
        return _buildEntries(transactionRows, walletRows, categoryRows);
      },
    );
  }

  @override
  Future<List<LedgerEntry>> getLedger() async {
    return _buildEntries(
      store.all('transactions'),
      store.all('wallets'),
      store.all('categories'),
    );
  }

  @override
  Future<List<Transaction>> getTransactions() async =>
      _mapTransactions(store.all('transactions'));

  @override
  Future<LedgerEntry?> getEntry(String id) async {
    final entries = await getLedger();
    for (final entry in entries) {
      if (entry.transaction.id == id) return entry;
    }
    return null;
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    final now = DateTime.now();
    final updated = transaction.copyWith(
      userId: transaction.userId.isEmpty ? userId : transaction.userId,
      updatedAt: now,
    );
    await upsertRow('transactions', transactionToRow(updated), updatedAt: now);
  }

  @override
  Future<void> deleteTransaction(String id) =>
      softDeleteRow('transactions', id);

  List<Transaction> _mapTransactions(List<Map<String, dynamic>> rows) {
    final transactions =
        rows
            .map(transactionFromRow)
            .where((transaction) => !transaction.isDeleted)
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return transactions;
  }

  List<LedgerEntry> _buildEntries(
    List<Map<String, dynamic>> transactionRows,
    List<Map<String, dynamic>> walletRows,
    List<Map<String, dynamic>> categoryRows,
  ) {
    final wallets = <String, Wallet>{};
    for (final row in walletRows) {
      final wallet = walletFromRow(row);
      if (!wallet.isDeleted) wallets[wallet.id] = wallet;
    }
    final categories = <String, Category>{};
    for (final row in categoryRows) {
      final category = categoryFromRow(row);
      if (!category.isDeleted) categories[category.id] = category;
    }

    final entries = <LedgerEntry>[];
    for (final row in transactionRows) {
      final transaction = transactionFromRow(row);
      if (transaction.isDeleted) continue;
      final wallet = wallets[transaction.walletId];
      if (wallet == null) continue;
      entries.add(
        LedgerEntry(
          transaction: transaction,
          wallet: wallet,
          toWallet: transaction.toWalletId == null
              ? null
              : wallets[transaction.toWalletId],
          category: transaction.categoryId == null
              ? null
              : categories[transaction.categoryId],
        ),
      );
    }
    entries.sort(
      (a, b) => b.transaction.occurredAt.compareTo(a.transaction.occurredAt),
    );
    return entries;
  }
}

class BudgetRepositoryImpl extends LocalRepositoryBase
    implements BudgetRepository {
  BudgetRepositoryImpl(super.store, super.sync, super.auth);

  @override
  Stream<List<Budget>> watchBudgets({DateTime? month}) {
    return store.watch('budgets').map((rows) => _map(rows, month));
  }

  @override
  Future<List<Budget>> getBudgets({DateTime? month}) async =>
      _map(store.all('budgets'), month);

  @override
  Future<Budget?> getBudget(String id) async {
    final row = store.get('budgets', id);
    if (row == null) return null;
    final budget = budgetFromRow(row);
    return budget.isDeleted ? null : budget;
  }

  @override
  Future<void> saveBudget(Budget budget) async {
    final now = DateTime.now();
    final updated = budget.copyWith(
      ownerId: budget.ownerId.isEmpty ? userId : budget.ownerId,
      month: DateTime(budget.month.year, budget.month.month),
      updatedAt: now,
    );
    await upsertRow('budgets', budgetToRow(updated), updatedAt: now);
  }

  @override
  Future<void> deleteBudget(String id) => softDeleteRow('budgets', id);

  List<Budget> _map(List<Map<String, dynamic>> rows, DateTime? month) {
    final budgets =
        rows
            .map(budgetFromRow)
            .where(
              (budget) =>
                  !budget.isDeleted &&
                  (month == null ||
                      (budget.month.year == month.year &&
                          budget.month.month == month.month)),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return budgets;
  }
}

class RecurringRepositoryImpl extends LocalRepositoryBase
    implements RecurringRepository {
  RecurringRepositoryImpl(super.store, super.sync, super.auth);

  @override
  Stream<List<RecurringRule>> watchRules() {
    return store.watch('recurring_rules').map(_map);
  }

  @override
  Future<List<RecurringRule>> getRules() async =>
      _map(store.all('recurring_rules'));

  @override
  Future<void> saveRule(RecurringRule rule) async {
    final now = DateTime.now();
    final updated = rule.copyWith(
      ownerId: rule.ownerId.isEmpty ? userId : rule.ownerId,
      updatedAt: now,
    );
    await upsertRow('recurring_rules', recurringToRow(updated), updatedAt: now);
  }

  @override
  Future<void> deleteRule(String id) => softDeleteRow('recurring_rules', id);

  List<RecurringRule> _map(List<Map<String, dynamic>> rows) {
    final rules =
        rows.map(recurringFromRow).where((rule) => !rule.isDeleted).toList()
          ..sort((a, b) => a.nextRunAt.compareTo(b.nextRunAt));
    return rules;
  }
}

class ReceiptRepositoryImpl extends LocalRepositoryBase
    implements ReceiptRepository {
  ReceiptRepositoryImpl(super.store, super.sync, super.auth, this._gateway);

  final CloudGateway _gateway;

  @override
  Stream<List<Receipt>> watchReceipts() {
    return store.watch('receipts').map(_map);
  }

  @override
  Future<List<Receipt>> getReceipts() async => _map(store.all('receipts'));

  @override
  Future<Receipt?> getReceipt(String id) async {
    final row = store.get('receipts', id);
    if (row == null) return null;
    final receipt = receiptFromRow(row);
    return receipt.isDeleted ? null : receipt;
  }

  @override
  Future<void> saveReceipt(Receipt receipt, {Uint8List? imageBytes}) async {
    final now = DateTime.now();
    var updated = receipt.copyWith(
      ownerId: receipt.ownerId.isEmpty ? userId : receipt.ownerId,
      updatedAt: now,
    );

    if (imageBytes != null) {
      final imageKey = updated.imageKey ?? updated.id;
      await store.saveImage(imageKey, imageBytes);
      updated = updated.copyWith(imageKey: imageKey);

      if (!_gateway.isDemo) {
        try {
          final remoteUrl = await _gateway.uploadReceipt(
            updated.id,
            imageBytes,
          );
          if (remoteUrl != null) {
            updated = updated.copyWith(remoteImageUrl: remoteUrl);
          }
        } catch (_) {
          // The receipt is still safe locally; upload can be retried later.
        }
      }
    }

    await upsertRow('receipts', receiptToRow(updated), updatedAt: now);
  }

  @override
  Future<void> deleteReceipt(String id) async {
    final row = store.get('receipts', id);
    if (row != null) {
      final receipt = receiptFromRow(row);
      if (receipt.imageKey != null) {
        await store.deleteImage(receipt.imageKey!);
      }
    }
    await softDeleteRow('receipts', id);
  }

  @override
  Future<Uint8List?> loadImage(String receiptId) async {
    final row = store.get('receipts', receiptId);
    if (row == null) return null;
    final receipt = receiptFromRow(row);
    final key = receipt.imageKey;
    if (key == null) return null;
    final bytes = store.loadImage(key);
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  List<Receipt> _map(List<Map<String, dynamic>> rows) {
    final receipts =
        rows.map(receiptFromRow).where((receipt) => !receipt.isDeleted).toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return receipts;
  }
}
