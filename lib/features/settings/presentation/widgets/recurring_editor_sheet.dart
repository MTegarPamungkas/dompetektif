import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class RecurringEditorSheet extends StatefulWidget {
  const RecurringEditorSheet({super.key, this.rule});

  final RecurringRule? rule;

  @override
  State<RecurringEditorSheet> createState() => RecurringEditorSheetState();
}

class RecurringEditorSheetState extends State<RecurringEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  TransactionType _type = TransactionType.expense;
  RecurrenceFrequency _frequency = RecurrenceFrequency.monthly;
  String? _walletId;
  String? _toWalletId;
  String? _categoryId;
  DateTime _nextRun = DateTime.now();
  int _interval = 1;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    final wallets = context.read<SettingsDataBloc>().state.wallets;
    _walletId = rule?.walletId ?? (wallets.isEmpty ? null : wallets.first.id);
    _toWalletId = rule?.toWalletId;
    _categoryId = rule?.categoryId;
    _type = rule?.type ?? TransactionType.expense;
    _frequency = rule?.frequency ?? RecurrenceFrequency.monthly;
    _nextRun = rule?.nextRunAt ?? DateTime.now();
    _interval = rule?.interval ?? 1;
    _active = rule?.isActive ?? true;
    _amountController = TextEditingController(
      text: rule == null ? '' : MoneyFormatter.input(rule.amount.amountMinor),
    );
    _merchantController = TextEditingController(text: rule?.merchant ?? '');
    _noteController = TextEditingController(text: rule?.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SettingsDataBloc>().state;
    final kind = _type == TransactionType.income
        ? CategoryKind.income
        : CategoryKind.expense;
    final categories = state.categories
        .where((category) => category.kind == kind)
        .toList();
    final destinations = state.wallets
        .where((wallet) => wallet.id != _walletId)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.rule == null
                      ? l10n.recurringCreate
                      : l10n.recurringEdit,
                  style: context.texts.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(l10n.recurringSubtitle, style: context.texts.bodySmall),
                const SizedBox(height: 18),
                AppSegmented<TransactionType>(
                  values: TransactionType.values,
                  selected: _type,
                  expanded: true,
                  labelBuilder: (type) => switch (type) {
                    TransactionType.expense => l10n.expense,
                    TransactionType.income => l10n.income,
                    TransactionType.transfer => l10n.transfer,
                  },
                  onChanged: (type) => setState(() {
                    _type = type;
                    _categoryId = null;
                    _toWalletId = null;
                  }),
                ),
                const SizedBox(height: 14),
                AppMoneyField(
                  controller: _amountController,
                  label: l10n.amount,
                ),
                const SizedBox(height: 12),
                AppDropdownField<String>(
                  label: l10n.wallet,
                  value: _walletId,
                  items: state.wallets.map((wallet) => wallet.id).toList(),
                  labelBuilder: (id) => state.wallets
                      .firstWhere((wallet) => wallet.id == id)
                      .name,
                  prefixIcon: Icons.wallet_outlined,
                  validator: (value) =>
                      value == null ? l10n.walletRequired : null,
                  onChanged: (value) => setState(() {
                    _walletId = value;
                    if (_toWalletId == value) _toWalletId = null;
                  }),
                ),
                const SizedBox(height: 12),
                if (_type == TransactionType.transfer)
                  AppDropdownField<String>(
                    label: l10n.destinationWallet,
                    value: _toWalletId,
                    items: destinations.map((wallet) => wallet.id).toList(),
                    labelBuilder: (id) => destinations
                        .firstWhere((wallet) => wallet.id == id)
                        .name,
                    prefixIcon: Icons.arrow_forward_rounded,
                    validator: (value) =>
                        value == null ? l10n.destinationRequired : null,
                    onChanged: (value) => setState(() => _toWalletId = value),
                  )
                else
                  AppDropdownField<String>(
                    label: l10n.category,
                    value: _categoryId,
                    items: categories.map((category) => category.id).toList(),
                    labelBuilder: (id) => localizedCategoryName(
                      l10n,
                      categories.firstWhere((category) => category.id == id),
                    ),
                    prefixIcon: Icons.category_outlined,
                    validator: (value) =>
                        value == null ? l10n.categoryRequired : null,
                    onChanged: (value) => setState(() => _categoryId = value),
                  ),
                const SizedBox(height: 12),
                AppDropdownField<RecurrenceFrequency>(
                  label: l10n.frequency,
                  value: _frequency,
                  items: RecurrenceFrequency.values,
                  labelBuilder: (frequency) => switch (frequency) {
                    RecurrenceFrequency.daily => l10n.daily,
                    RecurrenceFrequency.weekly => l10n.weekly,
                    RecurrenceFrequency.monthly => l10n.monthly,
                    RecurrenceFrequency.yearly => l10n.yearly,
                  },
                  prefixIcon: Icons.event_repeat_rounded,
                  onChanged: (value) =>
                      setState(() => _frequency = value ?? _frequency),
                ),
                const SizedBox(height: 12),
                AppDateField(
                  label: l10n.nextRun,
                  value: _nextRun,
                  onChanged: (value) => setState(() => _nextRun = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _merchantController,
                  label: l10n.merchant,
                  hint: l10n.t('Contoh: Spotify', 'e.g. Spotify'),
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 19),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _noteController,
                  label: l10n.note,
                  hint: l10n.t('Keterangan langganan', 'Subscription note'),
                  prefixIcon: const Icon(Icons.notes_rounded, size: 19),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                  title: Text(
                    l10n.active,
                    style: context.texts.bodyMedium?.copyWith(fontSize: 12),
                  ),
                  subtitle: Text(
                    l10n.recurringSubtitle,
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                  ),
                ),
                const SizedBox(height: 16),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = MoneyFormatter.parse(_amountController.text);
    if (amount == null || amount <= 0 || _walletId == null) return;
    final l10n = context.l10n;
    final current = widget.rule;
    final now = DateTime.now();
    final rule = RecurringRule(
      id: current?.id ?? getIt<Uuid>().v4(),
      ownerId: current?.ownerId ?? getIt<GetCurrentUser>()()?.id ?? '',
      walletId: _walletId!,
      type: _type,
      amount: Money(amount),
      categoryId: _type == TransactionType.transfer ? null : _categoryId,
      toWalletId: _type == TransactionType.transfer ? _toWalletId : null,
      note: _noteController.text.trim(),
      merchant: _merchantController.text.trim(),
      frequency: _frequency,
      interval: _interval,
      nextRunAt: _nextRun,
      endAt: current?.endAt,
      isActive: _active,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );
    final success = await context.read<SettingsDataBloc>().saveRule(rule);
    if (!mounted || !success) return;
    showAppSnackBar(context, l10n.recurringCreated);
    Navigator.of(context).pop();
  }
}
