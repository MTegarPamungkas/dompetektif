import 'dart:async';

import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/domain/usecases/export_usecases.dart';
import 'package:dompetektif/domain/usecases/insight_usecases.dart';
import 'package:dompetektif/domain/usecases/settings_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'report_event.dart';
import 'report_state.dart';

export 'report_event.dart';
export 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc(this._watch, this._generate, this._export, this._settings)
    : super(const ReportState()) {
    on<ReportStarted>(_onStarted);
    on<ReportListChanged>(_onListChanged);
    on<ReportLoadFailed>(_onLoadFailed);
    on<ReportGenerateRequested>(_onGenerateRequested);
    on<ReportExportRequested>(_onExportRequested);
    on<ReportExportMonthRequested>(_onExportMonthRequested);
    on<ReportFailureCleared>(_onFailureCleared);
    add(const ReportStarted());
  }

  final WatchReports _watch;
  final GenerateInvestigation _generate;
  final ExportLedger _export;
  final GetSettings _settings;

  StreamSubscription<List<InvestigationReport>>? _subscription;

  Future<void> _onStarted(
    ReportStarted event,
    Emitter<ReportState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _watch().listen(
      (reports) => add(ReportListChanged(reports)),
      onError: (_) => add(const ReportLoadFailed()),
    );
  }

  void _onListChanged(ReportListChanged event, Emitter<ReportState> emit) {
    emit(
      ReportState(
        reports: event.reports,
        loading: false,
        generating: state.generating,
        exporting: state.exporting,
      ),
    );
  }

  void _onLoadFailed(ReportLoadFailed event, Emitter<ReportState> emit) {
    emit(state.copyWith(loading: false, failure: ReportFailure.load));
  }

  Future<void> _onGenerateRequested(
    ReportGenerateRequested event,
    Emitter<ReportState> emit,
  ) async {
    if (state.generating) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(generating: true, clearFailure: true));
    final now = DateTime.now();
    final start = DateTime(event.month.year, event.month.month);
    final isCurrent = start.year == now.year && start.month == now.month;
    final end = isCurrent
        ? now
        : DateTime(event.month.year, event.month.month + 1, 0, 23, 59, 59, 999);
    try {
      await _generate(
        walletId: _settings().activeWalletId,
        from: start,
        to: end,
        localeCode: _settings().localeCode,
      );
      emit(state.copyWith(generating: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(generating: false, failure: ReportFailure.generate));
      event.completer.complete(false);
    }
  }

  Future<void> _onExportRequested(
    ReportExportRequested event,
    Emitter<ReportState> emit,
  ) async {
    if (state.exporting) {
      event.completer.complete(null);
      return;
    }
    emit(state.copyWith(exporting: true, clearFailure: true));
    try {
      final result = await _export(
        from: event.report.periodStart,
        to: event.report.periodEnd,
        format: event.format,
        localeCode: _settings().localeCode,
        walletId: event.report.walletId,
      );
      emit(state.copyWith(exporting: false));
      event.completer.complete(result);
    } catch (_) {
      emit(state.copyWith(exporting: false, failure: ReportFailure.export));
      event.completer.complete(null);
    }
  }

  Future<void> _onExportMonthRequested(
    ReportExportMonthRequested event,
    Emitter<ReportState> emit,
  ) async {
    if (state.exporting) {
      event.completer.complete(null);
      return;
    }
    emit(state.copyWith(exporting: true, clearFailure: true));
    try {
      final result = await _export(
        from: CaseDates.monthStart(event.month),
        to: CaseDates.monthEnd(event.month),
        format: event.format,
        localeCode: _settings().localeCode,
        walletId: _settings().activeWalletId,
      );
      emit(state.copyWith(exporting: false));
      event.completer.complete(result);
    } catch (_) {
      emit(state.copyWith(exporting: false, failure: ReportFailure.export));
      event.completer.complete(null);
    }
  }

  void _onFailureCleared(
    ReportFailureCleared event,
    Emitter<ReportState> emit,
  ) {
    emit(state.copyWith(clearFailure: true));
  }

  Future<bool> generateForMonth(DateTime month) async {
    final completer = Completer<bool>();
    add(ReportGenerateRequested(month, completer));
    return completer.future;
  }

  Future<ExportResult?> export(
    InvestigationReport report,
    ExportFormat format,
  ) async {
    final completer = Completer<ExportResult?>();
    add(ReportExportRequested(report, format, completer));
    return completer.future;
  }

  Future<ExportResult?> exportMonth({
    required DateTime month,
    required ExportFormat format,
  }) async {
    final completer = Completer<ExportResult?>();
    add(ReportExportMonthRequested(month, format, completer));
    return completer.future;
  }

  void clearFailure() => add(const ReportFailureCleared());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
