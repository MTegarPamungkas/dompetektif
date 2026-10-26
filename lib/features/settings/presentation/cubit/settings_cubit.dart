import 'dart:async';

import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/usecases/settings_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsCubit extends Cubit<AppSettings> {
  SettingsCubit(this._watch, GetSettings get, this._update) : super(get()) {
    _subscription = _watch().listen(emit);
  }

  final WatchSettings _watch;
  final UpdateSettings _update;

  StreamSubscription<AppSettings>? _subscription;

  Future<void> setTheme(AppThemeMode mode) =>
      _save(state.copyWith(themeMode: mode));

  Future<void> setLocale(String code) =>
      _save(state.copyWith(localeCode: code == 'en' ? 'en' : 'id'));

  Future<void> setBiometric(bool enabled) =>
      _save(state.copyWith(biometricEnabled: enabled));

  Future<void> setHideAmounts(bool hidden) =>
      _save(state.copyWith(hideAmounts: hidden));

  Future<void> setActiveWallet(String? walletId) => _save(
    state.copyWith(
      activeWalletId: walletId,
      clearActiveWallet: walletId == null,
    ),
  );

  Future<void> markOnboarded() => _save(state.copyWith(onboarded: true));

  Future<void> _save(AppSettings settings) async {
    emit(settings);
    await _update(settings);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
