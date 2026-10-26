import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/features/reports/presentation/cubit/report_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.reportId, this.report});

  final String reportId;
  final InvestigationReport? report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<ReportCubit, ReportState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          (previous.exporting && !current.exporting),
      listener: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          showAppSnackBar(
            context,
            failure == ReportFailure.export
                ? l10n.errorExport
                : l10n.errorGenerateReport,
            error: true,
          );
          context.read<ReportCubit>().clearFailure();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(l10n.reports),
          actions: [
            BlocBuilder<ReportCubit, ReportState>(
              buildWhen: (previous, current) =>
                  previous.exporting != current.exporting,
              builder: (context, state) {
                final data = report ?? _findReport(state.reports, reportId);
                if (data == null) return const SizedBox.shrink();
                return PopupMenuButton<ExportFormat>(
                  tooltip: l10n.exportData,
                  enabled: !state.exporting,
                  icon: state.exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  onSelected: (format) => _export(context, data, format),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: ExportFormat.pdf,
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined, size: 18),
                          const SizedBox(width: 9),
                          Text(l10n.exportPdf),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: ExportFormat.csv,
                      child: Row(
                        children: [
                          const Icon(Icons.table_chart_outlined, size: 18),
                          const SizedBox(width: 9),
                          Text(l10n.exportCsv),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: BlocBuilder<ReportCubit, ReportState>(
          builder: (context, state) {
            final data = report ?? _findReport(state.reports, reportId);
            if (data == null) {
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return PageScroll(
                children: [
                  ErrorState(
                    title: l10n.reportNotFound,
                    body: l10n.tapToRetry,
                    onRetry: () => context.pop(),
                  ),
                ],
              );
            }
            return _ReportBody(report: data);
          },
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    InvestigationReport report,
    ExportFormat format,
  ) async {
    final result = await context.read<ReportCubit>().export(report, format);
    if (!context.mounted || result == null) return;
    showAppSnackBar(context, context.l10n.exportSuccess);
  }
}

InvestigationReport? _findReport(List<InvestigationReport> reports, String id) {
  for (final report in reports) {
    if (report.id == id) return report;
  }
  return null;
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

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
                  _FindingsCard(report: report),
                  const SizedBox(height: 14),
                  _AnomaliesCard(report: report),
                ],
              );
              final side = Column(
                children: [
                  _RecommendationsCard(report: report),
                  const SizedBox(height: 14),
                  _ReportMetaCard(report: report),
                ],
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ReportHeader(report: report),
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
                        onPressed: () => context.read<ReportCubit>().export(
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
                        onPressed: () => context.read<ReportCubit>().export(
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

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report});

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

class _FindingsCard extends StatelessWidget {
  const _FindingsCard({required this.report});

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
              _FindingRow(finding: report.findings[index]),
            ],
        ],
      ),
    );
  }
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding});

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

class _AnomaliesCard extends StatelessWidget {
  const _AnomaliesCard({required this.report});

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

class _RecommendationsCard extends StatelessWidget {
  const _RecommendationsCard({required this.report});

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

class _ReportMetaCard extends StatelessWidget {
  const _ReportMetaCard({required this.report});

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
