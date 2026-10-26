import 'dart:async';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

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

class TeamCubit extends Cubit<TeamState> {
  TeamCubit(
    this._watchWallets,
    this._watchTeam,
    this._sendNote,
    this._createInvite,
    this._joinWallet,
    this._currentUser, {
    Uuid uuid = const Uuid(),
  }) : _uuid = uuid,
       super(const TeamState()) {
    _walletSubscription = _watchWallets().listen(
      (wallets) {
        final shared = wallets.where((wallet) => wallet.isShared).toList();
        final selected =
            shared.any((wallet) => wallet.id == state.selectedWalletId)
            ? state.selectedWalletId
            : (shared.isEmpty ? null : shared.first.id);
        emit(
          state.copyWith(
            wallets: shared,
            selectedWalletId: selected,
            clearSelectedWallet: selected == null,
            loading: shared.isEmpty ? false : state.loading,
            clearFailure: true,
          ),
        );
        _subscribeWallet(selected);
      },
      onError: (_) =>
          emit(state.copyWith(loading: false, failure: TeamFailure.load)),
    );
  }

  final WatchWallets _watchWallets;
  final WatchTeam _watchTeam;
  final SendCaseNote _sendNote;
  final CreateWalletInvite _createInvite;
  final JoinSharedWallet _joinWallet;
  final GetCurrentUser _currentUser;
  final Uuid _uuid;

  StreamSubscription<List<Wallet>>? _walletSubscription;
  StreamSubscription<(List<WalletMember>, List<CaseNote>, List<OnlineMember>)>?
  _teamSubscription;
  String? _subscribedWalletId;

  void _subscribeWallet(String? walletId) {
    if (_subscribedWalletId == walletId && _teamSubscription != null) return;
    _teamSubscription?.cancel();
    _teamSubscription = null;
    _subscribedWalletId = walletId;
    if (walletId == null) {
      emit(
        state.copyWith(
          members: const [],
          notes: const [],
          online: const [],
          loading: false,
        ),
      );
      return;
    }

    _teamSubscription =
        combineLatest3(
          _watchTeam.members(walletId),
          _watchTeam.notes(walletId),
          _watchTeam.presence(walletId),
          (
            List<WalletMember> members,
            List<CaseNote> notes,
            List<OnlineMember> online,
          ) {
            return (members, notes, online);
          },
        ).listen(
          (value) {
            final (members, notes, online) = value;
            emit(
              state.copyWith(
                members: members,
                notes: notes,
                online: online,
                loading: false,
                clearFailure: true,
              ),
            );
          },
          onError: (_) =>
              emit(state.copyWith(loading: false, failure: TeamFailure.load)),
        );
  }

  void selectWallet(String walletId) {
    if (walletId == state.selectedWalletId) return;
    emit(
      state.copyWith(
        selectedWalletId: walletId,
        loading: true,
        clearInviteCode: true,
        clearFailure: true,
      ),
    );
    _subscribeWallet(walletId);
  }

  Future<bool> sendNote(String body) async {
    final walletId = state.selectedWalletId;
    final user = _currentUser();
    if (walletId == null ||
        user == null ||
        body.trim().isEmpty ||
        state.sending) {
      return false;
    }
    emit(state.copyWith(sending: true, clearFailure: true));
    final now = DateTime.now();
    try {
      await _sendNote(
        CaseNote(
          id: _uuid.v4(),
          walletId: walletId,
          userId: user.id,
          authorName: user.displayName,
          avatarUrl: user.avatarUrl,
          body: body,
          createdAt: now,
          updatedAt: now,
        ),
      );
      emit(state.copyWith(sending: false));
      return true;
    } catch (_) {
      emit(state.copyWith(sending: false, failure: TeamFailure.send));
      return false;
    }
  }

  Future<String?> createInvite() async {
    final walletId = state.selectedWalletId;
    if (walletId == null || state.inviting) return null;
    emit(
      state.copyWith(inviting: true, clearInviteCode: true, clearFailure: true),
    );
    try {
      final code = await _createInvite(walletId);
      emit(state.copyWith(inviting: false, inviteCode: code));
      return code;
    } catch (_) {
      emit(state.copyWith(inviting: false, failure: TeamFailure.invite));
      return null;
    }
  }

  Future<bool> joinWallet(String code) async {
    if (state.joining) return false;
    emit(state.copyWith(joining: true, clearFailure: true));
    try {
      await _joinWallet(code);
      emit(state.copyWith(joining: false));
      return true;
    } catch (_) {
      emit(state.copyWith(joining: false, failure: TeamFailure.join));
      return false;
    }
  }

  void clearInviteCode() => emit(state.copyWith(clearInviteCode: true));

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  @override
  Future<void> close() async {
    await _walletSubscription?.cancel();
    await _teamSubscription?.cancel();
    return super.close();
  }
}
