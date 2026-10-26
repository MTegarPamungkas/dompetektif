import 'dart:async';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/services/device_services.dart';
import 'package:dompetektif/domain/usecases/budget_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum BudgetFailure { load, save, delete }

class BudgetState extends Equatable {
  const BudgetState({
    required this.month,
    this.progress = const [],
    this.categories = const [],
    this.loading = true,
    this.saving = false,
    this.deleting = false,
    this.failure,
  });

  final DateTime month;
  final List<BudgetProgress> progress;
  final List<Category> categories;
  final bool loading;
  final bool saving;
  final bool deleting;
  final BudgetFailure? failure;

  BudgetState copyWith({
    DateTime? month,
    List<BudgetProgress>? progress,
    List<Category>? categories,
    bool? loading,
    bool? saving,
    bool? deleting,
    BudgetFailure? failure,
    bool clearFailure = false,
  }) {
    return BudgetState(
      month: month ?? this.month,
      progress: progress ?? this.progress,
      categories: categories ?? this.categories,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    month,
    progress,
    categories,
    loading,
    saving,
    deleting,
    failure,
  ];
}

class BudgetCubit extends Cubit<BudgetState> {
  BudgetCubit(
    this._watchProgress,
    this._watchCategories,
    this._save,
    this._delete,
    this._notifications,
  ) : super(
        BudgetState(month: DateTime(DateTime.now().year, DateTime.now().month)),
      ) {
    _subscribe();
  }

  final WatchBudgetProgress _watchProgress;
  final WatchCategories _watchCategories;
  final SaveBudget _save;
  final DeleteBudget _delete;
  final NotificationService _notifications;

  StreamSubscription<(List<BudgetProgress>, List<Category>)>? _subscription;

  void _subscribe() {
    _subscription?.cancel();
    _subscription =
        combineLatest2(_watchProgress(month: state.month), _watchCategories(), (
          List<BudgetProgress> progress,
          List<Category> categories,
        ) {
          return (progress, categories);
        }).listen(
          (value) {
            final (progress, categories) = value;
            emit(
              state.copyWith(
                progress: progress,
                categories: categories,
                loading: false,
                clearFailure: true,
              ),
            );
          },
          onError: (_) =>
              emit(state.copyWith(loading: false, failure: BudgetFailure.load)),
        );
  }

  void setMonth(DateTime month) {
    emit(
      state.copyWith(
        month: DateTime(month.year, month.month),
        loading: true,
        clearFailure: true,
      ),
    );
    _subscribe();
  }

  void previousMonth() =>
      setMonth(DateTime(state.month.year, state.month.month - 1));

  void nextMonth() =>
      setMonth(DateTime(state.month.year, state.month.month + 1));

  Future<bool> saveBudget(Budget budget) async {
    if (state.saving) return false;
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await _save(budget);
      unawaited(_notifications.requestPermission());
      emit(state.copyWith(saving: false));
      return true;
    } catch (_) {
      emit(state.copyWith(saving: false, failure: BudgetFailure.save));
      return false;
    }
  }

  Future<bool> deleteBudget(String id) async {
    if (state.deleting) return false;
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(id);
      emit(state.copyWith(deleting: false));
      return true;
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: BudgetFailure.delete));
      return false;
    }
  }

  void clearFailure() => emit(state.copyWith(clearFailure: true));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
