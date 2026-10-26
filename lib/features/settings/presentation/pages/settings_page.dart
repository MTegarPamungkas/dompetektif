import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/sync_status.dart';
import 'package:dompetektif/domain/usecases/export_usecases.dart';
import 'package:dompetektif/domain/usecases/sync_usecases.dart';
import 'package:dompetektif/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:dompetektif/features/sync/presentation/bloc/sync_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../widgets/settings_cards.dart';
import '../widgets/sync_panel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricAvailable = false;
  bool _exporting = false;
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadBiometrics();
    _loadVersion();
  }

  Future<void> _loadBiometrics() async {
    final available = await getIt<CheckBiometrics>()();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version}+${info.buildNumber}');
    } catch (_) {
      // Keep the fallback version.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsBloc>().state;
    final auth = context.watch<AuthBloc>().state;
    final sync = context.watch<SyncBloc>().state;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.settings),
      ),
      body: PageScroll(
        children: [
          DossierHeader(
            eyebrow: '${l10n.caseFile} / ${l10n.settings.toUpperCase()}',
            title: l10n.settings,
            subtitle: l10n.settingsSubtitle,
            compact: true,
            trailing: CaseStamp(label: l10n.confidential, subLabel: 'CFG'),
          ),
          const SizedBox(height: 22),
          ProfileCard(auth: auth, settings: settings),
          const SizedBox(height: 18),
          SettingsSection(
            title: l10n.appearance,
            icon: Icons.palette_outlined,
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.dark_mode_outlined,
                  title: l10n.theme,
                  subtitle: switch (settings.themeMode) {
                    AppThemeMode.system => l10n.themeSystem,
                    AppThemeMode.light => l10n.lightMode,
                    AppThemeMode.dark => l10n.darkMode,
                  },
                  trailing: AppSegmented<AppThemeMode>(
                    values: AppThemeMode.values,
                    selected: settings.themeMode,
                    labelBuilder: (mode) => switch (mode) {
                      AppThemeMode.system => l10n.themeSystemShort,
                      AppThemeMode.light => l10n.themeLight,
                      AppThemeMode.dark => l10n.themeDark,
                    },
                    onChanged: (mode) =>
                        context.read<SettingsBloc>().setTheme(mode),
                  ),
                ),
                Divider(color: context.dompet.line),
                SettingRow(
                  icon: Icons.translate_rounded,
                  title: l10n.language,
                  subtitle: l10n.languageName,
                  trailing: AppSegmented<String>(
                    values: const ['id', 'en'],
                    selected: settings.localeCode,
                    labelBuilder: (code) => code == 'id' ? 'ID' : 'EN',
                    onChanged: (code) =>
                        context.read<SettingsBloc>().setLocale(code),
                  ),
                ),
                Divider(color: context.dompet.line),
                SettingSwitch(
                  icon: Icons.visibility_off_outlined,
                  title: l10n.hideAmounts,
                  subtitle: l10n.hideAmountsSubtitle,
                  value: settings.hideAmounts,
                  onChanged: (value) =>
                      context.read<SettingsBloc>().setHideAmounts(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SettingsSection(
            title: l10n.security,
            icon: Icons.shield_outlined,
            child: Column(
              children: [
                SettingSwitch(
                  icon: Icons.fingerprint_rounded,
                  title: l10n.biometric,
                  subtitle: _biometricAvailable
                      ? l10n.biometricSubtitle
                      : l10n.biometricUnavailable,
                  value: settings.biometricEnabled && _biometricAvailable,
                  enabled: _biometricAvailable,
                  onChanged: _setBiometric,
                ),
                Divider(color: context.dompet.line),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: context.dompet.inkMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.securityNote,
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 9.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SettingsSection(
            title: l10n.data,
            icon: Icons.storage_outlined,
            child: Column(
              children: [
                SyncPanel(status: sync, onSync: _syncNow),
                Divider(color: context.dompet.line),
                NavSettingRow(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.wallets,
                  subtitle: l10n.walletsSubtitle,
                  onTap: () => context.push('/wallets'),
                ),
                Divider(color: context.dompet.line),
                NavSettingRow(
                  icon: Icons.category_outlined,
                  title: l10n.categories,
                  subtitle: l10n.categoriesSubtitle,
                  onTap: () => context.push('/categories'),
                ),
                Divider(color: context.dompet.line),
                NavSettingRow(
                  icon: Icons.event_repeat_rounded,
                  title: l10n.recurring,
                  subtitle: l10n.recurringSubtitle,
                  onTap: () => context.push('/recurring'),
                ),
                Divider(color: context.dompet.line),
                NavSettingRow(
                  icon: Icons.ios_share_rounded,
                  title: l10n.exportData,
                  subtitle: l10n.exportDataSubtitle,
                  trailing: _exporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: _exporting ? null : _exportSheet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SettingsSection(
            title: l10n.account,
            icon: Icons.person_outline_rounded,
            child: Column(
              children: [
                NavSettingRow(
                  icon: Icons.logout_rounded,
                  title: l10n.signOut,
                  subtitle: l10n.signOutBody,
                  danger: true,
                  onTap: _confirmSignOut,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SettingsSection(
            title: l10n.about,
            icon: Icons.info_outline_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DOMPETEKTIF',
                  style: context.texts.labelMedium?.copyWith(
                    letterSpacing: 2,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.aboutBody,
                  style: context.texts.bodySmall?.copyWith(height: 1.55),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final versionText = Text(
                      '${l10n.version} $_version',
                      style: context.texts.labelSmall?.copyWith(fontSize: 8.5),
                    );
                    final taglineText = Text(
                      l10n.tagline,
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 8.5,
                        color: context.dompet.accent,
                      ),
                    );
                    if (constraints.maxWidth < 360) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          versionText,
                          const SizedBox(height: 4),
                          taglineText,
                        ],
                      );
                    }
                    return Row(
                      children: [versionText, const Spacer(), taglineText],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Future<void> _setBiometric(bool value) async {
    final l10n = context.l10n;
    if (value) {
      final ok = await getIt<UnlockWithBiometrics>()(l10n.biometricReason);
      if (!mounted) return;
      if (!ok) {
        showAppSnackBar(context, l10n.errorBiometric, error: true);
        return;
      }
    }
    if (!mounted) return;
    await context.read<SettingsBloc>().setBiometric(value);
  }

  Future<void> _syncNow() async {
    final l10n = context.l10n;
    await context.read<SyncBloc>().syncNow();
    if (!mounted) return;
    final status = context.read<SyncBloc>().state;
    showAppSnackBar(
      context,
      status.phase == SyncPhase.error ? l10n.syncFailed : l10n.syncDone,
      error: status.phase == SyncPhase.error,
    );
  }

  Future<void> _exportSheet() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final format = await showModalBottomSheet<ExportFormat>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.exportData, style: context.texts.headlineSmall),
            const SizedBox(height: 4),
            Text(l10n.exportDataSubtitle, style: context.texts.bodySmall),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
              tileColor: context.dompet.surfaceMuted,
              leading: Icon(
                Icons.picture_as_pdf_outlined,
                color: context.dompet.evidence,
              ),
              title: Text(l10n.exportPdf),
              subtitle: Text(
                CaseDates.monthYear(
                  CaseDates.monthStart(now),
                  l10n.locale.languageCode,
                ),
              ),
              onTap: () => Navigator.of(context).pop(ExportFormat.pdf),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: AppRadius.allMd),
              tileColor: context.dompet.surfaceMuted,
              leading: Icon(
                Icons.table_chart_outlined,
                color: context.dompet.success,
              ),
              title: Text(l10n.exportCsv),
              subtitle: Text(
                CaseDates.monthYear(
                  CaseDates.monthStart(now),
                  l10n.locale.languageCode,
                ),
              ),
              onTap: () => Navigator.of(context).pop(ExportFormat.csv),
            ),
          ],
        ),
      ),
    );
    if (!mounted || format == null) return;
    setState(() => _exporting = true);
    try {
      await getIt<ExportLedger>()(
        from: CaseDates.monthStart(now),
        to: CaseDates.monthEnd(now),
        format: format,
        localeCode: context.read<SettingsBloc>().state.localeCode,
        walletId: context.read<SettingsBloc>().state.activeWalletId,
      );
      if (!mounted) return;
      showAppSnackBar(context, l10n.exportSuccess);
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, l10n.errorExport, error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmSignOut() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.signOutConfirm,
      body: l10n.signOutBody,
      confirmLabel: l10n.signOut,
    );
    if (!confirmed || !mounted) return;
    await context.read<AuthBloc>().signOut();
  }
}
