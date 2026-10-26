import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/features/ledger/presentation/cubit/ledger_cubit.dart';
import 'package:dompetektif/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsCubit>().state;
    return BlocListener<LedgerCubit, LedgerState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppSnackBar(context, switch (failure) {
          LedgerFailure.load => l10n.errorLoadData,
          LedgerFailure.save => l10n.errorSaveData,
          LedgerFailure.delete => l10n.errorDeleteData,
        }, error: true);
        context.read<LedgerCubit>().clearFailure();
      },
      child: BlocBuilder<LedgerCubit, LedgerState>(
        builder: (context, state) {
          final entries = state.filteredEntries;
          return PageScroll(
            children: [
              DossierHeader(
                eyebrow:
                    '${l10n.caseFile} / ${entries.length} ${l10n.caseCount}',
                title: l10n.ledger,
                subtitle: l10n.t(
                  'Setiap transaksi adalah barang bukti. Saring berkas untuk menemukan pola yang tidak wajar.',
                  'Every transaction is evidence. Filter the file to surface unusual patterns.',
                ),
                trailing: FilledButton.icon(
                  onPressed: () => context.push('/transaction/new'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.addTransaction),
                ),
              ),
              const SizedBox(height: 22),
              _LedgerSummary(entries: entries, hidden: settings.hideAmounts),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _searchController,
                      onChanged: (value) =>
                          context.read<LedgerCubit>().setQuery(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: l10n.filters,
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    icon: Badge(
                      isLabelVisible: !state.filter.isEmpty,
                      smallSize: 8,
                      child: const Icon(Icons.tune_rounded, size: 20),
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _FilterPanel(state: state),
                ),
                crossFadeState: _showFilters
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 190),
              ),
              const SizedBox(height: 20),
              if (state.loading)
                const LoadingState()
              else if (entries.isEmpty)
                EmptyState(
                  icon: Icons.manage_search_rounded,
                  title: l10n.noTransactions,
                  body: l10n.t(
                    'Mulai catat pengeluaran atau lampirkan struk untuk membangun berkas pertama.',
                    'Record an expense or attach a receipt to build your first case file.',
                  ),
                  action: FilledButton.icon(
                    onPressed: () => context.push('/transaction/new'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.addTransaction),
                  ),
                )
              else
                _GroupedEntries(entries: entries, hidden: settings.hideAmounts),
            ],
          );
        },
      ),
    );
  }
}

class _LedgerSummary extends StatelessWidget {
  const _LedgerSummary({required this.entries, required this.hidden});

