import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:equatable/equatable.dart';

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
