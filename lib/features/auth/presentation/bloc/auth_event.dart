import 'dart:async';

import 'package:dompetektif/domain/entities/app_user.dart';

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthUserChanged extends AuthEvent {
  const AuthUserChanged(this.user);

  final AppUser? user;
}

final class AuthUserWatchFailed extends AuthEvent {
  const AuthUserWatchFailed();
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested(this.email, this.password);

  final String email;
  final String password;
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested(this.name, this.email, this.password);

  final String name;
  final String email;
  final String password;
}

final class AuthGoogleRequested extends AuthEvent {
  const AuthGoogleRequested();
}

final class AuthDemoRequested extends AuthEvent {
  const AuthDemoRequested();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested(this.completer);

  final Completer<void> completer;
}

final class AuthFailureCleared extends AuthEvent {
  const AuthFailureCleared();
}
