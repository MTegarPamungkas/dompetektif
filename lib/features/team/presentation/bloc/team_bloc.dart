import 'dart:async';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'team_event.dart';
import 'team_state.dart';

export 'team_event.dart';
export 'team_state.dart';

class TeamBloc extends Bloc<TeamEvent, TeamState> {
  TeamBloc(
    this._watchWallets,
    this._watchTeam,
    this._sendNote,
    this._createInvite,
    this._joinWallet,
    this._currentUser, {
    Uuid uuid = const Uuid(),
  }) : _uuid = uuid,
       super(const TeamState()) {
    on<TeamStarted>(_onStarted);
    on<TeamWalletsChanged>(_onWalletsChanged);
    on<TeamWalletWatchFailed>(_onWalletWatchFailed);
    on<TeamDataChanged>(_onDataChanged);
    on<TeamDataFailed>(_onDataFailed);
    on<TeamWalletSelected>(_onWalletSelected);
    on<TeamNoteSendRequested>(_onNoteSendRequested);
    on<TeamInviteRequested>(_onInviteRequested);
    on<TeamJoinRequested>(_onJoinRequested);
    on<TeamInviteCodeCleared>(_onInviteCodeCleared);
    on<TeamFailureCleared>(_onFailureCleared);
    add(const TeamStarted());
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

  Future<void> _onStarted(TeamStarted event, Emitter<TeamState> emit) async {
    await _walletSubscription?.cancel();
    _walletSubscription = _watchWallets().listen(
      (wallets) => add(TeamWalletsChanged(wallets)),
      onError: (_) => add(const TeamWalletWatchFailed()),
    );
  }

  void _onWalletsChanged(TeamWalletsChanged event, Emitter<TeamState> emit) {
    final shared = event.wallets.where((wallet) => wallet.isShared).toList();
    final selected = shared.any((wallet) => wallet.id == state.selectedWalletId)
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
    _subscribeWallet(selected, emit);
  }

  void _onWalletWatchFailed(
    TeamWalletWatchFailed event,
    Emitter<TeamState> emit,
  ) {
    emit(state.copyWith(loading: false, failure: TeamFailure.load));
  }

  void _subscribeWallet(String? walletId, Emitter<TeamState> emit) {
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
        ).listen((value) {
          final (members, notes, online) = value;
          add(TeamDataChanged(members, notes, online));
        }, onError: (_) => add(const TeamDataFailed()));
  }

  void _onDataChanged(TeamDataChanged event, Emitter<TeamState> emit) {
    emit(
      state.copyWith(
        members: event.members,
        notes: event.notes,
        online: event.online,
        loading: false,
        clearFailure: true,
      ),
    );
  }

  void _onDataFailed(TeamDataFailed event, Emitter<TeamState> emit) {
    emit(state.copyWith(loading: false, failure: TeamFailure.load));
  }

  void _onWalletSelected(TeamWalletSelected event, Emitter<TeamState> emit) {
    if (event.walletId == state.selectedWalletId) return;
    emit(
      state.copyWith(
        selectedWalletId: event.walletId,
        loading: true,
        clearInviteCode: true,
        clearFailure: true,
      ),
    );
    _subscribeWallet(event.walletId, emit);
  }

  Future<void> _onNoteSendRequested(
    TeamNoteSendRequested event,
    Emitter<TeamState> emit,
  ) async {
    final walletId = state.selectedWalletId;
    final user = _currentUser();
    if (walletId == null ||
        user == null ||
        event.body.trim().isEmpty ||
        state.sending) {
      event.completer.complete(false);
      return;
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
          body: event.body,
          createdAt: now,
          updatedAt: now,
        ),
      );
      emit(state.copyWith(sending: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(sending: false, failure: TeamFailure.send));
      event.completer.complete(false);
    }
  }

  Future<void> _onInviteRequested(
    TeamInviteRequested event,
    Emitter<TeamState> emit,
  ) async {
    final walletId = state.selectedWalletId;
    if (walletId == null || state.inviting) {
      event.completer.complete(null);
      return;
    }
    emit(
      state.copyWith(inviting: true, clearInviteCode: true, clearFailure: true),
    );
    try {
      final code = await _createInvite(walletId);
      emit(state.copyWith(inviting: false, inviteCode: code));
      event.completer.complete(code);
    } catch (_) {
      emit(state.copyWith(inviting: false, failure: TeamFailure.invite));
      event.completer.complete(null);
    }
  }

  Future<void> _onJoinRequested(
    TeamJoinRequested event,
    Emitter<TeamState> emit,
  ) async {
    if (state.joining) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(joining: true, clearFailure: true));
    try {
      await _joinWallet(event.code);
      emit(state.copyWith(joining: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(joining: false, failure: TeamFailure.join));
      event.completer.complete(false);
    }
  }

  void _onInviteCodeCleared(
    TeamInviteCodeCleared event,
    Emitter<TeamState> emit,
  ) {
    emit(state.copyWith(clearInviteCode: true));
  }

  void _onFailureCleared(TeamFailureCleared event, Emitter<TeamState> emit) {
    emit(state.copyWith(clearFailure: true));
  }

  void selectWallet(String walletId) => add(TeamWalletSelected(walletId));

  Future<bool> sendNote(String body) async {
    final completer = Completer<bool>();
    add(TeamNoteSendRequested(body, completer));
    return completer.future;
  }

  Future<String?> createInvite() async {
    final completer = Completer<String?>();
    add(TeamInviteRequested(completer));
    return completer.future;
  }

  Future<bool> joinWallet(String code) async {
    final completer = Completer<bool>();
    add(TeamJoinRequested(code, completer));
    return completer.future;
  }

  void clearInviteCode() => add(const TeamInviteCodeCleared());

  void clearFailure() => add(const TeamFailureCleared());

  @override
  Future<void> close() async {
    await _walletSubscription?.cancel();
    await _teamSubscription?.cancel();
    return super.close();
  }
}
