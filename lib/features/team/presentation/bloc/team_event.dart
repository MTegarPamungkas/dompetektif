import 'dart:async';

import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/wallet.dart';

sealed class TeamEvent {
  const TeamEvent();
}

final class TeamStarted extends TeamEvent {
  const TeamStarted();
}

final class TeamWalletsChanged extends TeamEvent {
  const TeamWalletsChanged(this.wallets);

  final List<Wallet> wallets;
}

final class TeamWalletWatchFailed extends TeamEvent {
  const TeamWalletWatchFailed();
}

final class TeamDataChanged extends TeamEvent {
  const TeamDataChanged(this.members, this.notes, this.online);

  final List<WalletMember> members;
  final List<CaseNote> notes;
  final List<OnlineMember> online;
}

final class TeamDataFailed extends TeamEvent {
  const TeamDataFailed();
}

final class TeamWalletSelected extends TeamEvent {
  const TeamWalletSelected(this.walletId);

  final String walletId;
}

final class TeamNoteSendRequested extends TeamEvent {
  const TeamNoteSendRequested(this.body, this.completer);

  final String body;
  final Completer<bool> completer;
}

final class TeamInviteRequested extends TeamEvent {
  const TeamInviteRequested(this.completer);

  final Completer<String?> completer;
}

final class TeamJoinRequested extends TeamEvent {
  const TeamJoinRequested(this.code, this.completer);

  final String code;
  final Completer<bool> completer;
}

final class TeamInviteCodeCleared extends TeamEvent {
  const TeamInviteCodeCleared();
}

final class TeamFailureCleared extends TeamEvent {
  const TeamFailureCleared();
}
