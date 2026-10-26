import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoryLeakCard extends StatelessWidget {
  const CategoryLeakCard({
    super.key,
    required this.data,
    required this.settings,
  });

  final DashboardData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.thisMonth,
            title: l10n.categoryBreakdown,
            padding: EdgeInsets.zero,
            action: TextButton(
              onPressed: () => context.go('/ledger'),
              child: Text(l10n.viewAll),
            ),
          ),
          const SizedBox(height: 8),
          if (data.categorySpend.isEmpty)
            EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: l10n.noData,
              compact: true,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 460;
                final donut = CategoryDonut(
                  spend: data.categorySpend,
                  size: compact ? 150 : 168,
                );
                final list = Column(
                  children: [
                    for (final item in data.categorySpend.take(5))
                      CategorySpendRow(
                        item: item,
                        hidden: settings.hideAmounts,
                      ),
                  ],
                );
                if (compact) {
                  return Column(
                    children: [
                      Center(child: donut),
                      const SizedBox(height: 16),
                      list,
                    ],
                  );
                }
                return Row(
                  children: [
                    donut,
                    const SizedBox(width: 22),
                    Expanded(child: list),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class CategorySpendRow extends StatelessWidget {
  const CategorySpendRow({super.key, required this.item, required this.hidden});

  final CategorySpend item;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CategoryAvatar(category: item.category, size: 30),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizedCategoryName(l10n, item.category),
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      MoneyFormatter.format(
                        item.amount.amountMinor,
                        localeCode: l10n.locale.languageCode,
                        compact: true,
                        hidden: hidden,
                      ),
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                BudgetProgressBar(
                  ratio: item.ratio,
                  height: 4,
                  color: colorFromHex(item.category.colorHex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
