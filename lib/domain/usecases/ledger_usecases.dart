import 'dart:typed_data';

import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/repositories/ledger_repository.dart';
import 'package:dompetektif/domain/repositories/wallet_repository.dart';
import 'package:dompetektif/domain/services/device_services.dart';
import 'package:dompetektif/domain/services/receipt_parser.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:uuid/uuid.dart';

class WatchLedger {
  const WatchLedger(this._repository);

  final TransactionRepository _repository;

  Stream<List<LedgerEntry>> call() => _repository.watchLedger();
}

class WatchTransactions {
  const WatchTransactions(this._repository);

  final TransactionRepository _repository;

  Stream<List<Transaction>> call() => _repository.watchTransactions();
}

class GetLedgerEntry {
  const GetLedgerEntry(this._repository);

  final TransactionRepository _repository;

  Future<LedgerEntry?> call(String id) => _repository.getEntry(id);
}

class SaveTransaction {
  const SaveTransaction(this._repository);

  final TransactionRepository _repository;

  Future<void> call(Transaction transaction) =>
      _repository.saveTransaction(transaction);
}

class DeleteTransaction {
  const DeleteTransaction(this._repository);

  final TransactionRepository _repository;

  Future<void> call(String id) => _repository.deleteTransaction(id);
}

class WatchReceipts {
  const WatchReceipts(this._repository);

  final ReceiptRepository _repository;

  Stream<List<Receipt>> call() => _repository.watchReceipts();
}

class GetReceipt {
  const GetReceipt(this._repository);

  final ReceiptRepository _repository;

  Future<Receipt?> call(String id) => _repository.getReceipt(id);
}

class SaveReceipt {
  const SaveReceipt(this._repository);

  final ReceiptRepository _repository;

  Future<void> call(Receipt receipt, {Uint8List? imageBytes}) =>
      _repository.saveReceipt(receipt, imageBytes: imageBytes);
}

class DeleteReceipt {
  const DeleteReceipt(this._repository);

  final ReceiptRepository _repository;

  Future<void> call(String id) => _repository.deleteReceipt(id);
}

class LoadReceiptImage {
  const LoadReceiptImage(this._repository);

  final ReceiptRepository _repository;

  Future<Uint8List?> call(String id) => _repository.loadImage(id);
}

class ParseReceiptText {
  const ParseReceiptText(this._categories);

  final CategoryRepository _categories;

  Future<OcrResult> call(String text) async {
    final rawText = text.trim();
    if (rawText.isEmpty) {
      return const OcrResult(rawText: '', isSupported: false);
    }
    final parsed = const ReceiptParser().parse(rawText);
    final categories = await _categories.getCategories();
    final suggestion = const CategoryClassifier().classify(
      text: '${parsed.merchant ?? ''} $rawText',
      categories: categories,
    );
    return OcrResult(
      rawText: rawText,
      isSupported: true,
      merchant: parsed.merchant,
      total: parsed.total,
      occurredAt: parsed.occurredAt,
      items: parsed.items,
      suggestedCategoryId: suggestion?.id,
      suggestedCategoryName: suggestion?.name,
      confidence: parsed.confidence,
    );
  }
}

class ScanReceipt {
  const ScanReceipt(this._scanner, this._categories);

  final ReceiptScanner _scanner;
  final CategoryRepository _categories;

  bool get isSupported => _scanner.isSupported;

  Future<OcrResult> call(Uint8List imageBytes) async {
    if (!_scanner.isSupported) return const OcrResult.unsupported();

    final rawText = await _scanner.recognize(imageBytes);
    final parsed = const ReceiptParser().parse(rawText);
    final categories = await _categories.getCategories();
    final suggestion = const CategoryClassifier().classify(
      text: '${parsed.merchant ?? ''} $rawText',
      categories: categories,
    );

    return OcrResult(
      rawText: rawText,
      isSupported: true,
      merchant: parsed.merchant,
      total: parsed.total,
      occurredAt: parsed.occurredAt,
      items: parsed.items,
      suggestedCategoryId: suggestion?.id,
      suggestedCategoryName: suggestion?.name,
      confidence: parsed.confidence,
    );
  }
}

class CreateTransactionFromReceipt {
  const CreateTransactionFromReceipt(
    this._transactions,
    this._receipts,
    this._currentUser, {
    Uuid uuid = const Uuid(),
  }) : _uuid = uuid;

  final TransactionRepository _transactions;
  final ReceiptRepository _receipts;
  final GetCurrentUser _currentUser;
  final Uuid _uuid;

  Future<Transaction> call({
    required Receipt receipt,
    required String walletId,
    required int amountMinor,
    required String categoryId,
    required DateTime occurredAt,
    String? note,
    String? merchant,
  }) async {
    final user = _currentUser();
    if (user == null) throw StateError('Sesi tidak ditemukan.');
    final now = DateTime.now();
    final transaction = Transaction(
      id: _uuid.v4(),
      walletId: walletId,
      userId: user.id,
      type: TransactionType.expense,
      amount: Money(amountMinor),
      categoryId: categoryId,
      occurredAt: occurredAt,
      note: note ?? '',
      merchant: merchant ?? receipt.merchant,
      receiptId: receipt.id,
      createdAt: now,
      updatedAt: now,
    );
    await _transactions.saveTransaction(transaction);
    await _receipts.saveReceipt(
      receipt.copyWith(
        walletId: walletId,
        transactionId: transaction.id,
        status: ReceiptStatus.attached,
        updatedAt: now,
      ),
    );
    return transaction;
  }
}
