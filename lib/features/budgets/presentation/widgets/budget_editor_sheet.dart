import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class BudgetEditorSheet extends StatefulWidget {
  const BudgetEditorSheet({super.key, this.current});

  final BudgetProgress? current;

  @override
  State<BudgetEditorSheet> createState() => BudgetEditorSheetState();
}

class BudgetEditorSheetState extends State<BudgetEditorSheet> {
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
    final bloc = context.watch<BudgetBloc>();
    final state = bloc.state;
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
    final bloc = context.read<BudgetBloc>();
    final current = widget.current;
    final now = DateTime.now();
    final budget = Budget(
      id: current?.budget.id ?? getIt<Uuid>().v4(),
      ownerId: current?.budget.ownerId ?? '',
      categoryId: _categoryId!,
      amount: Money(amount),
      month: bloc.state.month,
      alertThreshold: _threshold,
      createdAt: current?.budget.createdAt ?? now,
      updatedAt: now,
    );
    final success = await bloc.saveBudget(budget);
    if (!mounted || !success) return;
    showAppSnackBar(context, l10n.budgetCreated);
    Navigator.of(context).pop();
  }
}
