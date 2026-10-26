import 'package:dompetektif/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.webOauthRedirect', () {
    test('keeps the GitHub Pages project path', () {
      expect(
        AppConfig.webOauthRedirect(
          Uri.parse('https://mtegarpamungkas.github.io/dompetektif/#/auth'),
        ),
        'https://mtegarpamungkas.github.io/dompetektif/',
      );
    });

    test('keeps a local origin at the root', () {
      expect(
        AppConfig.webOauthRedirect(Uri.parse('http://localhost:8080/#/auth')),
        'http://localhost:8080/',
      );
    });

    test('adds a trailing slash when the base has no path', () {
      expect(
        AppConfig.webOauthRedirect(Uri.parse('https://example.com')),
        'https://example.com/',
      );
    });
  });
}
