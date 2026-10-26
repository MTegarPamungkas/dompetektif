import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:equatable/equatable.dart';

enum BudgetStatus { safe, warning, over }

class Budget extends Equatable {
  const Budget({
    required this.id,
    required this.ownerId,
    required this.categoryId,
    required this.amount,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
    this.walletId,
    this.alertThreshold = 0.8,
    this.deletedAt,
  });

  final String id;
  final String ownerId;
  final String? walletId;
  final String categoryId;
  final Money amount;
  final DateTime month;
  final double alertThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Budget copyWith({
    String? id,
    String? ownerId,
    String? walletId,
    String? categoryId,
    Money? amount,
    DateTime? month,
    double? alertThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearWallet = false,
    bool clearDeletedAt = false,
  }) {
    return Budget(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      alertThreshold: alertThreshold ?? this.alertThreshold,
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
    categoryId,
    amount,
    month,
    alertThreshold,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}

class BudgetProgress extends Equatable {
  const BudgetProgress({
    required this.budget,
    required this.category,
    required this.spent,
    required this.ratio,
    required this.status,
  });

  final Budget budget;
  final Category category;
  final Money spent;
  final double ratio;
  final BudgetStatus status;

  Money get remaining {
    final remaining = budget.amount.amountMinor - spent.amountMinor;
    return Money(remaining, currency: budget.amount.currency);
  }

  bool get isOver => remaining.isNegative;

  @override
  List<Object?> get props => [budget, category, spent, ratio, status];
}
