import 'package:dompetektif/data/datasources/cloud_gateway.dart';
import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/data/mappers/entity_mappers.dart';
import 'package:dompetektif/data/repositories/local_repository_base.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';

class InsightRepositoryImpl implements InsightRepository {
  InsightRepositoryImpl(this._store, this._gateway, this._base);

  final LocalStore _store;
  final CloudGateway _gateway;
  final LocalRepositoryBase _base;

  @override
  Stream<List<InvestigationReport>> watchReports() {
    return _store.watch('reports').map((rows) {
      final reports = rows.map(reportFromRow).toList()
        ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      return reports;
    });
  }

  @override
  Future<InvestigationReport> generate({
    required String? walletId,
    required DateTime from,
    required DateTime to,
    required String localeCode,
  }) async {
    final report = await _gateway.generateReport(
      walletId: walletId,
      from: from,
      to: to,
      localeCode: localeCode,
    );

    if (_gateway.isDemo) {
      await _store.put('reports', reportToRow(report));
    } else {
      await _base.upsertRow(
        'reports',
        reportToRow(report),
        updatedAt: report.generatedAt,
      );
    }
    return report;
  }
}
