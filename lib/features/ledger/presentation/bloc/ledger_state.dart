import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/ledger_filter.dart';
import 'package:equatable/equatable.dart';

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
