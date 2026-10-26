import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:equatable/equatable.dart';

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
