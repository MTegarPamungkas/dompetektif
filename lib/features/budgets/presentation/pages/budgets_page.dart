import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/features/budgets/presentation/cubit/budget_cubit.dart';
import 'package:dompetektif/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsCubit>().state;
    return BlocListener<BudgetCubit, BudgetState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppSnackBar(context, switch (failure) {
          BudgetFailure.load => l10n.errorLoadData,
          BudgetFailure.save => l10n.errorSaveData,
          BudgetFailure.delete => l10n.errorDeleteData,
        }, error: true);
        context.read<BudgetCubit>().clearFailure();
      },
      child: BlocBuilder<BudgetCubit, BudgetState>(
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
                _MonthSwitcher(
                  month: state.month,
                  onPrevious: () => context.read<BudgetCubit>().previousMonth(),
                  onNext: () => context.read<BudgetCubit>().nextMonth(),
                ),
                const SizedBox(height: 16),
                _BudgetSummary(
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
                                            ? _BudgetCard(
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
    final success = await context.read<BudgetCubit>().deleteBudget(
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
        value: context.read<BudgetCubit>(),
        child: _BudgetEditorSheet(current: current),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        IconButton.outlined(
          tooltip: l10n.previousMonth,
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
            decoration: BoxDecoration(
              color: context.dompet.surface,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: context.dompet.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 17,
                  color: context.dompet.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  CaseDates.monthYear(month, l10n.locale.languageCode),
                  style: context.texts.titleSmall?.copyWith(fontSize: 12.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        IconButton.outlined(
          tooltip: l10n.nextMonth,
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _BudgetSummary extends StatelessWidget {
  const _BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.ratio,
    required this.count,
    required this.hidden,
  });

  final int totalBudget;
  final int totalSpent;
  final double ratio;
  final int count;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = totalBudget - totalSpent;
    return AppCard(
      padding: const EdgeInsets.all(20),
      accent: ratio >= 1
          ? context.dompet.evidence
          : (ratio >= 0.8 ? context.dompet.warning : context.dompet.accent),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.budgetProgress.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  letterSpacing: 1.3,
                  fontSize: 8.5,
                ),
              ),
              const Spacer(),
              StatusPill(
                label: '$count ${l10n.categories}',
                tone: PillTone.neutral,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    MoneyFormatter.format(
                      totalSpent,
                      localeCode: l10n.locale.languageCode,
                      hidden: hidden,
                    ),
                    maxLines: 1,
                    style: AppTypography.money(
                      fontSize: 31,
                      color: context.dompet.ink,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${MoneyFormatter.format(totalBudget, localeCode: l10n.locale.languageCode, hidden: hidden)}',
                maxLines: 1,
                style: context.texts.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          BudgetProgressBar(ratio: ratio, height: 8),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InfoRow(
                  label: l10n.remaining,
                  value: MoneyFormatter.format(
                    remaining,
                    localeCode: l10n.locale.languageCode,
                    hidden: hidden,
                  ),
                  valueColor: remaining < 0
                      ? context.dompet.evidence
                      : context.dompet.success,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                MoneyFormatter.percent(
                  ratio,
                  localeCode: l10n.locale.languageCode,
                ),
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 10,
                  color: ratio >= 1
                      ? context.dompet.evidence
                      : (ratio >= 0.8
                            ? context.dompet.warning
                            : context.dompet.success),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.item,
    required this.hidden,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetProgress item;
  final bool hidden;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = switch (item.status) {
      BudgetStatus.over => context.dompet.evidence,
      BudgetStatus.warning => context.dompet.warning,
      BudgetStatus.safe => context.dompet.success,
    };
    final statusLabel = switch (item.status) {
      BudgetStatus.over => l10n.budgetStatusOver,
      BudgetStatus.warning => l10n.budgetStatusWarning,
      BudgetStatus.safe => l10n.budgetStatusSafe,
    };
    return AppCard(
      onTap: onEdit,
      accent: tone,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CategoryAvatar(category: item.category, size: 39),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedCategoryName(l10n, item.category),
                      style: context.texts.titleSmall?.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${MoneyFormatter.percent(item.budget.alertThreshold, localeCode: l10n.locale.languageCode)} ${l10n.threshold.toLowerCase()}',
                      style: context.texts.bodySmall?.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: statusLabel,
                tone: item.status == BudgetStatus.safe
                    ? PillTone.success
                    : (item.status == BudgetStatus.warning
                          ? PillTone.accent
                          : PillTone.evidence),
                compact: true,
              ),
              PopupMenuButton<String>(
                tooltip: l10n.edit,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: context.dompet.inkMuted,
                ),
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_outlined, size: 17),
                        const SizedBox(width: 9),
                        Text(l10n.edit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                          color: context.dompet.evidence,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          l10n.delete,
                          style: TextStyle(color: context.dompet.evidence),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  MoneyFormatter.format(
                    item.spent.amountMinor,
                    localeCode: l10n.locale.languageCode,
                    hidden: hidden,
                  ),
                  style: AppTypography.money(
                    fontSize: 22,
                    color: context.dompet.ink,
                  ),
                ),
              ),
              Text(
                '/ ${MoneyFormatter.format(item.budget.amount.amountMinor, localeCode: l10n.locale.languageCode, hidden: hidden)}',
                style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 9),
          BudgetProgressBar(ratio: item.ratio, height: 7),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.remaining}: ${MoneyFormatter.format(item.remaining.amountMinor, localeCode: l10n.locale.languageCode, hidden: hidden)}',
                  style: context.texts.bodySmall?.copyWith(fontSize: 9),
                ),
              ),
              Text(
                MoneyFormatter.percent(
                  item.ratio,
                  localeCode: l10n.locale.languageCode,
                ),
                style: context.texts.labelSmall?.copyWith(
                  color: tone,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetEditorSheet extends StatefulWidget {
  const _BudgetEditorSheet({this.current});

  final BudgetProgress? current;

  @override
  State<_BudgetEditorSheet> createState() => _BudgetEditorSheetState();
}

class _BudgetEditorSheetState extends State<_BudgetEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _categoryId;
  double _threshold = 0.8;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    if (current != null) {
      _categoryId = current.budget.categoryId;
      _amountController.text = MoneyFormatter.input(
        current.budget.amount.amountMinor,
      );
      _threshold = current.budget.alertThreshold;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.watch<BudgetCubit>();
    final state = cubit.state;
    final selectedMonth = state.month;
    final expenseCategories = state.categories
        .where((category) => category.kind == CategoryKind.expense)
        .toList();
    final budgetedIds = {
      for (final item in state.progress)
        if (item.budget.id != widget.current?.budget.id) item.budget.categoryId,
    };
    final available = expenseCategories
        .where(
          (category) =>
              !budgetedIds.contains(category.id) || category.id == _categoryId,
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.current == null ? l10n.budgetCreate : l10n.budgetEdit,
                style: context.texts.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                CaseDates.monthYear(selectedMonth, l10n.locale.languageCode),
                style: context.texts.bodySmall,
              ),
              const SizedBox(height: 18),
              AppDropdownField<String>(
                label: l10n.category,
                value: _categoryId,
                items: available.map((category) => category.id).toList(),
                labelBuilder: (id) {
                  final category = available.firstWhere(
                    (category) => category.id == id,
                  );
                  return localizedCategoryName(l10n, category);
                },
                prefixIcon: Icons.category_outlined,
                validator: (value) =>
                    value == null ? l10n.categoryRequired : null,
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              const SizedBox(height: 14),
              AppMoneyField(
                controller: _amountController,
                label: l10n.budgetCreate,
                helper: l10n.budgetThresholdHint,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(l10n.threshold, style: context.texts.bodySmall),
                  const Spacer(),
                  Text(
                    MoneyFormatter.percent(
                      _threshold,
                      localeCode: l10n.locale.languageCode,
                    ),
                    style: context.texts.labelMedium?.copyWith(
                      color: context.dompet.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _threshold,
                min: 0.5,
                max: 1,
                divisions: 10,
                label: MoneyFormatter.percent(
                  _threshold,
                  localeCode: l10n.locale.languageCode,
                ),
                onChanged: (value) => setState(() => _threshold = value),
              ),
              Text(
                l10n.budgetThresholdHint,
                style: context.texts.bodySmall?.copyWith(fontSize: 10),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: state.saving ? null : _save,
                      child: state.saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = MoneyFormatter.parse(_amountController.text);
    if (amount == null || amount <= 0 || _categoryId == null) return;
    final l10n = context.l10n;
    final cubit = context.read<BudgetCubit>();
    final current = widget.current;
    final now = DateTime.now();
    final budget = Budget(
      id: current?.budget.id ?? getIt<Uuid>().v4(),
      ownerId: current?.budget.ownerId ?? '',
      categoryId: _categoryId!,
      amount: Money(amount),
      month: cubit.state.month,
      alertThreshold: _threshold,
      createdAt: current?.budget.createdAt ?? now,
      updatedAt: now,
    );
    final success = await cubit.saveBudget(budget);
    if (!mounted || !success) return;
    showAppSnackBar(context, l10n.budgetCreated);
    Navigator.of(context).pop();
  }
}
