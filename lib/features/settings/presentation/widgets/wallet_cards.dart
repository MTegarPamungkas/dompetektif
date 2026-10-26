import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.wallet,
    required this.balance,
    required this.onEdit,
    required this.onDelete,
  });

  final Wallet wallet;
  final WalletBalance? balance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typeLabel = switch (wallet.type) {
      WalletType.cash => l10n.cash,
      WalletType.bank => l10n.bank,
      WalletType.ewallet => l10n.ewallet,
    };
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              WalletAvatar(wallet: wallet, size: 44),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            wallet.name,
                            style: context.texts.titleSmall?.copyWith(
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (wallet.isShared) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.groups_2_outlined,
                            size: 13,
                            color: context.dompet.accent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          typeLabel,
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 9.5,
                          ),
                        ),
                        if (wallet.isShared) ...[
                          const SizedBox(width: 6),
                          StatusPill(
                            label: l10n.shared,
                            tone: PillTone.accent,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.edit,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: context.dompet.inkMuted,
                ),
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 17),
                        const SizedBox(width: 9),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                          color: context.dompet.evidence,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          l10n.delete,
                          style: TextStyle(color: context.dompet.evidence),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.currentBalance.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontSize: 7.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            MoneyFormatter.format(
              balance?.balance.amountMinor ?? wallet.openingBalance.amountMinor,
              localeCode: l10n.locale.languageCode,
            ),
            style: AppTypography.money(
              fontSize: 27,
              color: context.dompet.ink,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MiniAmount(
                  label: l10n.income,
                  value: balance?.monthIncome.amountMinor ?? 0,
                  color: context.dompet.success,
                ),
              ),
              Container(width: 1, height: 28, color: context.dompet.line),
              const SizedBox(width: 12),
              Expanded(
                child: MiniAmount(
                  label: l10n.expense,
                  value: balance?.monthExpense.amountMinor ?? 0,
                  color: context.dompet.evidence,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniAmount extends StatelessWidget {
  const MiniAmount({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(fontSize: 7),
        ),
        const SizedBox(height: 2),
        Text(
          MoneyFormatter.format(
            value,
            localeCode: l10n.locale.languageCode,
            compact: true,
          ),
          style: context.texts.labelMedium?.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
