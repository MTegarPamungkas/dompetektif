import 'package:dompetektif/domain/entities/app_user.dart';
import 'package:equatable/equatable.dart';

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
