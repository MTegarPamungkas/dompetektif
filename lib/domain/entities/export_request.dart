import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:equatable/equatable.dart';

enum ExportFormat { pdf, csv }

class ExportRequest extends Equatable {
  const ExportRequest({
    required this.entries,
    required this.periodStart,
    required this.periodEnd,
    required this.localeCode,
    this.walletName,
    this.includeReceipts = false,
  });

  final List<LedgerEntry> entries;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String localeCode;
  final String? walletName;
  final bool includeReceipts;

  @override
  List<Object?> get props => [
    entries,
    periodStart,
    periodEnd,
    localeCode,
    walletName,
    includeReceipts,
  ];
}

class ExportResult extends Equatable {
  const ExportResult({
    required this.fileName,
    required this.byteCount,
    this.savedPath,
  });

  final String fileName;
  final int byteCount;
  final String? savedPath;

  @override
  List<Object?> get props => [fileName, byteCount, savedPath];
}
