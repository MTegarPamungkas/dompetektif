import 'dart:async';

import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/domain/usecases/export_usecases.dart';
import 'package:dompetektif/domain/usecases/insight_usecases.dart';
import 'package:dompetektif/domain/usecases/settings_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._watch, this._generate, this._export, this._settings)
    : super(const ReportState()) {
    _subscription = _watch().listen(
      (reports) => emit(
        ReportState(
          reports: reports,
          loading: false,
          generating: state.generating,
          exporting: state.exporting,
        ),
      ),
      onError: (_) =>
          emit(state.copyWith(loading: false, failure: ReportFailure.load)),
    );
  }

  final WatchReports _watch;
  final GenerateInvestigation _generate;
  final ExportLedger _export;
  final GetSettings _settings;

  StreamSubscription<List<InvestigationReport>>? _subscription;

  Future<bool> generateForMonth(DateTime month) async {
    if (state.generating) return false;
    emit(state.copyWith(generating: true, clearFailure: true));
    final now = DateTime.now();
    final start = DateTime(month.year, month.month);
    final isCurrent = start.year == now.year && start.month == now.month;
    final end = isCurrent
        ? now
        : DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
    try {
      await _generate(
        walletId: _settings().activeWalletId,
        from: start,
        to: end,
        localeCode: _settings().localeCode,
      );
      emit(state.copyWith(generating: false));
      return true;
    } catch (_) {
      emit(state.copyWith(generating: false, failure: ReportFailure.generate));
      return false;
    }
  }

  Future<ExportResult?> export(
    InvestigationReport report,
    ExportFormat format,
  ) async {
    if (state.exporting) return null;
    emit(state.copyWith(exporting: true, clearFailure: true));
    try {
      final result = await _export(
        from: report.periodStart,
        to: report.periodEnd,
        format: format,
        localeCode: _settings().localeCode,
        walletId: report.walletId,
      );
      emit(state.copyWith(exporting: false));
      return result;
    } catch (_) {
      emit(state.copyWith(exporting: false, failure: ReportFailure.export));
      return null;
    }
  }

  Future<ExportResult?> exportMonth({
    required DateTime month,
    required ExportFormat format,
  }) async {
    final start = CaseDates.monthStart(month);
    final end = CaseDates.monthEnd(month);
    emit(state.copyWith(exporting: true, clearFailure: true));
    try {
      final result = await _export(
        from: start,
        to: end,
        format: format,
        localeCode: _settings().localeCode,
        walletId: _settings().activeWalletId,
      );
      emit(state.copyWith(exporting: false));
      return result;
    } catch (_) {
      emit(state.copyWith(exporting: false, failure: ReportFailure.export));
      return null;
    }
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
