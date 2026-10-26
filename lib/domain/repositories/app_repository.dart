import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/domain/entities/sync_status.dart';

abstract interface class SettingsRepository {
  AppSettings get current;

  Stream<AppSettings> watch();

  Future<void> save(AppSettings settings);
}

abstract interface class AlertRepository {
  Future<bool> wasSent(String key);

  Future<void> markSent(String key);
}

abstract interface class SyncRepository {
  SyncStatus get current;

  Stream<SyncStatus> watchStatus();

  Future<void> syncNow();
}

abstract interface class InsightRepository {
  Stream<List<InvestigationReport>> watchReports();

  Future<InvestigationReport> generate({
    required String? walletId,
    required DateTime from,
    required DateTime to,
    required String localeCode,
  });
}

abstract interface class ExportRepository {
  Future<ExportResult> export(ExportRequest request, ExportFormat format);
}
