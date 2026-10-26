import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:flutter/material.dart';

class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        IconButton.outlined(
          tooltip: l10n.previousMonth,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
            decoration: BoxDecoration(
              color: context.dompet.surface,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: context.dompet.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 17,
                  color: context.dompet.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  CaseDates.monthYear(month, l10n.locale.languageCode),
                  style: context.texts.titleSmall?.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          tooltip: l10n.nextMonth,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class BudgetSummary extends StatelessWidget {
  const BudgetSummary({
    super.key,
    required this.totalBudget,
    required this.totalSpent,
    required this.ratio,
    required this.count,
    required this.hidden,
  });

  final int totalBudget;
  final int totalSpent;
  final double ratio;
  final int count;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = totalBudget - totalSpent;
    return AppCard(
      padding: const EdgeInsets.all(20),
      accent: ratio >= 1
          ? context.dompet.evidence
          : (ratio >= 0.8 ? context.dompet.warning : context.dompet.accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.budgetProgress.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  letterSpacing: 1.3,
                  fontSize: 8.5,
                ),
              ),
              const Spacer(),
              StatusPill(
                label: '$count ${l10n.categories}',
                tone: PillTone.neutral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    MoneyFormatter.format(
                      totalSpent,
                      localeCode: l10n.locale.languageCode,
                      hidden: hidden,
                    ),
                    maxLines: 1,
                    style: AppTypography.money(
                      fontSize: 31,
                      color: context.dompet.ink,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${MoneyFormatter.format(totalBudget, localeCode: l10n.locale.languageCode, hidden: hidden)}',
                maxLines: 1,
                style: context.texts.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          BudgetProgressBar(ratio: ratio, height: 8),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InfoRow(
                  label: l10n.remaining,
                  value: MoneyFormatter.format(
                    remaining,
                    localeCode: l10n.locale.languageCode,
                    hidden: hidden,
                  ),
                  valueColor: remaining < 0
                      ? context.dompet.evidence
                      : context.dompet.success,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                MoneyFormatter.percent(
                  ratio,
                  localeCode: l10n.locale.languageCode,
                ),
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 10,
                  color: ratio >= 1
                      ? context.dompet.evidence
                      : (ratio >= 0.8
                            ? context.dompet.warning
                            : context.dompet.success),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  const BudgetCard({
    super.key,
    required this.item,
    required this.hidden,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetProgress item;
  final bool hidden;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = switch (item.status) {
      BudgetStatus.over => context.dompet.evidence,
      BudgetStatus.warning => context.dompet.warning,
      BudgetStatus.safe => context.dompet.success,
    };
    final statusLabel = switch (item.status) {
      BudgetStatus.over => l10n.budgetStatusOver,
      BudgetStatus.warning => l10n.budgetStatusWarning,
      BudgetStatus.safe => l10n.budgetStatusSafe,
    };
    return AppCard(
      onTap: onEdit,
      accent: tone,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CategoryAvatar(category: item.category, size: 39),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedCategoryName(l10n, item.category),
                      style: context.texts.titleSmall?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${MoneyFormatter.percent(item.budget.alertThreshold, localeCode: l10n.locale.languageCode)} ${l10n.threshold.toLowerCase()}',
                      style: context.texts.bodySmall?.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: statusLabel,
                tone: item.status == BudgetStatus.safe
                    ? PillTone.success
                    : (item.status == BudgetStatus.warning
                          ? PillTone.accent
                          : PillTone.evidence),
                compact: true,
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
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  MoneyFormatter.format(
                    item.spent.amountMinor,
                    localeCode: l10n.locale.languageCode,
                    hidden: hidden,
                  ),
                  style: AppTypography.money(
                    fontSize: 22,
                    color: context.dompet.ink,
                  ),
                ),
              ),
              Text(
                '/ ${MoneyFormatter.format(item.budget.amount.amountMinor, localeCode: l10n.locale.languageCode, hidden: hidden)}',
                style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 9),
          BudgetProgressBar(ratio: item.ratio, height: 7),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.remaining}: ${MoneyFormatter.format(item.remaining.amountMinor, localeCode: l10n.locale.languageCode, hidden: hidden)}',
                  style: context.texts.bodySmall?.copyWith(fontSize: 9),
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
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
