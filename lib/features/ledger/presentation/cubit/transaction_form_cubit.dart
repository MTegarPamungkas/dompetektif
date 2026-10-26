import 'dart:async';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

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

class TransactionFormCubit extends Cubit<TransactionFormState> {
  TransactionFormCubit(
    this._watchWallets,
    this._watchCategories,
    this._getEntry,
    this._save,
    this._delete,
    this._currentUser,
    this.transactionId, {
    Uuid uuid = const Uuid(),
  }) : _uuid = uuid,
       super(const TransactionFormState()) {
    _subscription =
        combineLatest2(_watchWallets(), _watchCategories(), (
          List<Wallet> wallets,
          List<Category> categories,
        ) {
          return (wallets, categories);
        }).listen(
          (value) {
            final (wallets, categories) = value;
            emit(
              state.copyWith(
                wallets: wallets,
                categories: categories,
                loading: transactionId == null ? false : state.loading,
                clearFailure: true,
              ),
            );
          },
          onError: (_) => emit(
            state.copyWith(
              loading: false,
              failure: TransactionFormFailure.load,
            ),
          ),
        );
    if (transactionId != null) {
      _loadEntry();
    }
  }

  final WatchWallets _watchWallets;
  final WatchCategories _watchCategories;
  final GetLedgerEntry _getEntry;
  final SaveTransaction _save;
  final DeleteTransaction _delete;
  final GetCurrentUser _currentUser;
  final String? transactionId;
  final Uuid _uuid;

  StreamSubscription<(List<Wallet>, List<Category>)>? _subscription;

  Future<void> _loadEntry() async {
    try {
      final entry = await _getEntry(transactionId!);
      emit(state.copyWith(entry: entry, loading: false));
    } catch (_) {
      emit(
        state.copyWith(loading: false, failure: TransactionFormFailure.load),
      );
    }
  }

  Future<bool> save({
    required TransactionType type,
    required int amountMinor,
    required String walletId,
    String? toWalletId,
    String? categoryId,
    required DateTime occurredAt,
    required String note,
    required String merchant,
  }) async {
    if (state.saving) return false;
    final user = _currentUser();
    if (user == null) {
      emit(state.copyWith(failure: TransactionFormFailure.save));
      return false;
    }
    emit(state.copyWith(saving: true, clearFailure: true));
    final now = DateTime.now();
    final existing = state.entry?.transaction;
    final transaction = Transaction(
      id: existing?.id ?? _uuid.v4(),
      walletId: walletId,
      userId: existing?.userId ?? user.id,
      type: type,
      amount: Money(amountMinor),
      categoryId: type == TransactionType.transfer ? null : categoryId,
      toWalletId: type == TransactionType.transfer ? toWalletId : null,
      occurredAt: occurredAt,
      note: note.trim(),
      merchant: merchant.trim(),
      receiptId: existing?.receiptId,
      recurringRuleId: existing?.recurringRuleId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await _save(transaction);
      emit(state.copyWith(saving: false));
      return true;
    } catch (_) {
      emit(state.copyWith(saving: false, failure: TransactionFormFailure.save));
      return false;
    }
  }

  Future<bool> delete() async {
    final id = transactionId;
    if (id == null || state.deleting) return false;
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(id);
      emit(state.copyWith(deleting: false));
      return true;
    } catch (_) {
      emit(
        state.copyWith(deleting: false, failure: TransactionFormFailure.delete),
      );
      return false;
    }
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