  final List<LedgerEntry> entries;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    var income = 0;
    var expense = 0;
    for (final entry in entries) {
      switch (entry.transaction.type) {
        case TransactionType.income:
          income += entry.transaction.amount.amountMinor;
        case TransactionType.expense:
          expense += entry.transaction.amount.amountMinor;
        case TransactionType.transfer:
          break;
      }
    }
    final net = income - expense;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final tiles = [
          MetricTile(
            label: l10n.income,
            value: MoneyFormatter.format(
              income,
              localeCode: l10n.locale.languageCode,
              compact: compact,
              hidden: hidden,
            ),
            icon: Icons.south_west_rounded,
            tone: context.dompet.success,
            compact: compact,
          ),
          MetricTile(
            label: l10n.expense,
            value: MoneyFormatter.format(
              expense,
              localeCode: l10n.locale.languageCode,
              compact: compact,
              hidden: hidden,
            ),
            icon: Icons.north_east_rounded,
            tone: context.dompet.evidence,
            compact: compact,
          ),
          MetricTile(
            label: l10n.net,
            value: MoneyFormatter.format(
              net,
              localeCode: l10n.locale.languageCode,
              compact: compact,
              hidden: hidden,
            ),
            icon: Icons.compare_arrows_rounded,
            tone: net < 0 ? context.dompet.warning : context.dompet.info,
            compact: compact,
          ),
        ];
        if (compact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 8),
                  Expanded(child: tiles[1]),
                ],
              ),
              const SizedBox(height: 8),
              tiles[2],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < tiles.length; index++) ...[
              Expanded(child: tiles[index]),
              if (index < tiles.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({required this.state});

  final LedgerState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final walletLabels = {
      for (final wallet in state.wallets) wallet.id: wallet.name,
    };
    final categoryLabels = {
      for (final category in state.categories)
        category.id: localizedCategoryName(l10n, category),
    };
    final thisMonth =
        state.filter.from != null &&
        state.filter.to != null &&
        CaseDates.sameMonth(state.filter.from!, DateTime.now());
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l10n.filters.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  letterSpacing: 1.5,
                  fontSize: 8.5,
                ),
              ),
              const Spacer(),
              if (!state.filter.isEmpty)
                TextButton(
                  onPressed: () {
                    _searchClear(context);
                    context.read<LedgerCubit>().clearFilters();
                  },
                  child: Text(l10n.clearFilters),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ChoiceChip(
                label: Text(l10n.all),
                selected: state.filter.type == null,
                onSelected: (_) => context.read<LedgerCubit>().setType(null),
              ),
              for (final type in TransactionType.values)
                ChoiceChip(
                  label: Text(_typeLabel(l10n, type)),
                  selected: state.filter.type == type,
                  onSelected: (_) => context.read<LedgerCubit>().setType(type),
                ),
              ChoiceChip(
                label: Text(l10n.thisMonth),
                selected: thisMonth,
                onSelected: (selected) {
                  final now = DateTime.now();
                  context.read<LedgerCubit>().setPeriod(
                    selected ? CaseDates.monthStart(now) : null,
                    selected ? CaseDates.monthEnd(now) : null,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final wallet = AppDropdownField<String>(
                label: l10n.wallet,
                value: state.filter.walletId ?? '',
                items: ['', ...walletLabels.keys],
                labelBuilder: (id) =>
                    id.isEmpty ? l10n.allWallets : (walletLabels[id] ?? id),
                onChanged: (value) => context.read<LedgerCubit>().setWallet(
                  value == null || value.isEmpty ? null : value,
                ),
              );
              final category = AppDropdownField<String>(
                label: l10n.category,
                value: state.filter.categoryId ?? '',
                items: ['', ...categoryLabels.keys],
                labelBuilder: (id) =>
                    id.isEmpty ? l10n.all : (categoryLabels[id] ?? id),
                onChanged: (value) => context.read<LedgerCubit>().setCategory(
                  value == null || value.isEmpty ? null : value,
                ),
              );
              if (compact) {
                return Column(
                  children: [wallet, const SizedBox(height: 10), category],
                );
              }
              return Row(
                children: [
                  Expanded(child: wallet),
                  const SizedBox(width: 10),
                  Expanded(child: category),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _searchClear(BuildContext context) {
    final state = context.findAncestorStateOfType<_LedgerPageState>();
    state?._searchController.clear();
  }

  String _typeLabel(AppLocalizations l10n, TransactionType type) {
    return switch (type) {
      TransactionType.expense => l10n.expense,
      TransactionType.income => l10n.income,
      TransactionType.transfer => l10n.transfer,
    };
  }
}

class _GroupedEntries extends StatelessWidget {
  const _GroupedEntries({required this.entries, required this.hidden});

  final List<LedgerEntry> entries;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final groups = <DateTime, List<LedgerEntry>>{};
    for (final entry in entries) {
      final date = entry.transaction.occurredAt;
      final key = DateTime(date.year, date.month, date.day);
      groups.putIfAbsent(key, () => []).add(entry);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final key in keys) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 0, 7),
              child: Row(
                children: [
                  Text(
                    _dateLabel(context, key),
                    style: context.texts.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontSize: 9,
                      color: context.dompet.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(child: Divider(color: context.dompet.line)),
                  const SizedBox(width: 9),
                  Text(
                    '${groups[key]!.length} ${l10n.caseCount}',
                    style: context.texts.labelSmall?.copyWith(fontSize: 8),
                  ),
                ],
              ),
            ),
            for (final entry in groups[key]!) ...[
              _LedgerRow(entry: entry, hidden: hidden),
              if (entry != groups[key]!.last)
                Divider(color: context.dompet.line.withValues(alpha: 0.55)),
            ],
          ],
        ],
      ),
    );
  }

  String _dateLabel(BuildContext context, DateTime date) {
    final l10n = context.l10n;
    if (CaseDates.isToday(date)) return l10n.today;
    if (CaseDates.isYesterday(date)) return l10n.yesterday;
    return CaseDates.fullDate(date, l10n.locale.languageCode);
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.hidden});

  final LedgerEntry entry;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final transaction = entry.transaction;
    final category = entry.category;
    final categoryName = category == null
        ? (transaction.type == TransactionType.transfer
              ? l10n.transfer
              : l10n.t('Tanpa kategori', 'Uncategorized'))
        : localizedCategoryName(l10n, category);
    final title = transaction.displayTitle.isNotEmpty
        ? transaction.displayTitle
        : categoryName;
    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: () => context.push('/transaction/${transaction.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            CategoryAvatar(
              category: category,
              size: 42,
              iconOverride: transaction.type == TransactionType.transfer
                  ? Icons.swap_horiz_rounded
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      if (transaction.receiptId != null) ...[
                        const SizedBox(width: 5),
                        Icon(
                          Icons.attach_file_rounded,
                          size: 12,
                          color: context.dompet.inkMuted,
                        ),
                      ],
                      if (transaction.isPending) ...[
                        const SizedBox(width: 5),
                        StatusPill(
                          label: l10n.statusPending,
                          tone: PillTone.accent,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      categoryName,
                      entry.wallet.name,
                      if (entry.toWallet != null) entry.toWallet!.name,
                      CaseDates.time(
                        transaction.occurredAt,
                        l10n.locale.languageCode,
                      ),
                    ].join(' · '),
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TransactionAmount(
                  transaction: transaction,
                  hidden: hidden,
                  style: context.texts.bodyMedium?.copyWith(fontSize: 12.5),
                ),
                if (transaction.note.trim().isNotEmpty &&
                    transaction.merchant.trim().isNotEmpty)
                  Text(
                    transaction.note,
                    style: context.texts.bodySmall?.copyWith(fontSize: 8.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            PopupMenuButton<String>(
              tooltip: l10n.edit,
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: context.dompet.inkMuted,
              ),
              onSelected: (value) async {
                if (value == 'edit') {
                  context.push('/transaction/${transaction.id}');
                  return;
                }
                final confirmed = await showConfirmDialog(
                  context,
                  title: l10n.deleteTransactionTitle,
                  body: l10n.deleteTransactionBody,
                  confirmLabel: l10n.confirmDelete,
                );
                if (!confirmed || !context.mounted) return;
                final success = await context
                    .read<LedgerCubit>()
                    .deleteTransaction(transaction.id);
                if (!context.mounted) return;
                if (success) {
                  showAppSnackBar(context, l10n.deleteSuccess);
                }
              },
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
      ),
    );
  }
}
