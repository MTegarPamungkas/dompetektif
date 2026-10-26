import 'dart:async';

import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/usecases/dashboard_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardState extends Equatable {
  const DashboardState({this.data, this.loading = true, this.failure = false});

  final DashboardData? data;
  final bool loading;
  final bool failure;

  DashboardState copyWith({DashboardData? data, bool? loading, bool? failure}) {
    return DashboardState(
      data: data ?? this.data,
      loading: loading ?? this.loading,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [data, loading, failure];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._watch) : super(const DashboardState()) {
    _subscribe();
  }

  final WatchDashboard _watch;
  StreamSubscription<DashboardData>? _subscription;

  void _subscribe() {
    _subscription = _watch().listen(
      (data) =>
          emit(DashboardState(data: data, loading: false, failure: false)),
      onError: (_) => emit(const DashboardState(loading: false, failure: true)),
    );
  }

  void reload() {
    _subscription?.cancel();
    emit(const DashboardState());
    _subscribe();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
