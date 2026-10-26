import 'dart:async';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/ledger_analytics.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:dompetektif/domain/usecases/recurring_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum SettingsDataFailure { load, save, delete, runDue }

class SettingsDataState extends Equatable {
  const SettingsDataState({
    this.wallets = const [],
    this.balances = const [],
    this.categories = const [],
    this.rules = const [],
    this.transactions = const [],
    this.loading = true,
    this.saving = false,
    this.deleting = false,
    this.runningDue = false,
    this.failure,
  });

  final List<Wallet> wallets;
  final List<WalletBalance> balances;
  final List<Category> categories;
  final List<RecurringRule> rules;
  final List<Transaction> transactions;
  final bool loading;
  final bool saving;
  final bool deleting;
  final bool runningDue;
  final SettingsDataFailure? failure;

  SettingsDataState copyWith({
    List<Wallet>? wallets,
    List<WalletBalance>? balances,
    List<Category>? categories,
    List<RecurringRule>? rules,
    List<Transaction>? transactions,
    bool? loading,
    bool? saving,
    bool? deleting,
    bool? runningDue,
    SettingsDataFailure? failure,
    bool clearFailure = false,
  }) {
    return SettingsDataState(
      wallets: wallets ?? this.wallets,
      balances: balances ?? this.balances,
      categories: categories ?? this.categories,
      rules: rules ?? this.rules,
      transactions: transactions ?? this.transactions,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      runningDue: runningDue ?? this.runningDue,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    wallets,
    balances,
    categories,
    rules,
    transactions,
    loading,
    saving,
    deleting,
    runningDue,
    failure,
  ];
}

class SettingsDataCubit extends Cubit<SettingsDataState> {
  SettingsDataCubit(
    this._watchWallets,
    this._watchCategories,
    this._watchRules,
    this._watchTransactions,
    this._saveWallet,
    this._deleteWallet,
    this._saveCategory,
    this._deleteCategory,
    this._saveRule,
    this._deleteRule,
    this._runDue, {
    LedgerAnalytics analytics = const LedgerAnalytics(),
  }) : _analytics = analytics,
       super(const SettingsDataState()) {
    _subscription =
        combineLatest4(
          _watchWallets(),
          _watchCategories(),
          _watchRules(),
          _watchTransactions(),
          (
            List<Wallet> wallets,
            List<Category> categories,
            List<RecurringRule> rules,
            List<Transaction> transactions,
          ) {
            return (wallets, categories, rules, transactions);
          },
        ).listen(
          (value) {
            final (wallets, categories, rules, transactions) = value;
            emit(
              state.copyWith(
                wallets: wallets,
                categories: categories,
                rules: rules,
                transactions: transactions,
                balances: _analytics.walletBalances(
                  wallets: wallets,
                  transactions: transactions,
                ),
                loading: false,
                clearFailure: true,
              ),
            );
          },
          onError: (_) => emit(
            state.copyWith(loading: false, failure: SettingsDataFailure.load),
          ),
        );
  }

  final WatchWallets _watchWallets;
  final WatchCategories _watchCategories;
  final WatchRecurringRules _watchRules;
  final WatchTransactions _watchTransactions;
  final SaveWallet _saveWallet;
  final DeleteWallet _deleteWallet;
  final SaveCategory _saveCategory;
  final DeleteCategory _deleteCategory;
  final SaveRecurringRule _saveRule;
  final DeleteRecurringRule _deleteRule;
  final RunDueRecurring _runDue;
  final LedgerAnalytics _analytics;

  StreamSubscription<
    (List<Wallet>, List<Category>, List<RecurringRule>, List<Transaction>)
  >?
  _subscription;

  Future<bool> saveWallet(Wallet wallet) => _runSave(() => _saveWallet(wallet));

  Future<bool> deleteWallet(String id) => _runDelete(() => _deleteWallet(id));

  Future<bool> saveCategory(Category category) =>
      _runSave(() => _saveCategory(category));

  Future<bool> deleteCategory(String id) =>
      _runDelete(() => _deleteCategory(id));

  Future<bool> saveRule(RecurringRule rule) => _runSave(() => _saveRule(rule));

  Future<bool> deleteRule(String id) => _runDelete(() => _deleteRule(id));

  Future<bool> _runSave(Future<void> Function() action) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await action();
      emit(state.copyWith(saving: false));
      return true;
    } catch (_) {
      emit(state.copyWith(saving: false, failure: SettingsDataFailure.save));
      return false;
    }
  }

  Future<bool> _runDelete(Future<void> Function() action) async {
    if (state.deleting) return false;
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await action();
      emit(state.copyWith(deleting: false));
      return true;
    } catch (_) {
      emit(
        state.copyWith(deleting: false, failure: SettingsDataFailure.delete),
      );
      return false;
    }
  }

  Future<int?> runDueRecurring() async {
    if (state.runningDue) return null;
    emit(state.copyWith(runningDue: true, clearFailure: true));
    try {
      final count = await _runDue();
      emit(state.copyWith(runningDue: false));
      return count;
    } catch (_) {
      emit(
        state.copyWith(runningDue: false, failure: SettingsDataFailure.runDue),
      );
      return null;
    }
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
