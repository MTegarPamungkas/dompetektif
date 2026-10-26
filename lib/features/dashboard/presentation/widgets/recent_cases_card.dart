import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecentCasesCard extends StatelessWidget {
  const RecentCasesCard({
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
            eyebrow: l10n.ledger,
            title: l10n.recentCases,
            padding: EdgeInsets.zero,
            action: TextButton(
              onPressed: () => context.go('/ledger'),
              child: Text(l10n.viewAll),
            ),
          ),
          const SizedBox(height: 4),
          if (data.recentEntries.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.noTransactions,
              compact: true,
            )
          else
            for (final entry in data.recentEntries.take(6))
              RecentCaseRow(entry: entry, hidden: settings.hideAmounts),
        ],
      ),
    );
  }
}

class RecentCaseRow extends StatelessWidget {
  const RecentCaseRow({super.key, required this.entry, required this.hidden});

  final LedgerEntry entry;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final transaction = entry.transaction;
    final categoryName = entry.category == null
        ? ''
        : localizedCategoryName(l10n, entry.category!);
    final title = transaction.merchant.isNotEmpty
        ? transaction.merchant
        : transaction.note.isNotEmpty
        ? transaction.note
        : categoryName.isNotEmpty
        ? categoryName
        : entry.wallet.name;
    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: () => context.push('/transaction/${transaction.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            CategoryAvatar(category: entry.category, size: 36),
            const SizedBox(width: 10),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${CaseDates.dayMonth(transaction.occurredAt, l10n.locale.languageCode)} · ${entry.wallet.name}',
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TransactionAmount(
                  transaction: transaction,
                  hidden: hidden,
                  style: context.texts.bodyMedium?.copyWith(fontSize: 12),
                ),
                if (transaction.isPending)
                  StatusPill(
                    label: l10n.statusPending,
                    tone: PillTone.accent,
                    compact: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
