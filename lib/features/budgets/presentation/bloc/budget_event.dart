import 'dart:async';

import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/category.dart';

sealed class BudgetEvent {
  const BudgetEvent();
}

final class BudgetStarted extends BudgetEvent {
  const BudgetStarted();
}

final class BudgetDataReceived extends BudgetEvent {
  const BudgetDataReceived(this.progress, this.categories);

  final List<BudgetProgress> progress;
  final List<Category> categories;
}

final class BudgetLoadFailed extends BudgetEvent {
  const BudgetLoadFailed();
}

final class BudgetMonthChanged extends BudgetEvent {
  const BudgetMonthChanged(this.month);

  final DateTime month;
}

final class BudgetSaveRequested extends BudgetEvent {
  const BudgetSaveRequested(this.budget, this.completer);

  final Budget budget;
  final Completer<bool> completer;
}

final class BudgetDeleteRequested extends BudgetEvent {
  const BudgetDeleteRequested(this.id, this.completer);

  final String id;
  final Completer<bool> completer;
}

final class BudgetFailureCleared extends BudgetEvent {
  const BudgetFailureCleared();
}
