import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/iterable_x.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/features/settings/presentation/cubit/settings_data_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<SettingsDataCubit, SettingsDataState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppSnackBar(context, switch (failure) {
          SettingsDataFailure.load => l10n.errorLoadData,
          SettingsDataFailure.save => l10n.errorSaveData,
          SettingsDataFailure.delete => l10n.errorDeleteData,
          SettingsDataFailure.runDue => l10n.errorSaveData,
        }, error: true);
        context.read<SettingsDataCubit>().clearFailure();
      },
      child: BlocBuilder<SettingsDataCubit, SettingsDataState>(
        builder: (context, state) {
          final active = state.rules.where((rule) => rule.isActive).length;
          final next = state.rules
              .where((rule) => rule.isActive)
              .map((rule) => rule.nextRunAt)
              .fold<DateTime?>(
                null,
                (value, item) =>
                    value == null || item.isBefore(value) ? item : value,
              );
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(l10n.recurring),
              actions: [
                IconButton(
                  tooltip: l10n.recurringCreate,
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
                      '${l10n.caseFile} / ${state.rules.length} ${l10n.recurring.toLowerCase()}',
                  title: l10n.recurring,
                  subtitle: l10n.recurringSubtitle,
                  trailing: FilledButton.icon(
                    onPressed: () => _openEditor(context, null),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.recurringCreate),
                  ),
                ),
                const SizedBox(height: 22),
                _RecurringSummary(
                  total: state.rules.length,
                  active: active,
                  next: next,
                  running: state.runningDue,
                  onRunDue: () => _runDue(context),
                ),
                const SizedBox(height: 16),
                if (state.loading)
                  const LoadingState()
                else if (state.rules.isEmpty)
                  EmptyState(
                    icon: Icons.event_repeat_rounded,
                    title: l10n.recurringCreate,
                    body: l10n.recurringSubtitle,
                    action: FilledButton.icon(
                      onPressed: () => _openEditor(context, null),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.recurringCreate),
                    ),
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (
                          var index = 0;
                          index < state.rules.length;
                          index++
                        ) ...[
                          if (index > 0) Divider(color: context.dompet.line),
                          _RecurringRow(
                            rule: state.rules[index],
                            walletName: state.wallets
                                .where(
                                  (wallet) =>
                                      wallet.id == state.rules[index].walletId,
                                )
                                .map((wallet) => wallet.name)
                                .firstOrNull,
                            category: state.categories
                                .where(
                                  (category) =>
                                      category.id ==
                                      state.rules[index].categoryId,
                                )
                                .firstOrNull,
                            toWalletName: state.wallets
                                .where(
                                  (wallet) =>
                                      wallet.id ==
                                      state.rules[index].toWalletId,
                                )
                                .map((wallet) => wallet.name)
                                .firstOrNull,
                            onEdit: () =>
                                _openEditor(context, state.rules[index]),
                            onDelete: () =>
                                _delete(context, state.rules[index]),
                            onToggle: (active) =>
                                _toggle(context, state.rules[index], active),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _runDue(BuildContext context) async {
    final l10n = context.l10n;
    final count = await context.read<SettingsDataCubit>().runDueRecurring();
    if (!context.mounted) return;
    if (count == null) return;
    showAppSnackBar(context, count == 0 ? l10n.noDue : l10n.dueCompleted);
  }

  Future<void> _toggle(
    BuildContext context,
    RecurringRule rule,
    bool active,
  ) async {
    final success = await context.read<SettingsDataCubit>().saveRule(
      rule.copyWith(isActive: active, updatedAt: DateTime.now()),
    );
    if (!context.mounted) return;
    if (success) showAppSnackBar(context, context.l10n.recurringCreated);
  }

  Future<void> _delete(BuildContext context, RecurringRule rule) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteRecurringTitle,
      body: l10n.deleteRecurringBody,
      confirmLabel: l10n.confirmDelete,
    );
    if (!confirmed || !context.mounted) return;
    final success = await context.read<SettingsDataCubit>().deleteRule(rule.id);
    if (!context.mounted) return;
    if (success) showAppSnackBar(context, l10n.deleteSuccess);
  }

  Future<void> _openEditor(BuildContext context, RecurringRule? rule) async {
    if (context.read<SettingsDataCubit>().state.wallets.isEmpty) {
      showAppSnackBar(context, context.l10n.createFirstWalletBody, error: true);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 660),
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsDataCubit>(),
        child: _RecurringEditorSheet(rule: rule),
      ),
    );
  }
}

class _RecurringSummary extends StatelessWidget {
  const _RecurringSummary({
    required this.total,
    required this.active,
    required this.next,
    required this.running,
    required this.onRunDue,
  });

