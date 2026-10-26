import 'dart:typed_data';

import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';

abstract interface class TransactionRepository {
  Stream<List<Transaction>> watchTransactions();

  Stream<List<LedgerEntry>> watchLedger();

  Future<List<LedgerEntry>> getLedger();

  Future<List<Transaction>> getTransactions();

  Future<LedgerEntry?> getEntry(String id);

  Future<void> saveTransaction(Transaction transaction);

  Future<void> deleteTransaction(String id);
}

abstract interface class BudgetRepository {
  Stream<List<Budget>> watchBudgets({DateTime? month});

  Future<List<Budget>> getBudgets({DateTime? month});

  Future<Budget?> getBudget(String id);

  Future<void> saveBudget(Budget budget);

  Future<void> deleteBudget(String id);
}

abstract interface class RecurringRepository {
  Stream<List<RecurringRule>> watchRules();

  Future<List<RecurringRule>> getRules();

  Future<void> saveRule(RecurringRule rule);

  Future<void> deleteRule(String id);
}

abstract interface class ReceiptRepository {
  Stream<List<Receipt>> watchReceipts();

  Future<List<Receipt>> getReceipts();

  Future<Receipt?> getReceipt(String id);

  Future<void> saveReceipt(Receipt receipt, {Uint8List? imageBytes});

  Future<void> deleteReceipt(String id);

  Future<Uint8List?> loadImage(String receiptId);
}
