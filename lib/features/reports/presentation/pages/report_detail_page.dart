import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/features/reports/presentation/bloc/report_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/report_header.dart';

class ReportDetailPage extends StatelessWidget {
  const ReportDetailPage({super.key, required this.reportId, this.report});

  final String reportId;
  final InvestigationReport? report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<ReportBloc, ReportState>(
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
          context.read<ReportBloc>().clearFailure();
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
            BlocBuilder<ReportBloc, ReportState>(
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
        body: BlocBuilder<ReportBloc, ReportState>(
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
            return ReportBody(report: data);
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
    final result = await context.read<ReportBloc>().export(report, format);
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
