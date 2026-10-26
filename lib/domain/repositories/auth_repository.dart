import 'package:dompetektif/domain/entities/app_user.dart';

abstract interface class AuthRepository {
  AppUser? get currentUser;

  bool get isDemo;

  bool get isConfigured;

  Stream<AppUser?> watchUser();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> signInWithGoogle();

  Future<AppUser> continueAsDemo();

  Future<void> signOut();
}
