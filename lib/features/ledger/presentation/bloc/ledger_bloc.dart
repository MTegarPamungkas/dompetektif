import 'dart:async';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/ledger_filter.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'ledger_event.dart';
import 'ledger_state.dart';

export 'ledger_event.dart';
export 'ledger_state.dart';

class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  LedgerBloc(
    this._watch,
    this._watchWallets,
    this._watchCategories,
    this._save,
    this._delete,
  ) : super(const LedgerState()) {
    on<LedgerStarted>(_onStarted);
    on<LedgerDataReceived>(_onDataReceived);
    on<LedgerLoadFailed>(_onLoadFailed);
    on<LedgerFilterChanged>(_onFilterChanged);
    on<LedgerSaveRequested>(_onSaveRequested);
    on<LedgerDeleteRequested>(_onDeleteRequested);
    on<LedgerFailureCleared>(_onFailureCleared);
    add(const LedgerStarted());
  }

  final WatchLedger _watch;
  final WatchWallets _watchWallets;
  final WatchCategories _watchCategories;
  final SaveTransaction _save;
  final DeleteTransaction _delete;

  StreamSubscription<(List<LedgerEntry>, List<Wallet>, List<Category>)>?
  _subscription;

  Future<void> _onStarted(
    LedgerStarted event,
    Emitter<LedgerState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription =
        combineLatest3(_watch(), _watchWallets(), _watchCategories(), (
          List<LedgerEntry> entries,
          List<Wallet> wallets,
          List<Category> categories,
        ) {
          return (entries, wallets, categories);
        }).listen((value) {
          final (entries, wallets, categories) = value;
          add(LedgerDataReceived(entries, wallets, categories));
        }, onError: (_) => add(const LedgerLoadFailed()));
  }

  void _onDataReceived(LedgerDataReceived event, Emitter<LedgerState> emit) {
    emit(
      state.copyWith(
        entries: event.entries,
        wallets: event.wallets,
        categories: event.categories,
        filteredEntries: const FilterLedger().call(event.entries, state.filter),
        loading: false,
        clearFailure: true,
      ),
    );
  }

  void _onLoadFailed(LedgerLoadFailed event, Emitter<LedgerState> emit) {
    emit(state.copyWith(loading: false, failure: LedgerFailure.load));
  }

  void _onFilterChanged(LedgerFilterChanged event, Emitter<LedgerState> emit) {
    emit(
      state.copyWith(
        filter: event.filter,
        filteredEntries: const FilterLedger().call(state.entries, event.filter),
        clearFailure: true,
      ),
    );
  }

  Future<void> _onSaveRequested(
    LedgerSaveRequested event,
    Emitter<LedgerState> emit,
  ) async {
    if (state.saving) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await _save(event.transaction);
      emit(state.copyWith(saving: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(saving: false, failure: LedgerFailure.save));
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteRequested(
    LedgerDeleteRequested event,
    Emitter<LedgerState> emit,
  ) async {
    if (state.deleting) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(event.id);
      emit(state.copyWith(deleting: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: LedgerFailure.delete));
      event.completer.complete(false);
    }
  }

  void _onFailureCleared(
    LedgerFailureCleared event,
    Emitter<LedgerState> emit,
  ) {
    emit(state.copyWith(clearFailure: true));
  }

  void setQuery(String query) =>
      add(LedgerFilterChanged(state.filter.copyWith(query: query)));

  void setType(TransactionType? type) => add(
    LedgerFilterChanged(
      state.filter.copyWith(type: type, clearType: type == null),
    ),
  );

  void setCategory(String? categoryId) => add(
    LedgerFilterChanged(
      state.filter.copyWith(
        categoryId: categoryId,
        clearCategory: categoryId == null,
      ),
    ),
  );

  void setWallet(String? walletId) => add(
    LedgerFilterChanged(
      state.filter.copyWith(walletId: walletId, clearWallet: walletId == null),
    ),
  );

  void setPeriod(DateTime? from, DateTime? to) => add(
    LedgerFilterChanged(
      state.filter.copyWith(
        from: from,
        to: to,
        clearFrom: from == null,
        clearTo: to == null,
      ),
    ),
  );

  void clearFilters() => add(const LedgerFilterChanged(LedgerFilter()));

  Future<bool> saveTransaction(Transaction transaction) async {
    final completer = Completer<bool>();
    add(LedgerSaveRequested(transaction, completer));
    return completer.future;
  }

  Future<bool> deleteTransaction(String id) async {
    final completer = Completer<bool>();
    add(LedgerDeleteRequested(id, completer));
    return completer.future;
  }

  void clearFailure() => add(const LedgerFailureCleared());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
