import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._store) {
    _current = _read();
  }

  final LocalStore _store;
  late AppSettings _current;

  static const _key = 'settings';

  @override
  AppSettings get current => _current;

  @override
  Stream<AppSettings> watch() async* {
    yield _current;
    await for (final _ in _store.watchMeta(_key)) {
      _current = _read();
      yield _current;
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    _current = settings;
    await _store.setMeta(_key, {
      'theme_mode': settings.themeMode.name,
      'locale': settings.localeCode,
      'biometric': settings.biometricEnabled,
      'active_wallet_id': settings.activeWalletId,
      'currency': settings.currency,
      'hide_amounts': settings.hideAmounts,
      'onboarded': settings.onboarded,
    });
  }

  AppSettings _read() {
    final raw = _store.getMeta(_key);
    if (raw is! Map) return const AppSettings();
    return AppSettings(
      themeMode: AppThemeMode.fromKey(raw['theme_mode'] as String?),
      localeCode: (raw['locale'] as String?) == 'en' ? 'en' : 'id',
      biometricEnabled: raw['biometric'] as bool? ?? false,
      activeWalletId: raw['active_wallet_id'] as String?,
      currency: raw['currency'] as String? ?? 'IDR',
      hideAmounts: raw['hide_amounts'] as bool? ?? false,
      onboarded: raw['onboarded'] as bool? ?? false,
    );
  }
}

class AlertRepositoryImpl implements AlertRepository {
  AlertRepositoryImpl(this._store);

  final LocalStore _store;

  @override
  Future<bool> wasSent(String key) async {
    return _store.getMeta('alert_sent_$key') == true;
  }

  @override
  Future<void> markSent(String key) async {
    await _store.setMeta('alert_sent_$key', true);
  }
}
