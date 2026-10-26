import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:equatable/equatable.dart';

enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly;

  static RecurrenceFrequency fromKey(String? value) {
    return RecurrenceFrequency.values.firstWhere(
      (frequency) => frequency.name == value,
      orElse: () => RecurrenceFrequency.monthly,
    );
  }
}

class RecurringRule extends Equatable {
  const RecurringRule({
    required this.id,
    required this.ownerId,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.frequency,
    required this.nextRunAt,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.toWalletId,
    this.note = '',
    this.merchant = '',
    this.interval = 1,
    this.endAt,
    this.isActive = true,
    this.deletedAt,
  });

  final String id;
  final String ownerId;
  final String walletId;
  final TransactionType type;
  final Money amount;
  final String? categoryId;
  final String? toWalletId;
  final String note;
  final String merchant;
  final RecurrenceFrequency frequency;
  final int interval;
  final DateTime nextRunAt;
  final DateTime? endAt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  bool get isExpired => endAt != null && nextRunAt.isAfter(endAt!);

  RecurringRule copyWith({
    String? id,
    String? ownerId,
    String? walletId,
    TransactionType? type,
    Money? amount,
    String? categoryId,
    String? toWalletId,
    String? note,
    String? merchant,
    RecurrenceFrequency? frequency,
    int? interval,
    DateTime? nextRunAt,
    DateTime? endAt,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearEndAt = false,
    bool clearDeletedAt = false,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      walletId: walletId ?? this.walletId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      toWalletId: toWalletId ?? this.toWalletId,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      endAt: clearEndAt ? null : (endAt ?? this.endAt),
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    walletId,
    type,
    amount,
    categoryId,
    toWalletId,
    note,
    merchant,
    frequency,
    interval,
    nextRunAt,
    endAt,
    isActive,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
