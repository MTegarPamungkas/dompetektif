import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:equatable/equatable.dart';

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
