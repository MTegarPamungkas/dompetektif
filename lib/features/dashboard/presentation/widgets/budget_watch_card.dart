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

class BudgetWatchCard extends StatelessWidget {
  const BudgetWatchCard({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = data.budgetProgress.take(4).toList();
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.budgets,
            title: l10n.budgetWatch,
            padding: EdgeInsets.zero,
            action: IconButton(
              tooltip: l10n.manage,
              onPressed: () => context.push('/budgets'),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          if (progress.isEmpty)
            EmptyState(
              icon: Icons.track_changes_rounded,
              title: l10n.noBudgets,
              compact: true,
            )
          else
            for (final item in progress) BudgetWatchRow(item: item),
        ],
      ),
    );
  }
}

class BudgetWatchRow extends StatelessWidget {
  const BudgetWatchRow({super.key, required this.item});

  final BudgetProgress item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = switch (item.status) {
      BudgetStatus.over => context.dompet.evidence,
      BudgetStatus.warning => context.dompet.warning,
      BudgetStatus.safe => context.dompet.success,
    };
    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: () => context.push('/budgets'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: [
            Row(
              children: [
                CategoryAvatar(category: item.category, size: 30),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    localizedCategoryName(l10n, item.category),
                    style: context.texts.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                Text(
                  MoneyFormatter.percent(
                    item.ratio,
                    localeCode: l10n.locale.languageCode,
                  ),
                  style: context.texts.labelSmall?.copyWith(
                    color: tone,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            BudgetProgressBar(ratio: item.ratio, height: 5),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${MoneyFormatter.format(item.spent.amountMinor, localeCode: l10n.locale.languageCode, compact: true)} / ${MoneyFormatter.format(item.budget.amount.amountMinor, localeCode: l10n.locale.languageCode, compact: true)}',
                    style: context.texts.bodySmall?.copyWith(fontSize: 9),
                  ),
                ),
                Text(
                  switch (item.status) {
                    BudgetStatus.over => l10n.budgetStatusOver,
                    BudgetStatus.warning => l10n.budgetStatusWarning,
                    BudgetStatus.safe => l10n.budgetStatusSafe,
                  },
                  style: context.texts.labelSmall?.copyWith(
                    color: tone,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
