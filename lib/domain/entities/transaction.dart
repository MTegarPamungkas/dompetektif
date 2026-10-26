import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:equatable/equatable.dart';

enum TransactionType {
  expense,
  income,
  transfer;

  static TransactionType fromKey(String? value) {
    return TransactionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.toWalletId,
    this.note = '',
    this.merchant = '',
    this.receiptId,
    this.recurringRuleId,
    this.deletedAt,
    this.isPending = false,
  });

  final String id;
  final String walletId;
  final String userId;
  final TransactionType type;
  final Money amount;
  final String? categoryId;
  final String? toWalletId;
  final DateTime occurredAt;
  final String note;
  final String merchant;
  final String? receiptId;
  final String? recurringRuleId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Local-only flag: the row is waiting in the outbox.
  final bool isPending;

  bool get isDeleted => deletedAt != null;

  bool get isTransfer => type == TransactionType.transfer;

  String get displayTitle {
    if (merchant.trim().isNotEmpty) return merchant.trim();
    if (note.trim().isNotEmpty) return note.trim();
    return '';
  }

  Transaction copyWith({
    String? id,
    String? walletId,
    String? userId,
    TransactionType? type,
    Money? amount,
    String? categoryId,
    String? toWalletId,
    DateTime? occurredAt,
    String? note,
    String? merchant,
    String? receiptId,
    String? recurringRuleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? isPending,
    bool clearCategory = false,
    bool clearToWallet = false,
    bool clearReceipt = false,
  }) {
    return Transaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      toWalletId: clearToWallet ? null : (toWalletId ?? this.toWalletId),
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      receiptId: clearReceipt ? null : (receiptId ?? this.receiptId),
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      isPending: isPending ?? this.isPending,
    );
  }

  @override
  List<Object?> get props => [
    id,
    walletId,
    userId,
    type,
    amount,
    categoryId,
    toWalletId,
    occurredAt,
    note,
    merchant,
    receiptId,
    recurringRuleId,
    createdAt,
    updatedAt,
    deletedAt,
    isPending,
  ];
}

class LedgerEntry extends Equatable {
  const LedgerEntry({
    required this.transaction,
    required this.wallet,
    this.toWallet,
    this.category,
  });

  final Transaction transaction;
  final Wallet wallet;
  final Wallet? toWallet;
  final Category? category;

  bool get hasReceipt => transaction.receiptId != null;

  @override
  List<Object?> get props => [transaction, wallet, toWallet, category];
}
