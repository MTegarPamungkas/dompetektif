import 'dart:async';

import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/ledger_filter.dart';

sealed class LedgerEvent {
  const LedgerEvent();
}

final class LedgerStarted extends LedgerEvent {
  const LedgerStarted();
}

final class LedgerDataReceived extends LedgerEvent {
  const LedgerDataReceived(this.entries, this.wallets, this.categories);

  final List<LedgerEntry> entries;
  final List<Wallet> wallets;
  final List<Category> categories;
}

final class LedgerLoadFailed extends LedgerEvent {
  const LedgerLoadFailed();
}

final class LedgerFilterChanged extends LedgerEvent {
  const LedgerFilterChanged(this.filter);

  final LedgerFilter filter;
}

final class LedgerSaveRequested extends LedgerEvent {
  const LedgerSaveRequested(this.transaction, this.completer);

  final Transaction transaction;
  final Completer<bool> completer;
}

final class LedgerDeleteRequested extends LedgerEvent {
  const LedgerDeleteRequested(this.id, this.completer);

  final String id;
  final Completer<bool> completer;
}

final class LedgerFailureCleared extends LedgerEvent {
  const LedgerFailureCleared();
}
