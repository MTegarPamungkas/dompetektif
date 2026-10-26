import 'dart:async';

import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';

sealed class SettingsDataEvent {
  const SettingsDataEvent();
}

final class SettingsDataStarted extends SettingsDataEvent {
  const SettingsDataStarted();
}

final class SettingsDataReceived extends SettingsDataEvent {
  const SettingsDataReceived({
    required this.wallets,
    required this.categories,
    required this.rules,
    required this.transactions,
  });

  final List<Wallet> wallets;
  final List<Category> categories;
  final List<RecurringRule> rules;
  final List<Transaction> transactions;
}

final class SettingsDataLoadFailed extends SettingsDataEvent {
  const SettingsDataLoadFailed();
}

final class SettingsWalletSaveRequested extends SettingsDataEvent {
  const SettingsWalletSaveRequested(this.wallet, this.completer);

  final Wallet wallet;
  final Completer<bool> completer;
}

final class SettingsWalletDeleteRequested extends SettingsDataEvent {
  const SettingsWalletDeleteRequested(this.id, this.completer);

  final String id;
  final Completer<bool> completer;
}

final class SettingsCategorySaveRequested extends SettingsDataEvent {
  const SettingsCategorySaveRequested(this.category, this.completer);

  final Category category;
  final Completer<bool> completer;
}

final class SettingsCategoryDeleteRequested extends SettingsDataEvent {
  const SettingsCategoryDeleteRequested(this.id, this.completer);

  final String id;
  final Completer<bool> completer;
}

final class SettingsRuleSaveRequested extends SettingsDataEvent {
  const SettingsRuleSaveRequested(this.rule, this.completer);

  final RecurringRule rule;
  final Completer<bool> completer;
}

final class SettingsRuleDeleteRequested extends SettingsDataEvent {
  const SettingsRuleDeleteRequested(this.id, this.completer);

  final String id;
  final Completer<bool> completer;
}

final class SettingsRunDueRequested extends SettingsDataEvent {
  const SettingsRunDueRequested(this.completer);

  final Completer<int?> completer;
}

final class SettingsDataFailureCleared extends SettingsDataEvent {
  const SettingsDataFailureCleared();
}
