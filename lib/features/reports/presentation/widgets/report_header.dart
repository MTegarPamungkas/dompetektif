import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/features/reports/presentation/bloc/report_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'report_sections.dart';

class ReportBody extends StatelessWidget {
  const ReportBody({super.key, required this.report});

  final InvestigationReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final margin = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 28.0;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margin, 18, margin, 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 820;
              final main = Column(
                children: [
                  FindingsCard(report: report),
                  const SizedBox(height: 14),
                  AnomaliesCard(report: report),
                ],
              );
              final side = Column(
                children: [
                  RecommendationsCard(report: report),
                  const SizedBox(height: 14),
                  ReportMetaCard(report: report),
                ],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ReportHeader(report: report),
                  const SizedBox(height: 18),
                  if (twoColumns)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: main),
                        const SizedBox(width: 16),
                        Expanded(flex: 5, child: side),
                      ],
                    )
                  else ...[
                    main,
                    const SizedBox(height: 14),
                    side,
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.read<ReportBloc>().export(
                          report,
                          ExportFormat.pdf,
                        ),
                        icon: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 17,
                        ),
                        label: Text(l10n.exportPdf),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.read<ReportBloc>().export(
                          report,
                          ExportFormat.csv,
                        ),
                        icon: const Icon(Icons.table_chart_outlined, size: 17),
                        label: Text(l10n.exportCsv),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.reportExportHint,
                    style: context.texts.bodySmall?.copyWith(fontSize: 10),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ReportHeader extends StatelessWidget {
  const ReportHeader({super.key, required this.report});

  final InvestigationReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAi = report.source == ReportSource.ai;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: (isAi ? context.dompet.info : context.dompet.accent)
              .withValues(alpha: 0.22),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.dompet.surfaceElevated,
            context.dompet.surface,
            context.dompet.background.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isAi ? context.dompet.info : context.dompet.accent)
                        .withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  StatusPill(
                    label: isAi ? l10n.reportAiSource : l10n.reportLocalSource,
                    tone: isAi ? PillTone.info : PillTone.accent,
                    icon: isAi
                        ? Icons.auto_awesome_rounded
                        : Icons.memory_rounded,
                  ),
                  const SizedBox(width: 8),
                  StatusPill(
                    label: CaseDates.monthYear(
                      report.periodStart,
                      l10n.locale.languageCode,
                    ),
                    tone: PillTone.neutral,
                    icon: Icons.calendar_month_outlined,
                    compact: true,
                  ),
                  const Spacer(),
                  CaseStamp(
                    label: l10n.confidential,
                    subLabel: isAi ? 'AI-REPORT' : 'LOCAL',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                l10n.reportHeadline.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  letterSpacing: 2.2,
                  fontSize: 8.5,
                  color: context.dompet.accent,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Text(
                  report.headline,
                  style: context.texts.displayMedium?.copyWith(
                    fontSize: 38,
                    height: 1.02,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Text(
                  report.summary,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.dompet.inkMuted,
                    height: 1.65,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusPill(
                    label:
                        '${report.findings.length} ${l10n.findings.toLowerCase()}',
                    icon: Icons.search_rounded,
                    compact: true,
                  ),
                  StatusPill(
                    label:
                        '${report.anomalies.length} ${l10n.anomalies.toLowerCase()}',
                    icon: Icons.warning_amber_rounded,
                    tone: report.anomalies.isEmpty
                        ? PillTone.success
                        : PillTone.evidence,
                    compact: true,
                  ),
                  StatusPill(
                    label:
                        '${report.recommendations.length} ${l10n.recommendations.toLowerCase()}',
                    icon: Icons.checklist_rounded,
                    tone: PillTone.info,
                    compact: true,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
