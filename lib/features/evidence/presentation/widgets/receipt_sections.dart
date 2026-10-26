import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:flutter/material.dart';

class ReceiptSummary extends StatelessWidget {
  const ReceiptSummary({
    super.key,
    required this.receipt,
    required this.hidden,
    required this.onConvert,
    required this.onOpenTransaction,
  });

  final Receipt receipt;
  final bool hidden;
  final VoidCallback? onConvert;
  final VoidCallback? onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, tone) = switch (receipt.status) {
      ReceiptStatus.attached => (l10n.attached, PillTone.success),
      ReceiptStatus.parsed => (l10n.parsed, PillTone.accent),
      ReceiptStatus.draft => (l10n.draft, PillTone.neutral),
      ReceiptStatus.failed => (l10n.failed, PillTone.evidence),
    };
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusPill(label: label, tone: tone, compact: true),
              const Spacer(),
              if (receipt.imageKey == null)
                StatusPill(
                  label: l10n.noImage,
                  tone: PillTone.neutral,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.total.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              letterSpacing: 1.3,
              fontSize: 8.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            MoneyFormatter.format(
              receipt.total.amountMinor,
              localeCode: l10n.locale.languageCode,
              hidden: hidden,
            ),
            style: AppTypography.money(
              fontSize: 30,
              color: context.dompet.ink,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          InfoRow(
            label: l10n.merchant,
            value: receipt.merchant.isEmpty
                ? l10n.unknownMerchant
                : receipt.merchant,
          ),
          InfoRow(
            label: l10n.date,
            value: CaseDates.fullDate(
              receipt.occurredAt,
              l10n.locale.languageCode,
            ),
          ),
          InfoRow(
            label: l10n.generatedAt,
            value: CaseDates.dateTime(
              receipt.updatedAt,
              l10n.locale.languageCode,
            ),
          ),
          InfoRow(
            label: l10n.status,
            value: receipt.transactionId == null
                ? l10n.receiptDraft
                : l10n.receiptAttached,
            valueColor: receipt.transactionId == null
                ? context.dompet.inkMuted
                : context.dompet.success,
          ),
          const SizedBox(height: 14),
          if (onOpenTransaction != null)
            FilledButton.tonalIcon(
              onPressed: onOpenTransaction,
              icon: const Icon(Icons.receipt_long_outlined, size: 17),
              label: Text(l10n.openTransaction),
            )
          else
            FilledButton.icon(
              onPressed: onConvert,
              icon: const Icon(Icons.add_link_rounded, size: 17),
              label: Text(l10n.createTransactionFromReceipt),
            ),
        ],
      ),
    );
  }
}

class ItemsCard extends StatelessWidget {
  const ItemsCard({super.key, required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.items,
            eyebrow: l10n.details,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          if (receipt.items.isEmpty)
            Text(l10n.noItems, style: context.texts.bodySmall)
          else
            for (final item in receipt.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: context.texts.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ),
                    if (item.quantity > 1)
                      Text(
                        '${l10n.itemQuantity} ${item.quantity} · ',
                        style: context.texts.labelSmall?.copyWith(fontSize: 8),
                      ),
                    MoneyText(
                      money: item.total,
                      style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class RawTextCard extends StatelessWidget {
  const RawTextCard({super.key, required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.rawText,
            eyebrow: l10n.analysis,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.dompet.surfaceMuted,
              borderRadius: AppRadius.allSm,
            ),
            child: Text(
              receipt.rawText.isEmpty ? l10n.noTextDetected : receipt.rawText,
              style: context.texts.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 9.5,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
