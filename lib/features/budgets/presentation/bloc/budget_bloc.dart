import 'dart:async';

import 'package:dompetektif/core/utils/stream_combine.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/services/device_services.dart';
import 'package:dompetektif/domain/usecases/budget_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'budget_event.dart';
import 'budget_state.dart';

export 'budget_event.dart';
export 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  BudgetBloc(
    this._watchProgress,
    this._watchCategories,
    this._save,
    this._delete,
    this._notifications,
  ) : super(
        BudgetState(month: DateTime(DateTime.now().year, DateTime.now().month)),
      ) {
    on<BudgetStarted>(_onStarted);
    on<BudgetDataReceived>(_onDataReceived);
    on<BudgetLoadFailed>(_onLoadFailed);
    on<BudgetMonthChanged>(_onMonthChanged);
    on<BudgetSaveRequested>(_onSaveRequested);
    on<BudgetDeleteRequested>(_onDeleteRequested);
    on<BudgetFailureCleared>(_onFailureCleared);
    add(const BudgetStarted());
  }

  final WatchBudgetProgress _watchProgress;
  final WatchCategories _watchCategories;
  final SaveBudget _save;
  final DeleteBudget _delete;
  final NotificationService _notifications;

  StreamSubscription<(List<BudgetProgress>, List<Category>)>? _subscription;

  void _onStarted(BudgetStarted event, Emitter<BudgetState> emit) {
    _subscribe();
  }

  void _subscribe() {
    _subscription?.cancel();
    _subscription =
        combineLatest2(_watchProgress(month: state.month), _watchCategories(), (
          List<BudgetProgress> progress,
          List<Category> categories,
        ) {
          return (progress, categories);
        }).listen((value) {
          final (progress, categories) = value;
          add(BudgetDataReceived(progress, categories));
        }, onError: (_) => add(const BudgetLoadFailed()));
  }

  void _onDataReceived(BudgetDataReceived event, Emitter<BudgetState> emit) {
    emit(
      state.copyWith(
        progress: event.progress,
        categories: event.categories,
        loading: false,
        clearFailure: true,
      ),
    );
  }

  void _onLoadFailed(BudgetLoadFailed event, Emitter<BudgetState> emit) {
    emit(state.copyWith(loading: false, failure: BudgetFailure.load));
  }

  void _onMonthChanged(BudgetMonthChanged event, Emitter<BudgetState> emit) {
    emit(
      state.copyWith(
        month: DateTime(event.month.year, event.month.month),
        loading: true,
        clearFailure: true,
      ),
    );
    _subscribe();
  }

  Future<void> _onSaveRequested(
    BudgetSaveRequested event,
    Emitter<BudgetState> emit,
  ) async {
    if (state.saving) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(saving: true, clearFailure: true));
    try {
      await _save(event.budget);
      unawaited(_notifications.requestPermission());
      emit(state.copyWith(saving: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(saving: false, failure: BudgetFailure.save));
      event.completer.complete(false);
    }
  }

  Future<void> _onDeleteRequested(
    BudgetDeleteRequested event,
    Emitter<BudgetState> emit,
  ) async {
    if (state.deleting) {
      event.completer.complete(false);
      return;
    }
    emit(state.copyWith(deleting: true, clearFailure: true));
    try {
      await _delete(event.id);
      emit(state.copyWith(deleting: false));
      event.completer.complete(true);
    } catch (_) {
      emit(state.copyWith(deleting: false, failure: BudgetFailure.delete));
      event.completer.complete(false);
    }
  }

  void _onFailureCleared(
    BudgetFailureCleared event,
    Emitter<BudgetState> emit,
  ) {
    emit(state.copyWith(clearFailure: true));
  }

  void setMonth(DateTime month) => add(BudgetMonthChanged(month));

  void previousMonth() =>
      setMonth(DateTime(state.month.year, state.month.month - 1));

  void nextMonth() =>
      setMonth(DateTime(state.month.year, state.month.month + 1));

  Future<bool> saveBudget(Budget budget) async {
    final completer = Completer<bool>();
    add(BudgetSaveRequested(budget, completer));
    return completer.future;
  }

  Future<bool> deleteBudget(String id) async {
    final completer = Completer<bool>();
    add(BudgetDeleteRequested(id, completer));
    return completer.future;
  }

  void clearFailure() => add(const BudgetFailureCleared());

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
