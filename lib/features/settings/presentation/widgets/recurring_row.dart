import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:flutter/material.dart';

class RecurringRow extends StatelessWidget {
  const RecurringRow({
    super.key,
    required this.rule,
    required this.walletName,
    required this.category,
    required this.toWalletName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final RecurringRule rule;
  final String? walletName;
  final Category? category;
  final String? toWalletName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = rule.merchant.trim().isNotEmpty
        ? rule.merchant
        : (rule.note.trim().isNotEmpty
              ? rule.note
              : (category == null
                    ? l10n.recurring
                    : localizedCategoryName(l10n, category!)));
    final frequency = switch (rule.frequency) {
      RecurrenceFrequency.daily => l10n.daily,
      RecurrenceFrequency.weekly => l10n.weekly,
      RecurrenceFrequency.monthly => l10n.monthly,
      RecurrenceFrequency.yearly => l10n.yearly,
    };
    final titleRow = Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 5),
        if (!rule.isActive)
          StatusPill(
            label: l10n.inactive,
            tone: PillTone.neutral,
            compact: true,
          ),
      ],
    );
    final subtitle = Text(
      [
        frequency,
        ?walletName,
        ?toWalletName,
        '${l10n.nextRun}: ${CaseDates.dayMonth(rule.nextRunAt, l10n.locale.languageCode)}',
      ].join(' · '),
      style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final amount = Text(
      MoneyFormatter.format(
        rule.amount.amountMinor,
        localeCode: l10n.locale.languageCode,
      ),
      style: context.texts.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
      ),
    );
    final typeLabel = Text(
      rule.type == TransactionType.income
          ? l10n.incomeShort
          : (rule.type == TransactionType.transfer
                ? l10n.transfer
                : l10n.expenseShort),
      style: context.texts.labelSmall?.copyWith(fontSize: 7.5),
    );
    final menu = PopupMenuButton<String>(
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
    );
    final toggle = Switch(value: rule.isActive, onChanged: onToggle);

    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            final avatar = CategoryAvatar(
              category: category,
              size: 40,
              iconOverride: rule.type == TransactionType.transfer
                  ? Icons.swap_horiz_rounded
                  : null,
            );
            if (compact) {
              return Row(
                children: [
                  avatar,
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleRow,
                        const SizedBox(height: 3),
                        subtitle,
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            amount,
                            const SizedBox(width: 6),
                            typeLabel,
                          ],
                        ),
                      ],
                    ),
                  ),
                  toggle,
                  menu,
                ],
              );
            }
            return Row(
              children: [
                avatar,
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titleRow, const SizedBox(height: 3), subtitle],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [amount, const SizedBox(height: 2), typeLabel],
                ),
                toggle,
                menu,
              ],
            );
          },
        ),
      ),
    );
  }
}