  final int total;
  final int active;
  final DateTime? next;
  final bool running;
  final VoidCallback onRunDue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final stats = [
            _SummaryStat(
              label: compact ? l10n.total : l10n.recurring,
              value: '$total',
              icon: Icons.event_repeat_rounded,
              color: context.dompet.accent,
            ),
            _SummaryStat(
              label: l10n.active,
              value: '$active',
              icon: Icons.play_circle_outline_rounded,
              color: context.dompet.success,
            ),
            _SummaryStat(
              label: compact ? l10n.nextRunShort : l10n.nextRun,
              value: next == null
                  ? '—'
                  : CaseDates.dayMonth(next!, l10n.locale.languageCode),
              icon: Icons.schedule_rounded,
              color: context.dompet.info,
            ),
          ];
          final button = FilledButton.tonalIcon(
            onPressed: running ? null : onRunDue,
            icon: running
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(l10n.runDue),
          );
          if (compact) {
            final veryCompact = constraints.maxWidth < 330;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (veryCompact) ...[
                  Row(
                    children: [
                      Expanded(child: stats[0]),
                      const SizedBox(width: 8),
                      Expanded(child: stats[1]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  stats[2],
                ] else
                  Row(
                    children: [
                      for (var index = 0; index < stats.length; index++) ...[
                        Expanded(child: stats[index]),
                        if (index < stats.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                const SizedBox(height: 14),
                button,
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < stats.length; index++) ...[
                Expanded(child: stats[index]),
                if (index < stats.length - 1) const SizedBox(width: 10),
              ],
              const SizedBox(width: 8),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: context.dompet.surfaceMuted.withValues(alpha: 0.6),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.dompet.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(fontSize: 7),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.texts.titleSmall?.copyWith(
                    fontSize: 12.5,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  const _RecurringRow({
    required this.rule,
    required this.walletName,
    required this.category,
    required this.toWalletName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final RecurringRule rule;
  final String? walletName;
  final Category? category;
  final String? toWalletName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = rule.merchant.trim().isNotEmpty
        ? rule.merchant
        : (rule.note.trim().isNotEmpty
              ? rule.note
              : (category == null
                    ? l10n.recurring
                    : localizedCategoryName(l10n, category!)));
    final frequency = switch (rule.frequency) {
      RecurrenceFrequency.daily => l10n.daily,
      RecurrenceFrequency.weekly => l10n.weekly,
      RecurrenceFrequency.monthly => l10n.monthly,
      RecurrenceFrequency.yearly => l10n.yearly,
    };
    final titleRow = Row(
      children: [
        Flexible(
          child: Text(
            title,
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 5),
        if (!rule.isActive)
          StatusPill(
            label: l10n.inactive,
            tone: PillTone.neutral,
            compact: true,
          ),
      ],
    );
    final subtitle = Text(
      [
        frequency,
        ?walletName,
        ?toWalletName,
        '${l10n.nextRun}: ${CaseDates.dayMonth(rule.nextRunAt, l10n.locale.languageCode)}',
      ].join(' · '),
      style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final amount = Text(
      MoneyFormatter.format(
        rule.amount.amountMinor,
        localeCode: l10n.locale.languageCode,
      ),
      style: context.texts.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 11.5,
      ),
    );
    final typeLabel = Text(
      rule.type == TransactionType.income
          ? l10n.incomeShort
          : (rule.type == TransactionType.transfer
                ? l10n.transfer
                : l10n.expenseShort),
      style: context.texts.labelSmall?.copyWith(fontSize: 7.5),
    );
    final menu = PopupMenuButton<String>(
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
    );
    final toggle = Switch(value: rule.isActive, onChanged: onToggle);

    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 430;
            final avatar = CategoryAvatar(
              category: category,
              size: 40,
              iconOverride: rule.type == TransactionType.transfer
                  ? Icons.swap_horiz_rounded
                  : null,
            );
            if (compact) {
              return Row(
                children: [
                  avatar,
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleRow,
                        const SizedBox(height: 3),
                        subtitle,
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            amount,
                            const SizedBox(width: 6),
                            typeLabel,
                          ],
                        ),
                      ],
                    ),
                  ),
                  toggle,
                  menu,
                ],
              );
            }
            return Row(
              children: [
                avatar,
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titleRow, const SizedBox(height: 3), subtitle],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [amount, const SizedBox(height: 2), typeLabel],
                ),
                toggle,
                menu,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecurringEditorSheet extends StatefulWidget {
  const _RecurringEditorSheet({this.rule});

  final RecurringRule? rule;

  @override
  State<_RecurringEditorSheet> createState() => _RecurringEditorSheetState();
}

class _RecurringEditorSheetState extends State<_RecurringEditorSheet> {
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
    final wallets = context.read<SettingsDataCubit>().state.wallets;
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
    final state = context.watch<SettingsDataCubit>().state;
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
    final success = await context.read<SettingsDataCubit>().saveRule(rule);
    if (!mounted || !success) return;
    showAppSnackBar(context, l10n.recurringCreated);
    Navigator.of(context).pop();
  }
}
