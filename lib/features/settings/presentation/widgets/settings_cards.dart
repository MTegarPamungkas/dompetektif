import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.auth, required this.settings});

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

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
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

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
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
            SettingIcon(icon: icon),
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

class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    super.key,
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
          SettingIcon(icon: icon),
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

class NavSettingRow extends StatelessWidget {
  const NavSettingRow({
    super.key,
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
            SettingIcon(icon: icon, danger: danger),
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

class SettingIcon extends StatelessWidget {
  const SettingIcon({super.key, required this.icon, this.danger = false});

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
