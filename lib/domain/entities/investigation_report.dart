import 'package:dompetektif/domain/entities/money.dart';
import 'package:equatable/equatable.dart';

enum FindingSeverity {
  info,
  warning,
  critical;

  static FindingSeverity fromKey(String? value) {
    return FindingSeverity.values.firstWhere(
      (severity) => severity.name == value,
      orElse: () => FindingSeverity.info,
    );
  }
}

class ReportFinding extends Equatable {
  const ReportFinding({
    required this.title,
    required this.detail,
    this.severity = FindingSeverity.info,
  });

  final String title;
  final String detail;
  final FindingSeverity severity;

  @override
  List<Object?> get props => [title, detail, severity];
}

class ReportAnomaly extends Equatable {
  const ReportAnomaly({
    required this.title,
    required this.detail,
    this.transactionId,
    this.amount,
    this.severity = FindingSeverity.warning,
  });

  final String title;
  final String detail;
  final String? transactionId;
  final Money? amount;
  final FindingSeverity severity;

  @override
  List<Object?> get props => [title, detail, transactionId, amount, severity];
}

enum ReportSource {
  ai,
  heuristic;

  static ReportSource fromKey(String? value) {
    return value == 'ai' ? ReportSource.ai : ReportSource.heuristic;
  }
}

class InvestigationReport extends Equatable {
  const InvestigationReport({
    required this.id,
    required this.ownerId,
    required this.periodStart,
    required this.periodEnd,
    required this.headline,
    required this.summary,
    required this.findings,
    required this.anomalies,
    required this.recommendations,
    required this.source,
    required this.generatedAt,
    this.walletId,
  });

  final String id;
  final String ownerId;
  final String? walletId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String headline;
  final String summary;
  final List<ReportFinding> findings;
  final List<ReportAnomaly> anomalies;
  final List<String> recommendations;
  final ReportSource source;
  final DateTime generatedAt;

  InvestigationReport copyWith({
    String? id,
    String? ownerId,
    String? walletId,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? headline,
    String? summary,
    List<ReportFinding>? findings,
    List<ReportAnomaly>? anomalies,
    List<String>? recommendations,
    ReportSource? source,
    DateTime? generatedAt,
  }) {
    return InvestigationReport(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      walletId: walletId ?? this.walletId,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      findings: findings ?? this.findings,
      anomalies: anomalies ?? this.anomalies,
      recommendations: recommendations ?? this.recommendations,
      source: source ?? this.source,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    walletId,
    periodStart,
    periodEnd,
    headline,
    summary,
    findings,
    anomalies,
    recommendations,
    source,
    generatedAt,
  ];
}
