import 'dart:async';

import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';

sealed class TransactionFormEvent {
  const TransactionFormEvent();
}

final class TransactionFormStarted extends TransactionFormEvent {
  const TransactionFormStarted();
}

final class TransactionFormDataReceived extends TransactionFormEvent {
  const TransactionFormDataReceived(this.wallets, this.categories);

  final List<Wallet> wallets;
  final List<Category> categories;
}

final class TransactionFormLoadFailed extends TransactionFormEvent {
  const TransactionFormLoadFailed();
}

final class TransactionFormEntryLoaded extends TransactionFormEvent {
  const TransactionFormEntryLoaded(this.entry);

  final LedgerEntry entry;
}

final class TransactionFormSaveRequested extends TransactionFormEvent {
  const TransactionFormSaveRequested({
    required this.type,
    required this.amountMinor,
    required this.walletId,
    required this.occurredAt,
    required this.note,
    required this.merchant,
    required this.completer,
    this.toWalletId,
    this.categoryId,
  });

  final TransactionType type;
  final int amountMinor;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final DateTime occurredAt;
  final String note;
  final String merchant;
  final Completer<bool> completer;
}

final class TransactionFormDeleteRequested extends TransactionFormEvent {
  const TransactionFormDeleteRequested(this.completer);

  final Completer<bool> completer;
}

final class TransactionFormFailureCleared extends TransactionFormEvent {
  const TransactionFormFailureCleared();
}
