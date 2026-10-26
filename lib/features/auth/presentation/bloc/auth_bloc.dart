import 'dart:async';

import 'package:dompetektif/domain/entities/app_user.dart';
import 'package:dompetektif/domain/repositories/auth_repository.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(
    this._watchUser,
    this._signIn,
    this._signUp,
    this._google,
    this._demo,
    this._signOut,
    AuthRepository auth,
  ) : super(AuthState(isDemo: auth.isDemo, isConfigured: auth.isConfigured)) {
    on<AuthStarted>(_onStarted);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthUserWatchFailed>(_onUserWatchFailed);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthGoogleRequested>(_onGoogleRequested);
    on<AuthDemoRequested>(_onDemoRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthFailureCleared>(_onFailureCleared);
    add(const AuthStarted());
  }

  final WatchAuthUser _watchUser;
  final SignInWithEmail _signIn;
  final SignUpWithEmail _signUp;
  final SignInWithGoogle _google;
  final ContinueAsDemo _demo;
  final SignOut _signOut;

  StreamSubscription<AppUser?>? _subscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _subscription?.cancel();
    _subscription = _watchUser().listen(
      (user) => add(AuthUserChanged(user)),
      onError: (_) => add(const AuthUserWatchFailed()),
    );
  }

  void _onUserChanged(AuthUserChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        user: event.user,
        clearUser: event.user == null,
        resolving: false,
        submitting: false,
        clearFailure: true,
      ),
    );
  }

  void _onUserWatchFailed(AuthUserWatchFailed event, Emitter<AuthState> emit) {
    emit(state.copyWith(resolving: false, submitting: false));
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearFailure: true));
    try {
      final user = await _signIn(email: event.email, password: event.password);
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

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.submitting) return;
    emit(state.copyWith(submitting: true, clearFailure: true));
    try {
      final user = await _signUp(
        displayName: event.name,
        email: event.email,
        password: event.password,
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

  Future<void> _onGoogleRequested(
    AuthGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
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

  Future<void> _onDemoRequested(
    AuthDemoRequested event,
    Emitter<AuthState> emit,
  ) async {
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

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state.submitting) {
      event.completer.complete();
      return;
    }
    emit(state.copyWith(submitting: true, clearFailure: true));
    try {
      await _signOut();
      emit(
        state.copyWith(clearUser: true, submitting: false, resolving: false),
      );
    } catch (_) {
      emit(state.copyWith(submitting: false, failure: AuthFailure.generic));
    } finally {
      if (!event.completer.isCompleted) event.completer.complete();
    }
  }

  void _onFailureCleared(AuthFailureCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearFailure: true));
  }

  void signInWithEmail(String email, String password) =>
      add(AuthSignInRequested(email, password));

  void signUpWithEmail(String name, String email, String password) =>
      add(AuthSignUpRequested(name, email, password));

  void signInWithGoogle() => add(const AuthGoogleRequested());

  void continueAsDemo() => add(const AuthDemoRequested());

  Future<void> signOut() async {
    final completer = Completer<void>();
    add(AuthSignOutRequested(completer));
    await completer.future;
  }

  void clearFailure() => add(const AuthFailureCleared());

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
    if (text.contains('rate limit') ||
        text.contains('over_email_send_rate_limit') ||
        text.contains('too many')) {
      return AuthFailure.emailRateLimit;
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
