import 'dart:async';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'transaction_form_event.dart';
import 'transaction_form_state.dart';

export 'transaction_form_event.dart';
export 'transaction_form_state.dart';

class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  TransactionFormBloc(
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
    on<TransactionFormStarted>(_onStarted);
    on<TransactionFormDataReceived>(_onDataReceived);
    on<TransactionFormLoadFailed>(_onLoadFailed);
    on<TransactionFormEntryLoaded>(_onEntryLoaded);
    on<TransactionFormSaveRequested>(_onSaveRequested);
    on<TransactionFormDeleteRequested>(_onDeleteRequested);
    on<TransactionFormFailureCleared>(_onFailureCleared);
    add(const TransactionFormStarted());
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

  Future<void> _onStarted(
    TransactionFormStarted event,
    Emitter<TransactionFormState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription =
        combineLatest2(_watchWallets(), _watchCategories(), (
          List<Wallet> wallets,
          List<Category> categories,
        ) {
          return (wallets, categories);
        }).listen((value) {
          final (wallets, categories) = value;
          add(TransactionFormDataReceived(wallets, categories));
        }, onError: (_) => add(const TransactionFormLoadFailed()));
    if (transactionId != null) {
      await _loadEntry(emit);
    }
  }

  Future<void> _loadEntry(Emitter<TransactionFormState> emit) async {
    try {
      final entry = await _getEntry(transactionId!);
      emit(state.copyWith(entry: entry, loading: false));
    } catch (_) {
      emit(
        state.copyWith(loading: false, failure: TransactionFormFailure.load),
      );
    }
  }

  void _onDataReceived(
    TransactionFormDataReceived event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(
      state.copyWith(
        wallets: event.wallets,
        categories: event.categories,
        loading: transactionId == null ? false : state.loading,
        clearFailure: true,
      ),
    );
  }

  void _onLoadFailed(
    TransactionFormLoadFailed event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(loading: false, failure: TransactionFormFailure.load));
  }

  void _onEntryLoaded(
    TransactionFormEntryLoaded event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(entry: event.entry, loading: false));
  }

  Future<void> _onSaveRequested(
    TransactionFormSaveRequested event,
    Emitter<TransactionFormState> emit,
  ) async {
    if (state.saving) {
      event.completer.complete(false);
      return;
    }
    final user = _currentUser();
    if (user == null) {
      emit(state.copyWith(failure: TransactionFormFailure.save));
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(saving: true, clearFailure: true));
    final now = DateTime.now();
    final existing = state.entry?.transaction;
    final transaction = Transaction(
      id: existing?.id ?? _uuid.v4(),
      walletId: event.walletId,
      userId: existing?.userId ?? user.id,
      type: event.type,
      amount: Money(event.amountMinor),
      categoryId: event.type == TransactionType.transfer
          ? null
          : event.categoryId,
      toWalletId: event.type == TransactionType.transfer
          ? event.toWalletId
          : null,
      occurredAt: event.occurredAt,
      note: event.note.trim(),
      merchant: event.merchant.trim(),
      receiptId: existing?.receiptId,
      recurringRuleId: existing?.recurringRuleId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await _save(transaction);
      emit(state.copyWith(saving: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(saving: false, failure: TransactionFormFailure.save));
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteRequested(
    TransactionFormDeleteRequested event,
    Emitter<TransactionFormState> emit,
  ) async {
    final id = transactionId;
    if (id == null || state.deleting) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(id);
      emit(state.copyWith(deleting: false));
      event.completer.complete(true);
    } catch (_) {
      emit(
        state.copyWith(deleting: false, failure: TransactionFormFailure.delete),
      );
      event.completer.complete(false);
    }
  }

  void _onFailureCleared(
    TransactionFormFailureCleared event,
    Emitter<TransactionFormState> emit,
  ) {
    emit(state.copyWith(clearFailure: true));
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
    final completer = Completer<bool>();
    add(
      TransactionFormSaveRequested(
        type: type,
        amountMinor: amountMinor,
        walletId: walletId,
        toWalletId: toWalletId,
        categoryId: categoryId,
        occurredAt: occurredAt,
        note: note,
        merchant: merchant,
        completer: completer,
      ),
    );
    return completer.future;
  }

  Future<bool> delete() async {
    final completer = Completer<bool>();
    add(TransactionFormDeleteRequested(completer));
    return completer.future;
  }

  void clearFailure() => add(const TransactionFormFailureCleared());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
