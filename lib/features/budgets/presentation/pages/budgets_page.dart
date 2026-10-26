import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/budget_widgets.dart';
import '../widgets/budget_editor_sheet.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsBloc>().state;
    return BlocListener<BudgetBloc, BudgetState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppSnackBar(context, switch (failure) {
          BudgetFailure.load => l10n.errorLoadData,
          BudgetFailure.save => l10n.errorSaveData,
          BudgetFailure.delete => l10n.errorDeleteData,
        }, error: true);
        context.read<BudgetBloc>().clearFailure();
      },
      child: BlocBuilder<BudgetBloc, BudgetState>(
        builder: (context, state) {
          final totalBudget = state.progress.fold<int>(
            0,
            (sum, item) => sum + item.budget.amount.amountMinor,
          );
          final totalSpent = state.progress.fold<int>(
            0,
            (sum, item) => sum + item.spent.amountMinor,
          );
          final ratio = totalBudget == 0 ? 0.0 : totalSpent / totalBudget;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(l10n.budgets),
              actions: [
                IconButton(
                  tooltip: l10n.add,
                  onPressed: () => _openEditor(context, null),
                  icon: const Icon(Icons.add_rounded),
                ),
                const SizedBox(width: 6),
              ],
            ),
            body: PageScroll(
              children: [
                DossierHeader(
                  eyebrow:
                      '${l10n.caseFile} / ${CaseDates.monthYear(state.month, l10n.locale.languageCode)}',
                  title: l10n.budgets,
                  subtitle: l10n.budgetsSubtitle,
                  trailing: FilledButton.icon(
                    onPressed: () => _openEditor(context, null),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.budgetCreate),
                  ),
                ),
                const SizedBox(height: 22),
                MonthSwitcher(
                  month: state.month,
                  onPrevious: () => context.read<BudgetBloc>().previousMonth(),
                  onNext: () => context.read<BudgetBloc>().nextMonth(),
                ),
                const SizedBox(height: 16),
                BudgetSummary(
                  totalBudget: totalBudget,
                  totalSpent: totalSpent,
                  ratio: ratio,
                  count: state.progress.length,
                  hidden: settings.hideAmounts,
                ),
                const SizedBox(height: 20),
                if (state.loading)
                  const LoadingState()
                else if (state.progress.isEmpty)
                  EmptyState(
                    icon: Icons.track_changes_rounded,
                    title: l10n.noBudgets,
                    body: l10n.budgetsSubtitle,
                    action: FilledButton.icon(
                      onPressed: () => _openEditor(context, null),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.budgetCreate),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 860 ? 2 : 1;
                      final items = state.progress;
                      return Column(
                        children: [
                          for (
                            var index = 0;
                            index < items.length;
                            index += columns
                          )
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (
                                    var column = 0;
                                    column < columns;
                                    column++
                                  )
                                    Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: column < columns - 1 ? 12 : 0,
                                        ),
                                        child: index + column < items.length
                                            ? BudgetCard(
                                                item: items[index + column],
                                                hidden: settings.hideAmounts,
                                                onEdit: () => _openEditor(
                                                  context,
                                                  items[index + column],
                                                ),
                                                onDelete: () => _delete(
                                                  context,
                                                  items[index + column],
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _delete(BuildContext context, BudgetProgress item) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteBudgetTitle,
      body: l10n.deleteBudgetBody,
      confirmLabel: l10n.confirmDelete,
    );
    if (!confirmed || !context.mounted) return;
    final success = await context.read<BudgetBloc>().deleteBudget(
      item.budget.id,
    );
    if (!context.mounted) return;
    if (success) showAppSnackBar(context, l10n.deleteSuccess);
  }

  Future<void> _openEditor(
    BuildContext context,
    BudgetProgress? current,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => BlocProvider.value(
        value: context.read<BudgetBloc>(),
        child: BudgetEditorSheet(current: current),
      ),
    );
  }
}
