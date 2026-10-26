import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:equatable/equatable.dart';

enum TeamFailure { load, send, invite, join }

class TeamState extends Equatable {
  const TeamState({
    this.wallets = const [],
    this.selectedWalletId,
    this.members = const [],
    this.notes = const [],
    this.online = const [],
    this.loading = true,
    this.sending = false,
    this.inviting = false,
    this.joining = false,
    this.inviteCode,
    this.failure,
  });

  final List<Wallet> wallets;
  final String? selectedWalletId;
  final List<WalletMember> members;
  final List<CaseNote> notes;
  final List<OnlineMember> online;
  final bool loading;
  final bool sending;
  final bool inviting;
  final bool joining;
  final String? inviteCode;
  final TeamFailure? failure;

  TeamState copyWith({
    List<Wallet>? wallets,
    String? selectedWalletId,
    bool clearSelectedWallet = false,
    List<WalletMember>? members,
    List<CaseNote>? notes,
    List<OnlineMember>? online,
    bool? loading,
    bool? sending,
    bool? inviting,
    bool? joining,
    String? inviteCode,
    bool clearInviteCode = false,
    TeamFailure? failure,
    bool clearFailure = false,
  }) {
    return TeamState(
      wallets: wallets ?? this.wallets,
      selectedWalletId: clearSelectedWallet
          ? null
          : (selectedWalletId ?? this.selectedWalletId),
      members: members ?? this.members,
      notes: notes ?? this.notes,
      online: online ?? this.online,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      inviting: inviting ?? this.inviting,
      joining: joining ?? this.joining,
      inviteCode: clearInviteCode ? null : (inviteCode ?? this.inviteCode),
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  Wallet? get selectedWallet {
    for (final wallet in wallets) {
      if (wallet.id == selectedWalletId) return wallet;
    }
    return null;
  }

  Set<String> get onlineUserIds => {for (final member in online) member.userId};

  @override
  List<Object?> get props => [
    wallets,
    selectedWalletId,
    members,
    notes,
    online,
    loading,
    sending,
    inviting,
    joining,
    inviteCode,
    failure,
  ];
}
