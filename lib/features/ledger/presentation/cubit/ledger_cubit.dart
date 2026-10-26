import 'dart:async';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/ledger_filter.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum LedgerFailure { load, save, delete }

class LedgerState extends Equatable {
  const LedgerState({
    this.entries = const [],
    this.filteredEntries = const [],
    this.wallets = const [],
    this.categories = const [],
    this.filter = const LedgerFilter(),
    this.loading = true,
    this.saving = false,
    this.deleting = false,
    this.failure,
  });

  final List<LedgerEntry> entries;
  final List<LedgerEntry> filteredEntries;
  final List<Wallet> wallets;
  final List<Category> categories;
  final LedgerFilter filter;
  final bool loading;
  final bool saving;
  final bool deleting;
  final LedgerFailure? failure;

  LedgerState copyWith({
    List<LedgerEntry>? entries,
    List<LedgerEntry>? filteredEntries,
    List<Wallet>? wallets,
    List<Category>? categories,
    LedgerFilter? filter,
    bool? loading,
    bool? saving,
    bool? deleting,
    LedgerFailure? failure,
    bool clearFailure = false,
  }) {
    return LedgerState(
      entries: entries ?? this.entries,
      filteredEntries: filteredEntries ?? this.filteredEntries,
      wallets: wallets ?? this.wallets,
      categories: categories ?? this.categories,
      filter: filter ?? this.filter,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    entries,
    filteredEntries,
    wallets,
    categories,
    filter,
    loading,
    saving,
    deleting,
    failure,
  ];
}

class LedgerCubit extends Cubit<LedgerState> {
  LedgerCubit(
    this._watch,
    this._watchWallets,
    this._watchCategories,
    this._save,
    this._delete,
  ) : super(const LedgerState()) {
    _subscription =
        combineLatest3(_watch(), _watchWallets(), _watchCategories(), (
          List<LedgerEntry> entries,
          List<Wallet> wallets,
          List<Category> categories,
        ) {
          return (entries, wallets, categories);
        }).listen(
          (value) {
            final (entries, wallets, categories) = value;
            emit(
              state.copyWith(
                entries: entries,
                wallets: wallets,
                categories: categories,
                filteredEntries: const FilterLedger().call(
                  entries,
                  state.filter,
                ),
                loading: false,
                clearFailure: true,
              ),
            );
          },
          onError: (_) =>
              emit(state.copyWith(loading: false, failure: LedgerFailure.load)),
        );
  }

  final WatchLedger _watch;
  final WatchWallets _watchWallets;
  final WatchCategories _watchCategories;
  final SaveTransaction _save;
  final DeleteTransaction _delete;

  StreamSubscription<(List<LedgerEntry>, List<Wallet>, List<Category>)>?
  _subscription;

  void setQuery(String query) {
    _updateFilter(state.filter.copyWith(query: query));
  }

  void setType(TransactionType? type) {
    _updateFilter(state.filter.copyWith(type: type, clearType: type == null));
  }

  void setCategory(String? categoryId) {
    _updateFilter(
      state.filter.copyWith(
        categoryId: categoryId,
        clearCategory: categoryId == null,
      ),
    );
  }

  void setWallet(String? walletId) {
    _updateFilter(
      state.filter.copyWith(walletId: walletId, clearWallet: walletId == null),
    );
  }

  void setPeriod(DateTime? from, DateTime? to) {
    _updateFilter(
      state.filter.copyWith(
        from: from,
        to: to,
        clearFrom: from == null,
        clearTo: to == null,
      ),
    );
  }

  void clearFilters() {
    _updateFilter(const LedgerFilter());
  }

  void _updateFilter(LedgerFilter filter) {
    emit(
      state.copyWith(
        filter: filter,
        filteredEntries: const FilterLedger().call(state.entries, filter),
        clearFailure: true,
      ),
    );
  }

  Future<bool> saveTransaction(Transaction transaction) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await _save(transaction);
      emit(state.copyWith(saving: false));
      return true;
    } catch (_) {
      emit(state.copyWith(saving: false, failure: LedgerFailure.save));
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    if (state.deleting) return false;
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(id);
      emit(state.copyWith(deleting: false));
      return true;
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: LedgerFailure.delete));
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
