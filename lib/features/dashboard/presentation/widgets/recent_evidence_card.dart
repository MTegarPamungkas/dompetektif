import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecentEvidenceCard extends StatelessWidget {
  const RecentEvidenceCard({
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
            eyebrow: l10n.evidence,
            title: l10n.recentEvidence,
            padding: EdgeInsets.zero,
            action: TextButton(
              onPressed: () => context.go('/evidence'),
              child: Text(l10n.viewAll),
            ),
          ),
          const SizedBox(height: 8),
          if (data.recentReceipts.isEmpty)
            EmptyState(
              icon: Icons.document_scanner_outlined,
              title: l10n.noEvidence,
              compact: true,
              action: OutlinedButton(
                onPressed: () => context.push('/receipt/scan'),
                child: Text(l10n.scanNow),
              ),
            )
          else
            for (final receipt in data.recentReceipts.take(4))
              ReceiptPreview(receipt: receipt, hidden: settings.hideAmounts),
        ],
      ),
    );
  }
}

class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({
    super.key,
    required this.receipt,
    required this.hidden,
  });

  final Receipt receipt;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: () => context.push('/receipt/${receipt.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.dompet.accentSoft,
                borderRadius: AppRadius.allSm,
                border: Border.all(
                  color: context.dompet.accent.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                receipt.imageKey != null
                    ? Icons.receipt_long_rounded
                    : Icons.article_outlined,
                size: 18,
                color: context.dompet.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.merchant.isEmpty
                        ? l10n.unknownMerchant
                        : receipt.merchant,
                    style: context.texts.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CaseDates.dayMonth(
                      receipt.occurredAt,
                      l10n.locale.languageCode,
                    ),
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                  ),
                ],
              ),
            ),
            MoneyText(
              money: receipt.total,
              hidden: hidden,
              style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}
