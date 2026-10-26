import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/features/ledger/presentation/bloc/ledger_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class GroupedEntries extends StatelessWidget {
  const GroupedEntries({
    super.key,
    required this.entries,
    required this.hidden,
  });

  final List<LedgerEntry> entries;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = <DateTime, List<LedgerEntry>>{};
    for (final entry in entries) {
      final date = entry.transaction.occurredAt;
      final key = DateTime(date.year, date.month, date.day);
      groups.putIfAbsent(key, () => []).add(entry);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final key in keys) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 7),
              child: Row(
                children: [
                  Text(
                    _dateLabel(context, key),
                    style: context.texts.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontSize: 9,
                      color: context.dompet.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Divider(color: context.dompet.line)),
                  const SizedBox(width: 9),
                  Text(
                    '${groups[key]!.length} ${l10n.caseCount}',
                    style: context.texts.labelSmall?.copyWith(fontSize: 8),
                  ),
                ],
              ),
            ),
            for (final entry in groups[key]!) ...[
              LedgerRow(entry: entry, hidden: hidden),
              if (entry != groups[key]!.last)
                Divider(color: context.dompet.line.withValues(alpha: 0.55)),
            ],
          ],
        ],
      ),
    );
  }

  String _dateLabel(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    if (CaseDates.isToday(date)) return l10n.today;
    if (CaseDates.isYesterday(date)) return l10n.yesterday;
    return CaseDates.fullDate(date, l10n.locale.languageCode);
  }
}

class LedgerRow extends StatelessWidget {
  const LedgerRow({super.key, required this.entry, required this.hidden});

  final LedgerEntry entry;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final transaction = entry.transaction;
    final category = entry.category;
    final categoryName = category == null
        ? (transaction.type == TransactionType.transfer
              ? l10n.transfer
              : l10n.t('Tanpa kategori', 'Uncategorized'))
        : localizedCategoryName(l10n, category);
    final title = transaction.displayTitle.isNotEmpty
        ? transaction.displayTitle
        : categoryName;
    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: () => context.push('/transaction/${transaction.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            CategoryAvatar(
              category: category,
              size: 42,
              iconOverride: transaction.type == TransactionType.transfer
                  ? Icons.swap_horiz_rounded
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      if (transaction.receiptId != null) ...[
                        const SizedBox(width: 5),
                        Icon(
                          Icons.attach_file_rounded,
                          size: 12,
                          color: context.dompet.inkMuted,
                        ),
                      ],
                      if (transaction.isPending) ...[
                        const SizedBox(width: 5),
                        StatusPill(
                          label: l10n.statusPending,
                          tone: PillTone.accent,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      categoryName,
                      entry.wallet.name,
                      if (entry.toWallet != null) entry.toWallet!.name,
                      CaseDates.time(
                        transaction.occurredAt,
                        l10n.locale.languageCode,
                      ),
                    ].join(' · '),
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
                  style: context.texts.bodyMedium?.copyWith(fontSize: 12.5),
                ),
                if (transaction.note.trim().isNotEmpty &&
                    transaction.merchant.trim().isNotEmpty)
                  Text(
                    transaction.note,
                    style: context.texts.bodySmall?.copyWith(fontSize: 8.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: l10n.edit,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: context.dompet.inkMuted,
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/transaction/${transaction.id}');
                  return;
                }
                final confirmed = await showConfirmDialog(
                  context,
                  title: l10n.deleteTransactionTitle,
                  body: l10n.deleteTransactionBody,
                  confirmLabel: l10n.confirmDelete,
                );
                if (!confirmed || !context.mounted) return;
                final success = await context
                    .read<LedgerBloc>()
                    .deleteTransaction(transaction.id);
                if (!context.mounted) return;
                if (success) {
                  showAppSnackBar(context, l10n.deleteSuccess);
                }
              },
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
      ),
    );
  }
}
