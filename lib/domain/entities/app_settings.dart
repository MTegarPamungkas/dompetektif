import 'package:equatable/equatable.dart';

enum AppThemeMode {
  system,
  light,
  dark;

  static AppThemeMode fromKey(String? value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.dark,
    );
  }
}

class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = AppThemeMode.dark,
    this.localeCode = 'id',
    this.biometricEnabled = false,
    this.activeWalletId,
    this.currency = 'IDR',
    this.hideAmounts = false,
    this.onboarded = false,
  });

  final AppThemeMode themeMode;
  final String localeCode;
  final bool biometricEnabled;
  final String? activeWalletId;
  final String currency;
  final bool hideAmounts;
  final bool onboarded;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? localeCode,
    bool? biometricEnabled,
    String? activeWalletId,
    String? currency,
    bool? hideAmounts,
    bool? onboarded,
    bool clearActiveWallet = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      activeWalletId: clearActiveWallet
          ? null
          : (activeWalletId ?? this.activeWalletId),
      currency: currency ?? this.currency,
      hideAmounts: hideAmounts ?? this.hideAmounts,
      onboarded: onboarded ?? this.onboarded,
    );
  }

  @override
  List<Object?> get props => [
    themeMode,
    localeCode,
    biometricEnabled,
    activeWalletId,
    currency,
    hideAmounts,
    onboarded,
  ];
}
