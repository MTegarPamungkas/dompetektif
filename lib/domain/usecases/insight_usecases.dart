import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';

class WatchReports {
  const WatchReports(this._repository);

  final InsightRepository _repository;

  Stream<List<InvestigationReport>> call() => _repository.watchReports();
}

class GenerateInvestigation {
  const GenerateInvestigation(this._repository);

  final InsightRepository _repository;

  Future<InvestigationReport> call({
    required String? walletId,
    required DateTime from,
    required DateTime to,
    required String localeCode,
  }) {
    return _repository.generate(
      walletId: walletId,
      from: from,
      to: to,
      localeCode: localeCode,
    );
  }
}
