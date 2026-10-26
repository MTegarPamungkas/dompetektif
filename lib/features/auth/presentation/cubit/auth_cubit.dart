import 'dart:async';

import 'package:dompetektif/domain/entities/app_user.dart';
import 'package:dompetektif/domain/repositories/auth_repository.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthFailure {
  invalidCredentials,
  emailInUse,
  emailNotConfirmed,
  network,
  demoDisabled,
  cloudNotConfigured,
  oauthRedirect,
  generic,
}

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.resolving = true,
    this.submitting = false,
    this.failure,
    this.isDemo = false,
    this.isConfigured = false,
  });

  final AppUser? user;
  final bool resolving;
  final bool submitting;
  final AuthFailure? failure;
  final bool isDemo;
  final bool isConfigured;

  bool get signedIn => user != null;

  AuthState copyWith({
    AppUser? user,
    bool clearUser = false,
    bool? resolving,
    bool? submitting,
    AuthFailure? failure,
    bool clearFailure = false,
    bool? isDemo,
    bool? isConfigured,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      resolving: resolving ?? this.resolving,
      submitting: submitting ?? this.submitting,
      failure: clearFailure ? null : (failure ?? this.failure),
      isDemo: isDemo ?? this.isDemo,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  @override
  List<Object?> get props => [
    user,
    resolving,
    submitting,
    failure,
    isDemo,
    isConfigured,
  ];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._watchUser,
    this._signIn,
    this._signUp,
    this._google,
    this._demo,
    this._signOut,
    AuthRepository auth,
  ) : super(AuthState(isDemo: auth.isDemo, isConfigured: auth.isConfigured)) {
    _subscription = _watchUser().listen(
      (user) {
        emit(
          state.copyWith(
            user: user,
            clearUser: user == null,
            resolving: false,
            submitting: false,
            clearFailure: true,
          ),
        );
      },
      onError: (_) {
        emit(state.copyWith(resolving: false, submitting: false));
      },
    );
  }

  final WatchAuthUser _watchUser;
  final SignInWithEmail _signIn;
  final SignUpWithEmail _signUp;
  final SignInWithGoogle _google;
  final ContinueAsDemo _demo;
  final SignOut _signOut;

  StreamSubscription<AppUser?>? _subscription;

  Future<void> signInWithEmail(String email, String password) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearFailure: true));
    try {
      final user = await _signIn(email: email, password: password);
      emit(
        state.copyWith(
          user: user,
          submitting: false,
          resolving: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(submitting: false, failure: _mapFailure(error)));
    }
  }

  Future<void> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearFailure: true));
    try {
      final user = await _signUp(
        displayName: name,
        email: email,
        password: password,
      );
      emit(
        state.copyWith(
          user: user,
          submitting: false,
          resolving: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(submitting: false, failure: _mapFailure(error)));
    }
  }

  Future<void> signInWithGoogle() async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearFailure: true));
    try {
      final user = await _google();
      emit(
        state.copyWith(
          user: user,
          submitting: false,
          resolving: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(submitting: false, failure: _mapFailure(error)));
    }
  }

  Future<void> continueAsDemo() async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearFailure: true));
    try {
      final user = await _demo();
      emit(
        state.copyWith(
          user: user,
          submitting: false,
          resolving: false,
          clearFailure: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(submitting: false, failure: _mapFailure(error)));
    }
  }

  Future<void> signOut() async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearFailure: true));
    try {
      await _signOut();
      emit(
        state.copyWith(clearUser: true, submitting: false, resolving: false),
      );
    } catch (_) {
      emit(state.copyWith(submitting: false, failure: AuthFailure.generic));
    }
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  AuthFailure _mapFailure(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('invalid login credentials') ||
        text.contains('invalid_credentials')) {
      return AuthFailure.invalidCredentials;
    }
    if (text.contains('already registered') ||
        text.contains('user already exists') ||
        text.contains('email_exists')) {
      return AuthFailure.emailInUse;
    }
    if (text.contains('email not confirmed') ||
        text.contains('email_not_confirmed')) {
      return AuthFailure.emailNotConfirmed;
    }
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('failed host lookup') ||
        text.contains('connection')) {
      return AuthFailure.network;
    }
    if (text.contains('mode demo tidak tersedia')) {
      return AuthFailure.demoDisabled;
    }
    if (text.contains('cloud belum dikonfigurasi')) {
      return AuthFailure.cloudNotConfigured;
    }
    if (text.contains('dibuka di browser') || text.contains('browser')) {
      return AuthFailure.oauthRedirect;
    }
    return AuthFailure.generic;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
