import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletFilterStrip extends StatelessWidget {
  const WalletFilterStrip({
    super.key,
    required this.data,
    required this.settings,
  });

  final DashboardData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              l10n.activeWallet.toUpperCase(),
              style: context.texts.labelSmall?.copyWith(
                fontSize: 8,
                letterSpacing: 1.2,
              ),
            ),
          ),
          WalletChip(
            label: l10n.allWallets,
            selected: settings.activeWalletId == null,
            onTap: () => context.read<SettingsBloc>().setActiveWallet(null),
          ),
          for (final item in data.wallets)
            WalletChip(
              label: item.wallet.name,
              selected: settings.activeWalletId == item.wallet.id,
              color: colorFromHex(item.wallet.colorHex),
              onTap: () =>
                  context.read<SettingsBloc>().setActiveWallet(item.wallet.id),
            ),
        ],
      ),
    );
  }
}

class WalletChip extends StatelessWidget {
  const WalletChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? context.dompet.accent;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: InkWell(
        borderRadius: AppRadius.allPill,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? tone.withValues(alpha: 0.14)
                : context.dompet.surface,
            borderRadius: AppRadius.allPill,
            border: Border.all(
              color: selected
                  ? tone.withValues(alpha: 0.45)
                  : context.dompet.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? tone : context.dompet.inkMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 9.5,
                  color: selected
                      ? context.dompet.ink
                      : context.dompet.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
