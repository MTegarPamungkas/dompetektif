import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/features/reports/presentation/cubit/report_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<ReportCubit, ReportState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          (previous.generating && !current.generating),
      listener: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          showAppSnackBar(context, switch (failure) {
            ReportFailure.load => l10n.errorLoadData,
            ReportFailure.generate => l10n.errorGenerateReport,
            ReportFailure.export => l10n.errorExport,
          }, error: true);
          context.read<ReportCubit>().clearFailure();
        } else if (!state.generating) {
          showAppSnackBar(context, l10n.reportReady);
        }
      },
      child: BlocBuilder<ReportCubit, ReportState>(
        builder: (context, state) {
          return PageScroll(
            children: [
              DossierHeader(
                eyebrow:
                    '${l10n.caseFile} / ${state.reports.length} ${l10n.reports.toLowerCase()}',
                title: l10n.reports,
                subtitle: l10n.t(
                  'Laporan Penyelidikan merangkum pola, kebocoran kategori, dan langkah lanjutan. AI hanya membaca ringkasan, bukan data mentah.',
                  'Investigation Reports summarize patterns, category leaks, and next steps. AI reads summaries, never raw records.',
                ),
              ),
              const SizedBox(height: 22),
              _GeneratorCard(
                generating: state.generating,
                onGenerate: (month) => _generate(context, month),
              ),
              const SizedBox(height: 22),
              if (state.loading)
                const LoadingState()
              else if (state.reports.isEmpty)
                EmptyState(
                  icon: Icons.analytics_outlined,
                  title: l10n.insightEmptyTitle,
                  body: l10n.insightEmptyBody,
                  action: FilledButton.icon(
                    onPressed: state.generating
                        ? null
                        : () => _generate(context, DateTime.now()),
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(l10n.reportGenerate),
                  ),
                )
              else ...[
                SectionHeader(
                  eyebrow: l10n.analysis,
                  title: l10n.t('Arsip laporan', 'Report archive'),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 860 ? 2 : 1;
                    return Column(
                      children: [
                        for (
                          var index = 0;
                          index < state.reports.length;
                          index += columns
                        )
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var column = 0; column < columns; column++)
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: column < columns - 1 ? 12 : 0,
                                      ),
                                      child:
                                          index + column < state.reports.length
                                          ? _ReportCard(
                                              report:
                                                  state.reports[index + column],
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _generate(BuildContext context, DateTime month) async {
    final success = await context.read<ReportCubit>().generateForMonth(month);
    if (!context.mounted) return;
    if (success) {
      showAppSnackBar(context, context.l10n.reportReady);
    }
  }
}

class _GeneratorCard extends StatelessWidget {
  const _GeneratorCard({required this.generating, required this.onGenerate});

  final bool generating;
  final ValueChanged<DateTime> onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: context.dompet.accentSoft,
                      borderRadius: AppRadius.allMd,
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 19,
                      color: context.dompet.accent,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.reportGenerate,
                          style: context.texts.titleLarge,
                        ),
                        Text(
                          l10n.reportSourceNote,
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 10,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (generating)
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(l10n.reportGenerating, style: context.texts.bodySmall),
                  ],
                )
              else
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    FilledButton.icon(
                      onPressed: () => onGenerate(now),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text(l10n.thisMonth),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => onGenerate(previous),
                      icon: const Icon(Icons.history_rounded, size: 17),
                      label: Text(l10n.lastMonth),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusPill(
                    label: l10n.reportLocalSource,
                    tone: PillTone.neutral,
                    icon: Icons.memory_rounded,
                    compact: true,
                  ),
                  const SizedBox(width: 7),
                  StatusPill(
                    label: l10n.offlineFirst,
                    tone: PillTone.info,
                    icon: Icons.cloud_off_outlined,
                    compact: true,
                  ),
                ],
              ),
            ],
          );
          if (compact) return copy;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: copy),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.dompet.background.withValues(alpha: 0.42),
                    borderRadius: AppRadius.allLg,
                    border: Border.all(color: context.dompet.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CaseStamp(
                        label: l10n.confidential,
                        subLabel: 'AI / LOCAL',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.insightEmptyBody,
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 10,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final InvestigationReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sourceLabel = report.source == ReportSource.ai
        ? l10n.reportAiSource
        : l10n.reportLocalSource;
    return AppCard(
      onTap: () => context.push('/report/${report.id}', extra: report),
      padding: const EdgeInsets.all(18),
      accent: report.source == ReportSource.ai
          ? context.dompet.info
          : context.dompet.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusPill(
                label: sourceLabel,
                tone: report.source == ReportSource.ai
                    ? PillTone.info
                    : PillTone.accent,
                icon: report.source == ReportSource.ai
                    ? Icons.auto_awesome_rounded
                    : Icons.memory_rounded,
                compact: true,
              ),
              const Spacer(),
              Text(
                CaseDates.monthYear(
                  report.periodStart,
                  l10n.locale.languageCode,
                ),
                style: context.texts.labelSmall?.copyWith(fontSize: 8.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.headline,
            style: context.texts.titleLarge?.copyWith(height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 7),
          Text(
            report.summary,
            style: context.texts.bodySmall?.copyWith(height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _CountBadge(
                icon: Icons.search_rounded,
                value: '${report.findings.length}',
                label: l10n.findings,
              ),
              const SizedBox(width: 7),
              _CountBadge(
                icon: Icons.warning_amber_rounded,
                value: '${report.anomalies.length}',
                label: l10n.anomalies,
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: context.dompet.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: context.dompet.surfaceMuted,
        borderRadius: AppRadius.allPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.dompet.inkMuted),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: context.texts.labelSmall?.copyWith(fontSize: 8),
          ),
        ],
      ),
    );
  }
}
