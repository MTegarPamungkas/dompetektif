import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/iterable_x.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/recurring_summary.dart';
import '../widgets/recurring_row.dart';
import '../widgets/recurring_editor_sheet.dart';

class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<SettingsDataBloc, SettingsDataState>(
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
        context.read<SettingsDataBloc>().clearFailure();
      },
      child: BlocBuilder<SettingsDataBloc, SettingsDataState>(
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
                RecurringSummary(
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
                          RecurringRow(
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
    final count = await context.read<SettingsDataBloc>().runDueRecurring();
    if (!context.mounted) return;
    if (count == null) return;
    showAppSnackBar(context, count == 0 ? l10n.noDue : l10n.dueCompleted);
  }

  Future<void> _toggle(
    BuildContext context,
    RecurringRule rule,
    bool active,
  ) async {
    final success = await context.read<SettingsDataBloc>().saveRule(
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
    final success = await context.read<SettingsDataBloc>().deleteRule(rule.id);
    if (!context.mounted) return;
    if (success) showAppSnackBar(context, l10n.deleteSuccess);
  }

  Future<void> _openEditor(BuildContext context, RecurringRule? rule) async {
    if (context.read<SettingsDataBloc>().state.wallets.isEmpty) {
      showAppSnackBar(context, context.l10n.createFirstWalletBody, error: true);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 660),
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsDataBloc>(),
        child: RecurringEditorSheet(rule: rule),
      ),
    );
  }
}
