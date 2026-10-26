import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:equatable/equatable.dart';

enum ReportFailure { load, generate, export }

class ReportState extends Equatable {
  const ReportState({
    this.reports = const [],
    this.loading = true,
    this.generating = false,
    this.exporting = false,
    this.failure,
  });

  final List<InvestigationReport> reports;
  final bool loading;
  final bool generating;
  final bool exporting;
  final ReportFailure? failure;

  ReportState copyWith({
    List<InvestigationReport>? reports,
    bool? loading,
    bool? generating,
    bool? exporting,
    ReportFailure? failure,
    bool clearFailure = false,
  }) {
    return ReportState(
      reports: reports ?? this.reports,
      loading: loading ?? this.loading,
      generating: generating ?? this.generating,
      exporting: exporting ?? this.exporting,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [reports, loading, generating, exporting, failure];
}
