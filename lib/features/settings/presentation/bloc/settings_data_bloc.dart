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
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_data_event.dart';
import 'settings_data_state.dart';

export 'settings_data_event.dart';
export 'settings_data_state.dart';

class SettingsDataBloc extends Bloc<SettingsDataEvent, SettingsDataState> {
  SettingsDataBloc(
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
    on<SettingsDataStarted>(_onStarted);
    on<SettingsDataReceived>(_onDataReceived);
    on<SettingsDataLoadFailed>(_onLoadFailed);
    on<SettingsWalletSaveRequested>(_onWalletSave);
    on<SettingsWalletDeleteRequested>(_onWalletDelete);
    on<SettingsCategorySaveRequested>(_onCategorySave);
    on<SettingsCategoryDeleteRequested>(_onCategoryDelete);
    on<SettingsRuleSaveRequested>(_onRuleSave);
    on<SettingsRuleDeleteRequested>(_onRuleDelete);
    on<SettingsRunDueRequested>(_onRunDue);
    on<SettingsDataFailureCleared>(_onFailureCleared);
    add(const SettingsDataStarted());
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

  Future<void> _onStarted(
    SettingsDataStarted event,
    Emitter<SettingsDataState> emit,
  ) async {
    await _subscription?.cancel();
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
        ).listen((value) {
          final (wallets, categories, rules, transactions) = value;
          add(
            SettingsDataReceived(
              wallets: wallets,
              categories: categories,
              rules: rules,
              transactions: transactions,
            ),
          );
        }, onError: (_) => add(const SettingsDataLoadFailed()));
  }

  void _onDataReceived(
    SettingsDataReceived event,
    Emitter<SettingsDataState> emit,
  ) {
    emit(
      state.copyWith(
        wallets: event.wallets,
        categories: event.categories,
        rules: event.rules,
        transactions: event.transactions,
        balances: _analytics.walletBalances(
          wallets: event.wallets,
          transactions: event.transactions,
        ),
        loading: false,
        clearFailure: true,
      ),
    );
  }

  void _onLoadFailed(
    SettingsDataLoadFailed event,
    Emitter<SettingsDataState> emit,
  ) {
    emit(state.copyWith(loading: false, failure: SettingsDataFailure.load));
  }

  Future<void> _onWalletSave(
    SettingsWalletSaveRequested event,
    Emitter<SettingsDataState> emit,
  ) => _runSave(emit, event.completer, () => _saveWallet(event.wallet));

  Future<void> _onWalletDelete(
    SettingsWalletDeleteRequested event,
    Emitter<SettingsDataState> emit,
  ) => _runDelete(emit, event.completer, () => _deleteWallet(event.id));

  Future<void> _onCategorySave(
    SettingsCategorySaveRequested event,
    Emitter<SettingsDataState> emit,
  ) => _runSave(emit, event.completer, () => _saveCategory(event.category));

  Future<void> _onCategoryDelete(
    SettingsCategoryDeleteRequested event,
    Emitter<SettingsDataState> emit,
  ) => _runDelete(emit, event.completer, () => _deleteCategory(event.id));

  Future<void> _onRuleSave(
    SettingsRuleSaveRequested event,
    Emitter<SettingsDataState> emit,
  ) => _runSave(emit, event.completer, () => _saveRule(event.rule));

  Future<void> _onRuleDelete(
    SettingsRuleDeleteRequested event,
    Emitter<SettingsDataState> emit,
  ) => _runDelete(emit, event.completer, () => _deleteRule(event.id));

  Future<void> _runSave(
    Emitter<SettingsDataState> emit,
    Completer<bool> completer,
    Future<void> Function() action,
  ) async {
    if (state.saving) {
      completer.complete(false);
      return;
    }
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await action();
      emit(state.copyWith(saving: false));
      completer.complete(true);
    } catch (_) {
      emit(state.copyWith(saving: false, failure: SettingsDataFailure.save));
      completer.complete(false);
    }
  }

  Future<void> _runDelete(
    Emitter<SettingsDataState> emit,
    Completer<bool> completer,
    Future<void> Function() action,
  ) async {
    if (state.deleting) {
      completer.complete(false);
      return;
    }
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await action();
      emit(state.copyWith(deleting: false));
      completer.complete(true);
    } catch (_) {
      emit(
        state.copyWith(deleting: false, failure: SettingsDataFailure.delete),
      );
      completer.complete(false);
    }
  }

  Future<void> _onRunDue(
    SettingsRunDueRequested event,
    Emitter<SettingsDataState> emit,
  ) async {
    if (state.runningDue) {
      event.completer.complete(null);
      return;
    }
    emit(state.copyWith(runningDue: true, clearFailure: true));
    try {
      final count = await _runDue();
      emit(state.copyWith(runningDue: false));
      event.completer.complete(count);
    } catch (_) {
      emit(
        state.copyWith(runningDue: false, failure: SettingsDataFailure.runDue),
      );
      event.completer.complete(null);
    }
  }

  void _onFailureCleared(
    SettingsDataFailureCleared event,
    Emitter<SettingsDataState> emit,
  ) {
    emit(state.copyWith(clearFailure: true));
  }

  Future<bool> saveWallet(Wallet wallet) async {
    final completer = Completer<bool>();
    add(SettingsWalletSaveRequested(wallet, completer));
    return completer.future;
  }

  Future<bool> deleteWallet(String id) async {
    final completer = Completer<bool>();
    add(SettingsWalletDeleteRequested(id, completer));
    return completer.future;
  }

  Future<bool> saveCategory(Category category) async {
    final completer = Completer<bool>();
    add(SettingsCategorySaveRequested(category, completer));
    return completer.future;
  }

  Future<bool> deleteCategory(String id) async {
    final completer = Completer<bool>();
    add(SettingsCategoryDeleteRequested(id, completer));
    return completer.future;
  }

  Future<bool> saveRule(RecurringRule rule) async {
    final completer = Completer<bool>();
    add(SettingsRuleSaveRequested(rule, completer));
    return completer.future;
  }

  Future<bool> deleteRule(String id) async {
    final completer = Completer<bool>();
    add(SettingsRuleDeleteRequested(id, completer));
    return completer.future;
  }

  Future<int?> runDueRecurring() async {
    final completer = Completer<int?>();
    add(SettingsRunDueRequested(completer));
    return completer.future;
  }

  void clearFailure() => add(const SettingsDataFailureCleared());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
