import 'package:flutter/foundation.dart';

/// Compile-time configuration.
///
/// Provide values with:
/// `flutter run --dart-define-from-file=env.json`
///
/// When Supabase is not configured the app starts in a fully usable local
/// demo mode. The demo is intentionally labelled in the UI so it is never
/// mistaken for a cloud-backed session.
abstract final class AppConfig {
  static const String appName = 'Dompetektif';
  static const String tagline = 'Usut tuntas ke mana uangmu pergi.';
  static const String appScheme = String.fromEnvironment(
    'APP_SCHEME',
    defaultValue: 'dev.dompetektif',
  );
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static const String demoEmail = 'demo@dompetektif.app';
  static const String demoName = 'Inspektur Demo';
  static const String demoUserId = '00000000-0000-4000-8000-000000000001';

  static bool get hasSupabase =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static String get oauthRedirectUrl {
    if (kIsWeb) return webOauthRedirect(Uri.base);
    return '$appScheme://login-callback';
  }

  /// Returns the directory the web app is served from, with a trailing slash.
  ///
  /// GitHub Pages hosts the app under `/<repo>/`, so redirecting to
  /// `Uri.base.origin` would drop the path and land outside the app.
  @visibleForTesting
  static String webOauthRedirect(Uri base) => base.resolve('.').toString();

  static const String privacyUrl = 'https://github.com/dompetektif/app';
}
