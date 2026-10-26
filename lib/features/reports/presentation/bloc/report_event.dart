import 'dart:async';

import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';

sealed class ReportEvent {
  const ReportEvent();
}

final class ReportStarted extends ReportEvent {
  const ReportStarted();
}

final class ReportListChanged extends ReportEvent {
  const ReportListChanged(this.reports);

  final List<InvestigationReport> reports;
}

final class ReportLoadFailed extends ReportEvent {
  const ReportLoadFailed();
}

final class ReportGenerateRequested extends ReportEvent {
  const ReportGenerateRequested(this.month, this.completer);

  final DateTime month;
  final Completer<bool> completer;
}

final class ReportExportRequested extends ReportEvent {
  const ReportExportRequested(this.report, this.format, this.completer);

  final InvestigationReport report;
  final ExportFormat format;
  final Completer<ExportResult?> completer;
}

final class ReportExportMonthRequested extends ReportEvent {
  const ReportExportMonthRequested(this.month, this.format, this.completer);

  final DateTime month;
  final ExportFormat format;
  final Completer<ExportResult?> completer;
}

final class ReportFailureCleared extends ReportEvent {
  const ReportFailureCleared();
}
