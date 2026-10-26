import 'dart:async';

import 'package:dompetektif/core/config/app_config.dart';
import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/data/seed/demo_seeder.dart';
import 'package:dompetektif/domain/entities/app_user.dart';
import 'package:dompetektif/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required LocalStore store,
    required DemoSeeder seeder,
    SupabaseClient? client,
  }) : _store = store,
       _seeder = seeder,
       _client = client;

  final LocalStore _store;
  final DemoSeeder _seeder;
  final SupabaseClient? _client;
  final StreamController<AppUser?> _demoController =
      StreamController<AppUser?>.broadcast();

  AppUser? _demoUser;
  Future<void> _scopeChain = Future<void>.value();

  @override
  AppUser? get currentUser {
    if (isDemo) return _demoUser;
    final user = _client?.auth.currentUser;
    return user == null ? null : _mapUser(user);
  }

  @override
  bool get isDemo => _client == null;

  @override
  bool get isConfigured => _client != null;

  @override
  Stream<AppUser?> watchUser() async* {
    if (isDemo) {
      if (_demoUser == null) {
        final saved = _store.getMeta('demo_user');
        if (saved is Map) {
          _demoUser = AppUser(
            id: saved['id'] as String? ?? AppConfig.demoUserId,
            email: saved['email'] as String? ?? AppConfig.demoEmail,
            displayName: saved['display_name'] as String? ?? AppConfig.demoName,
            avatarUrl: saved['avatar_url'] as String?,
            isDemo: true,
            createdAt: DateTime.tryParse(saved['created_at'] as String? ?? ''),
          );
        }
      }
      final demoUser = _demoUser;
      if (demoUser != null) {
        await _ensureScope(demoUser.id);
      }
      yield demoUser;
      yield* _demoController.stream;
      return;
    }

    final client = _client!;
    final current = client.auth.currentUser;
    if (current != null) {
      await _ensureScope(current.id, discardDemoData: true);
    }
    yield current == null ? null : _mapUser(current);
    yield* client.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;
      final mapped = _mapUser(user);
      await _ensureScope(mapped.id, discardDemoData: true);
      return mapped;
    });
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) throw StateError('Login tidak mengembalikan sesi.');
    await _ensureScope(user.id, discardDemoData: true);
    return _mapUser(user);
  }

  @override
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final client = _requireClient();
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Registrasi berhasil, tetapi sesi belum aktif.');
    }
    if (client.auth.currentUser != null) {
      await _ensureScope(user.id, discardDemoData: true);
    }
    return _mapUser(user);
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final client = _requireClient();
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.oauthRedirectUrl,
    );
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError(
        'Login Google dibuka di browser. Setelah selesai, aplikasi akan melanjutkan otomatis.',
      );
    }
    await _ensureScope(user.id, discardDemoData: true);
    return _mapUser(user);
  }

  @override
  Future<AppUser> continueAsDemo() async {
    if (!isDemo) {
      throw UnsupportedError('Mode demo tidak tersedia saat Supabase aktif.');
    }
    await _ensureScope(AppConfig.demoUserId);
    await _seeder.seedIfNeeded();
    final user = AppUser(
      id: AppConfig.demoUserId,
      email: AppConfig.demoEmail,
      displayName: AppConfig.demoName,
      isDemo: true,
      createdAt: DateTime.now(),
    );
    _demoUser = user;
    await _store.setMeta('demo_user', {
      'id': user.id,
      'email': user.email,
      'display_name': user.displayName,
      'created_at': user.createdAt?.toIso8601String(),
    });
    _demoController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    if (isDemo) {
      _demoUser = null;
      _demoController.add(null);
      await _store.clearUserData();
      return;
    }
    await _client!.auth.signOut();
    await _store.clearUserData();
  }

  /// Serialises scope changes so a sign-in event and the auth stream cannot
  /// clear the same local store at the same time.
  Future<void> _ensureScope(String userId, {bool discardDemoData = false}) {
    _scopeChain = _scopeChain
        .catchError((Object _) {})
        .then(
          (_) =>
              _store.ensureUserScope(userId, discardDemoData: discardDemoData),
        );
    return _scopeChain;
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw UnsupportedError(
        'Cloud belum dikonfigurasi. Gunakan mode demo atau isi SUPABASE_URL dan SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }

  AppUser _mapUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final displayName =
        (metadata['display_name'] as String?)?.trim().isNotEmpty == true
        ? metadata['display_name'] as String
        : (user.email?.split('@').first ?? 'Investigator');
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: displayName,
      avatarUrl: metadata['avatar_url'] as String?,
      isDemo: false,
      createdAt: DateTime.tryParse(user.createdAt),
    );
  }
}
