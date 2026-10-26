import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FindingsCard extends StatelessWidget {
  const FindingsCard({super.key, required this.report});

  final InvestigationReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.analysis,
            title: l10n.findings,
            padding: EdgeInsets.zero,
            action: StatusPill(
              label: '${report.findings.length}',
              tone: PillTone.neutral,
              compact: true,
            ),
          ),
          const SizedBox(height: 6),
          if (report.findings.isEmpty)
            Text(l10n.noData, style: context.texts.bodySmall)
          else
            for (var index = 0; index < report.findings.length; index++) ...[
              if (index > 0) Divider(color: context.dompet.line),
              FindingRow(finding: report.findings[index]),
            ],
        ],
      ),
    );
  }
}

class FindingRow extends StatelessWidget {
  const FindingRow({super.key, required this.finding});

  final ReportFinding finding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (color, label) = switch (finding.severity) {
      FindingSeverity.info => (context.dompet.info, l10n.info),
      FindingSeverity.warning => (context.dompet.warning, l10n.watch),
      FindingSeverity.critical => (context.dompet.evidence, l10n.alert),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              finding.severity == FindingSeverity.info
                  ? Icons.search_rounded
                  : Icons.priority_high_rounded,
              size: 15,
              color: color,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        finding.title,
                        style: context.texts.titleSmall?.copyWith(fontSize: 13),
                      ),
                    ),
                    StatusPill(
                      label: label,
                      tone: PillTone.neutral,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  finding.detail,
                  style: context.texts.bodySmall?.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnomaliesCard extends StatelessWidget {
  const AnomaliesCard({super.key, required this.report});

  final InvestigationReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.watch,
            title: l10n.anomalies,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 6),
          if (report.anomalies.isEmpty)
            Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 18,
                  color: context.dompet.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.noAnomalies, style: context.texts.bodySmall),
                ),
              ],
            )
          else
            for (final anomaly in report.anomalies)
              InkWell(
                borderRadius: AppRadius.allSm,
                onTap: anomaly.transactionId == null
                    ? null
                    : () =>
                          context.push('/transaction/${anomaly.transactionId}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.crisis_alert_rounded,
                        size: 18,
                        color: context.dompet.evidence,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anomaly.title,
                              style: context.texts.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              anomaly.detail,
                              style: context.texts.bodySmall?.copyWith(
                                fontSize: 9.5,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (anomaly.transactionId != null)
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 17,
                          color: context.dompet.inkMuted,
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class RecommendationsCard extends StatelessWidget {
  const RecommendationsCard({super.key, required this.report});

  final InvestigationReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      accent: context.dompet.accent,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.nextSteps,
            title: l10n.recommendations,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          if (report.recommendations.isEmpty)
            Text(l10n.noData, style: context.texts.bodySmall)
          else
            for (var index = 0; index < report.recommendations.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 19,
                      height: 19,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.dompet.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: context.texts.labelSmall?.copyWith(
                          fontSize: 8,
                          color: context.dompet.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        report.recommendations[index],
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 10.5,
                          height: 1.5,
                        ),
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

class ReportMetaCard extends StatelessWidget {
  const ReportMetaCard({super.key, required this.report});

  final InvestigationReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.details,
            title: l10n.reportPeriod,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          InfoRow(
            label: l10n.reportPeriod,
            value:
                '${CaseDates.dayMonth(report.periodStart, l10n.locale.languageCode)} – ${CaseDates.dayMonth(report.periodEnd, l10n.locale.languageCode)}',
          ),
          InfoRow(
            label: l10n.generatedAt,
            value: CaseDates.dateTime(
              report.generatedAt,
              l10n.locale.languageCode,
            ),
          ),
          InfoRow(
            label: l10n.reportWalletScope,
            value: report.walletId == null
                ? l10n.allWallets
                : l10n.activeWallet,
          ),
          InfoRow(
            label: l10n.reportSourceNote,
            value: report.source == ReportSource.ai
                ? l10n.reportAiSource
                : l10n.reportLocalSource,
            valueColor: report.source == ReportSource.ai
                ? context.dompet.info
                : context.dompet.accent,
          ),
        ],
      ),
    );
  }
}
