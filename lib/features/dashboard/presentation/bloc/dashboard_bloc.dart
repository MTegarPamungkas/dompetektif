import 'dart:async';

import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/usecases/dashboard_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dashboard_event.dart';
import 'dashboard_state.dart';

export 'dashboard_event.dart';
export 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._watch) : super(const DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardReloaded>(_onReloaded);
    on<DashboardDataReceived>(_onDataReceived);
    on<DashboardFailed>(_onFailed);
    add(const DashboardStarted());
  }

  final WatchDashboard _watch;
  StreamSubscription<DashboardData>? _subscription;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = _watch().listen(
      (data) => add(DashboardDataReceived(data)),
      onError: (_) => add(const DashboardFailed()),
    );
  }

  Future<void> _onReloaded(
    DashboardReloaded event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardState());
    add(const DashboardStarted());
  }

  void _onDataReceived(
    DashboardDataReceived event,
    Emitter<DashboardState> emit,
  ) {
    emit(DashboardState(data: event.data, loading: false, failure: false));
  }

  void _onFailed(DashboardFailed event, Emitter<DashboardState> emit) {
    emit(const DashboardState(loading: false, failure: true));
  }

  void reload() => add(const DashboardReloaded());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
