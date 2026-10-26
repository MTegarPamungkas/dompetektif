import 'dart:async';

import 'package:dompetektif/domain/entities/app_settings.dart';

sealed class SettingsEvent {
  const SettingsEvent();
}

final class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

final class SettingsChanged extends SettingsEvent {
  const SettingsChanged(this.settings);

  final AppSettings settings;
}

final class SettingsThemeChanged extends SettingsEvent {
  const SettingsThemeChanged(this.mode);

  final AppThemeMode mode;
}

final class SettingsLocaleChanged extends SettingsEvent {
  const SettingsLocaleChanged(this.code);

  final String code;
}

final class SettingsBiometricChanged extends SettingsEvent {
  const SettingsBiometricChanged(this.enabled, this.completer);

  final bool enabled;
  final Completer<void> completer;
}

final class SettingsHideAmountsChanged extends SettingsEvent {
  const SettingsHideAmountsChanged(this.hidden);

  final bool hidden;
}

final class SettingsActiveWalletChanged extends SettingsEvent {
  const SettingsActiveWalletChanged(this.walletId);

  final String? walletId;
}

final class SettingsOnboarded extends SettingsEvent {
  const SettingsOnboarded();
}
