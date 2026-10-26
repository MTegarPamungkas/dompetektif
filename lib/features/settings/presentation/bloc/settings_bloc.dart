import 'dart:async';

import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/usecases/settings_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'settings_event.dart';

export 'settings_event.dart';

class SettingsBloc extends Bloc<SettingsEvent, AppSettings> {
  SettingsBloc(this._watch, GetSettings get, this._update) : super(get()) {
    on<SettingsStarted>(_onStarted);
    on<SettingsChanged>(_onChanged);
    on<SettingsThemeChanged>(_onThemeChanged);
    on<SettingsLocaleChanged>(_onLocaleChanged);
    on<SettingsBiometricChanged>(_onBiometricChanged);
    on<SettingsHideAmountsChanged>(_onHideAmountsChanged);
    on<SettingsActiveWalletChanged>(_onActiveWalletChanged);
    on<SettingsOnboarded>(_onOnboarded);
    add(const SettingsStarted());
  }

  final WatchSettings _watch;
  final UpdateSettings _update;
  StreamSubscription<AppSettings>? _subscription;

  Future<void> _onStarted(
    SettingsStarted event,
    Emitter<AppSettings> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _watch().listen(
      (settings) => add(SettingsChanged(settings)),
    );
  }

  void _onChanged(SettingsChanged event, Emitter<AppSettings> emit) {
    emit(event.settings);
  }

  Future<void> _onThemeChanged(
    SettingsThemeChanged event,
    Emitter<AppSettings> emit,
  ) => _save(state.copyWith(themeMode: event.mode), emit);

  Future<void> _onLocaleChanged(
    SettingsLocaleChanged event,
    Emitter<AppSettings> emit,
  ) =>
      _save(state.copyWith(localeCode: event.code == 'en' ? 'en' : 'id'), emit);

  Future<void> _onBiometricChanged(
    SettingsBiometricChanged event,
    Emitter<AppSettings> emit,
  ) async {
    try {
      await _save(state.copyWith(biometricEnabled: event.enabled), emit);
    } finally {
      if (!event.completer.isCompleted) event.completer.complete();
    }
  }

  Future<void> _onHideAmountsChanged(
    SettingsHideAmountsChanged event,
    Emitter<AppSettings> emit,
  ) => _save(state.copyWith(hideAmounts: event.hidden), emit);

  Future<void> _onActiveWalletChanged(
    SettingsActiveWalletChanged event,
    Emitter<AppSettings> emit,
  ) => _save(
    state.copyWith(
      activeWalletId: event.walletId,
      clearActiveWallet: event.walletId == null,
    ),
    emit,
  );

  Future<void> _onOnboarded(
    SettingsOnboarded event,
    Emitter<AppSettings> emit,
  ) => _save(state.copyWith(onboarded: true), emit);

  Future<void> _save(AppSettings settings, Emitter<AppSettings> emit) async {
    emit(settings);
    await _update(settings);
  }

  Future<void> setTheme(AppThemeMode mode) async =>
      add(SettingsThemeChanged(mode));

  Future<void> setLocale(String code) async => add(SettingsLocaleChanged(code));

  Future<void> setBiometric(bool enabled) async {
    final completer = Completer<void>();
    add(SettingsBiometricChanged(enabled, completer));
    await completer.future;
  }

  Future<void> setHideAmounts(bool hidden) async =>
      add(SettingsHideAmountsChanged(hidden));

  Future<void> setActiveWallet(String? walletId) async =>
      add(SettingsActiveWalletChanged(walletId));

  Future<void> markOnboarded() async => add(const SettingsOnboarded());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
