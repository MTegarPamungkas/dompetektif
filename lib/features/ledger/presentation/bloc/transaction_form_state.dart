import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:equatable/equatable.dart';

enum TransactionFormFailure { load, save, delete }

class TransactionFormState extends Equatable {
  const TransactionFormState({
    this.wallets = const [],
    this.categories = const [],
    this.entry,
    this.loading = true,
    this.saving = false,
    this.deleting = false,
    this.failure,
  });

  final List<Wallet> wallets;
  final List<Category> categories;
  final LedgerEntry? entry;
  final bool loading;
  final bool saving;
  final bool deleting;
  final TransactionFormFailure? failure;

  bool get isEditing => entry != null;

  TransactionFormState copyWith({
    List<Wallet>? wallets,
    List<Category>? categories,
    LedgerEntry? entry,
    bool? loading,
    bool? saving,
    bool? deleting,
    TransactionFormFailure? failure,
    bool clearFailure = false,
  }) {
    return TransactionFormState(
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      entry: entry ?? this.entry,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    wallets,
    categories,
    entry,
    loading,
    saving,
    deleting,
    failure,
  ];
}
