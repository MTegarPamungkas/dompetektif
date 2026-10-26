import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HeroBalance extends StatelessWidget {
  const HeroBalance({super.key, required this.data, required this.settings});

  final DashboardData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = data.activeWallet;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.dompet.accent.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.dompet.surfaceElevated,
            context.dompet.surface,
            context.dompet.background.withValues(alpha: 0.9),
          ],
          stops: const [0, 0.58, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: context.dompet.shadow.withValues(alpha: 0.34),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.dompet.accent.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active == null
                              ? l10n.totalBalance
                              : '${l10n.totalBalance} · ${active.wallet.name}',
                          style: context.texts.labelSmall?.copyWith(
                            letterSpacing: 1.6,
                            fontSize: 8.5,
                            color: context.dompet.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            MoneyFormatter.format(
                              data.totalBalance.amountMinor,
                              localeCode: l10n.locale.languageCode,
                              hidden: settings.hideAmounts,
                            ),
                            style: AppTypography.money(
                              fontSize: 45,
                              color: context.dompet.ink,
                              letterSpacing: -1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            TrendPill(value: data.monthExpenseChange),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l10n.previousMonthComparison,
                                style: context.texts.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: context.dompet.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CaseStamp(label: l10n.confidential, subLabel: 'PK-2026'),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final metrics = [
                    HeroStat(
                      label: compact ? l10n.incomeShort : l10n.income,
                      value: MoneyFormatter.format(
                        data.monthIncome.amountMinor,
                        localeCode: l10n.locale.languageCode,
                        compact: true,
                        hidden: settings.hideAmounts,
                      ),
                      color: context.dompet.success,
                      icon: Icons.south_west_rounded,
                    ),
                    HeroStat(
                      label: compact ? l10n.expenseShort : l10n.expense,
                      value: MoneyFormatter.format(
                        data.monthExpense.amountMinor,
                        localeCode: l10n.locale.languageCode,
                        compact: true,
                        hidden: settings.hideAmounts,
                      ),
                      color: context.dompet.evidence,
                      icon: Icons.north_east_rounded,
                    ),
                    HeroStat(
                      label: compact ? l10n.netShort : l10n.net,
                      value: MoneyFormatter.format(
                        data.monthNet.amountMinor,
                        localeCode: l10n.locale.languageCode,
                        compact: true,
                        hidden: settings.hideAmounts,
                      ),
                      color: data.monthNet.isNegative
                          ? context.dompet.warning
                          : context.dompet.info,
                      icon: Icons.compare_arrows_rounded,
                    ),
                  ];
                  if (compact) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final metric in metrics)
                          SizedBox(
                            width: (constraints.maxWidth - 8) / 2,
                            child: metric,
                          ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        Expanded(child: metrics[index]),
                        if (index < metrics.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final addButton = FilledButton.icon(
                    onPressed: () => context.push('/transaction/new'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.addTransaction),
                  );
                  final scanButton = OutlinedButton.icon(
                    onPressed: () => context.push('/receipt/scan'),
                    icon: const Icon(Icons.document_scanner_outlined, size: 17),
                    label: Text(l10n.scanReceipt),
                  );
                  if (constraints.maxWidth < 340) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        addButton,
                        const SizedBox(height: 8),
                        scanButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: addButton),
                      const SizedBox(width: 9),
                      Expanded(child: scanButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeroStat extends StatelessWidget {
  const HeroStat({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: context.dompet.background.withValues(alpha: 0.42),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.dompet.line.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    fontSize: 7.5,
                    letterSpacing: 0.7,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.money(fontSize: 14, color: color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrendPill extends StatelessWidget {
  const TrendPill({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final up = value > 0;
    final color = up ? context.dompet.evidence : context.dompet.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allPill,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            MoneyFormatter.percent(
              value.abs(),
              localeCode: l10n.locale.languageCode,
            ),
            style: context.texts.labelSmall?.copyWith(
              color: color,
              fontSize: 8.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
