import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:equatable/equatable.dart';

class LedgerFilter extends Equatable {
  const LedgerFilter({
    this.query = '',
    this.type,
    this.categoryId,
    this.walletId,
    this.from,
    this.to,
  });

  final String query;
  final TransactionType? type;
  final String? categoryId;
  final String? walletId;
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty =>
      query.trim().isEmpty &&
      type == null &&
      categoryId == null &&
      walletId == null &&
      from == null &&
      to == null;

  LedgerFilter copyWith({
    String? query,
    TransactionType? type,
    String? categoryId,
    String? walletId,
    DateTime? from,
    DateTime? to,
    bool clearType = false,
    bool clearCategory = false,
    bool clearWallet = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return LedgerFilter(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      walletId: clearWallet ? null : (walletId ?? this.walletId),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }

  @override
  List<Object?> get props => [query, type, categoryId, walletId, from, to];
}

class FilterLedger {
  const FilterLedger();

  List<LedgerEntry> call(List<LedgerEntry> entries, LedgerFilter filter) {
    final query = filter.query.trim().toLowerCase();
    final result = entries.where((entry) {
      final transaction = entry.transaction;
      if (transaction.isDeleted) return false;

      if (filter.type != null && transaction.type != filter.type) return false;

      if (filter.categoryId != null &&
          transaction.categoryId != filter.categoryId) {
        return false;
      }

      if (filter.walletId != null &&
          transaction.walletId != filter.walletId &&
          transaction.toWalletId != filter.walletId) {
        return false;
      }

      if (filter.from != null &&
          transaction.occurredAt.isBefore(filter.from!)) {
        return false;
      }

      if (filter.to != null) {
        final end = DateTime(
          filter.to!.year,
          filter.to!.month,
          filter.to!.day,
          23,
          59,
          59,
          999,
        );
        if (transaction.occurredAt.isAfter(end)) return false;
      }

      if (query.isEmpty) return true;

      final haystack = [
        transaction.merchant,
        transaction.note,
        entry.category?.name ?? '',
        entry.wallet.name,
        entry.toWallet?.name ?? '',
        transaction.amount.amountMinor.toString(),
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();

    result.sort(
      (a, b) => b.transaction.occurredAt.compareTo(a.transaction.occurredAt),
    );
    return result;
  }
}
