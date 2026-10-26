import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/sync_status.dart';
import 'package:dompetektif/domain/usecases/export_usecases.dart';
import 'package:dompetektif/domain/usecases/sync_usecases.dart';
import 'package:dompetektif/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:dompetektif/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:dompetektif/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
    final settings = context.watch<SettingsCubit>().state;
    final auth = context.watch<AuthCubit>().state;
    final sync = context.watch<SyncCubit>().state;
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
          _ProfileCard(auth: auth, settings: settings),
          const SizedBox(height: 18),
          _SettingsSection(
            title: l10n.appearance,
            icon: Icons.palette_outlined,
            child: Column(
              children: [
                _SettingRow(
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
                        context.read<SettingsCubit>().setTheme(mode),
                  ),
                ),
                Divider(color: context.dompet.line),
                _SettingRow(
                  icon: Icons.translate_rounded,
                  title: l10n.language,
                  subtitle: l10n.languageName,
                  trailing: AppSegmented<String>(
                    values: const ['id', 'en'],
                    selected: settings.localeCode,
                    labelBuilder: (code) => code == 'id' ? 'ID' : 'EN',
                    onChanged: (code) =>
                        context.read<SettingsCubit>().setLocale(code),
                  ),
                ),
                Divider(color: context.dompet.line),
                _SettingSwitch(
                  icon: Icons.visibility_off_outlined,
                  title: l10n.hideAmounts,
                  subtitle: l10n.hideAmountsSubtitle,
                  value: settings.hideAmounts,
                  onChanged: (value) =>
                      context.read<SettingsCubit>().setHideAmounts(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SettingsSection(
            title: l10n.security,
            icon: Icons.shield_outlined,
            child: Column(
              children: [
                _SettingSwitch(
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
          _SettingsSection(
            title: l10n.data,
            icon: Icons.storage_outlined,
            child: Column(
              children: [
                _SyncPanel(status: sync, onSync: _syncNow),
                Divider(color: context.dompet.line),
                _NavSettingRow(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.wallets,
                  subtitle: l10n.walletsSubtitle,
                  onTap: () => context.push('/wallets'),
                ),
                Divider(color: context.dompet.line),
                _NavSettingRow(
                  icon: Icons.category_outlined,
                  title: l10n.categories,
                  subtitle: l10n.categoriesSubtitle,
                  onTap: () => context.push('/categories'),
                ),
                Divider(color: context.dompet.line),
                _NavSettingRow(
                  icon: Icons.event_repeat_rounded,
                  title: l10n.recurring,
                  subtitle: l10n.recurringSubtitle,
                  onTap: () => context.push('/recurring'),
                ),
                Divider(color: context.dompet.line),
                _NavSettingRow(
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
          _SettingsSection(
            title: l10n.account,
            icon: Icons.person_outline_rounded,
            child: Column(
              children: [
                _NavSettingRow(
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
          _SettingsSection(
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
      if (!mounted || !ok) return;
    }
    if (!mounted) return;
    await context.read<SettingsCubit>().setBiometric(value);
  }

  Future<void> _syncNow() async {
    final l10n = context.l10n;
    await context.read<SyncCubit>().syncNow();
    if (!mounted) return;
    final status = context.read<SyncCubit>().state;
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
        localeCode: context.read<SettingsCubit>().state.localeCode,
        walletId: context.read<SettingsCubit>().state.activeWalletId,
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
    await context.read<AuthCubit>().signOut();
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.auth, required this.settings});

  final AuthState auth;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = auth.user;
    final name = user?.displayName ?? l10n.demoUser;
    final email = user?.email ?? l10n.demoEmail;
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.substring(0, 1).toUpperCase())
              .join();
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.dompet.accentSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.dompet.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              initials,
              style: context.texts.headlineSmall?.copyWith(
                color: context.dompet.accent,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: context.texts.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: context.texts.bodySmall?.copyWith(fontSize: 10),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusPill(
                      label: auth.isDemo ? l10n.demoMode : l10n.cloudMode,
                      tone: auth.isDemo ? PillTone.accent : PillTone.success,
                      icon: auth.isDemo
                          ? Icons.science_outlined
                          : Icons.cloud_done_outlined,
                      compact: true,
                    ),
                    StatusPill(
                      label: settings.localeCode == 'id'
                          ? 'Bahasa Indonesia'
                          : 'English',
                      tone: PillTone.neutral,
                      icon: Icons.translate_rounded,
                      compact: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.dompet.accent),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  letterSpacing: 1.7,
                  fontSize: 8.5,
                  color: context.dompet.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final copy = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SettingIcon(icon: icon),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: constraints.maxWidth < 430
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    copy,
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 45),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: trailing,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 10),
                    trailing,
                  ],
                ),
        );
      },
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          _SettingIcon(icon: icon),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: enabled ? null : context.dompet.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: enabled ? onChanged : null),
        ],
      ),
    );
  }
}

class _NavSettingRow extends StatelessWidget {
  const _NavSettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.dompet.evidence : null;
    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            _SettingIcon(icon: icon, danger: danger),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: context.dompet.inkMuted,
                ),
          ],
        ),
      ),
    );
  }
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, this.danger = false});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? context.dompet.evidence : context.dompet.accent;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadius.allMd,
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

class _SyncPanel extends StatelessWidget {
  const _SyncPanel({required this.status, required this.onSync});

  final SyncStatus status;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, tone, icon) = switch (status.phase) {
      SyncPhase.demo => (
        l10n.demoMode,
        PillTone.accent,
        Icons.science_outlined,
      ),
      SyncPhase.syncing => (l10n.syncing, PillTone.info, Icons.sync_rounded),
      SyncPhase.offline => (
        l10n.offline,
        PillTone.neutral,
        Icons.cloud_off_outlined,
      ),
      SyncPhase.error => (
        l10n.syncFailed,
        PillTone.evidence,
        Icons.error_outline_rounded,
      ),
      SyncPhase.idle => (
        l10n.cloudMode,
        PillTone.success,
        Icons.cloud_done_outlined,
      ),
    };
    final statusCopy = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingIcon(icon: Icons.sync_rounded),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cloudStatus,
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              StatusPill(label: label, tone: tone, icon: icon, compact: true),
            ],
          ),
        ),
      ],
    );
    final syncButton = OutlinedButton.icon(
      onPressed: status.phase == SyncPhase.demo || status.phase.isBusy
          ? null
          : onSync,
      icon: status.phase.isBusy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded, size: 16),
      label: Text(l10n.syncNow),
    );
    final pending = InfoRow(
      label: l10n.pendingChanges,
      value: status.pendingCount == 0
          ? l10n.noPendingChanges
          : '${status.pendingCount}',
      valueColor: status.pendingCount == 0
          ? context.dompet.success
          : context.dompet.warning,
    );
    final lastSynced = InfoRow(
      label: l10n.lastSynced,
      value: status.lastSyncedAt == null
          ? l10n.neverSynced
          : CaseDates.dateTime(status.lastSyncedAt!, l10n.locale.languageCode),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 430;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (narrow) ...[
                statusCopy,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: syncButton),
              ] else
                Row(
                  children: [
                    Expanded(child: statusCopy),
                    const SizedBox(width: 12),
                    syncButton,
                  ],
                ),
              const SizedBox(height: 10),
              if (constraints.maxWidth < 360)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [pending, const SizedBox(height: 4), lastSynced],
                )
              else
                Row(
                  children: [
                    Expanded(child: pending),
                    const SizedBox(width: 16),
                    Expanded(child: lastSynced),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
