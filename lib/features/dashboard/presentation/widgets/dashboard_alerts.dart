import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AnomalyBanner extends StatelessWidget {
  const AnomalyBanner({super.key, required this.anomaly});

  final Anomaly anomaly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = anomaly.categoryName ?? l10n.unusualAmount;
    final merchant = anomaly.entry.transaction.merchant.isEmpty
        ? anomaly.entry.wallet.name
        : anomaly.entry.transaction.merchant;
    final amount = MoneyFormatter.format(
      anomaly.entry.transaction.amount.amountMinor,
      localeCode: l10n.locale.languageCode,
    );
    return AppCard(
      onTap: () => context.push('/transaction/${anomaly.entry.transaction.id}'),
      accent: context.dompet.evidence,
      background: context.dompet.evidenceSoft.withValues(alpha: 0.7),
      borderColor: context.dompet.evidence.withValues(alpha: 0.28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.dompet.evidence.withValues(alpha: 0.14),
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(
              Icons.crisis_alert_rounded,
              color: context.dompet.evidence,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        anomaly.kind == AnomalyKind.categoryLeak
                            ? l10n.anomalyHeadline(category)
                            : l10n.unusualAmount,
                        style: context.texts.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: anomaly.severity == AnomalySeverity.alert
                          ? l10n.alert
                          : l10n.watch,
                      tone: PillTone.evidence,
                      icon: Icons.priority_high_rounded,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.anomalyBody(merchant, amount),
                  style: context.texts.bodySmall?.copyWith(
                    height: 1.5,
                    color: context.dompet.inkMuted,
                  ),
                ),
                if (anomaly.deviation > 0) ...[
                  const SizedBox(height: 7),
                  Text(
                    '${anomaly.deviation.toStringAsFixed(1)}${l10n.anomalyDeviation}',
                    style: context.texts.labelSmall?.copyWith(
                      fontSize: 8.5,
                      color: context.dompet.evidence,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: context.dompet.evidence,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class BudgetAlertStrip extends StatelessWidget {
  const BudgetAlertStrip({super.key, required this.alerts});

  final List<BudgetProgress> alerts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      accent: context.dompet.warning,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: context.dompet.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alerts.length == 1
                  ? l10n.budgetOver(
                      localizedCategoryName(l10n, alerts.first.category),
                    )
                  : l10n.t(
                      '${alerts.length} batas perlu diperiksa.',
                      '${alerts.length} limits need a look.',
                    ),
              style: context.texts.bodySmall?.copyWith(height: 1.45),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.push('/budgets'),
            child: Text(l10n.manage),
          ),
        ],
      ),
    );
  }
}
