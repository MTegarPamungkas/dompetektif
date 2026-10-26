import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/features/ledger/presentation/bloc/ledger_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LedgerSummary extends StatelessWidget {
  const LedgerSummary({super.key, required this.entries, required this.hidden});

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

class FilterPanel extends StatelessWidget {
  const FilterPanel({super.key, required this.state, this.onClearSearch});

  final LedgerState state;
  final VoidCallback? onClearSearch;

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
                    onClearSearch?.call();
                    context.read<LedgerBloc>().clearFilters();
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
                onSelected: (_) => context.read<LedgerBloc>().setType(null),
              ),
              for (final type in TransactionType.values)
                ChoiceChip(
                  label: Text(_typeLabel(l10n, type)),
                  selected: state.filter.type == type,
                  onSelected: (_) => context.read<LedgerBloc>().setType(type),
                ),
              ChoiceChip(
                label: Text(l10n.thisMonth),
                selected: thisMonth,
                onSelected: (selected) {
                  final now = DateTime.now();
                  context.read<LedgerBloc>().setPeriod(
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
                onChanged: (value) => context.read<LedgerBloc>().setWallet(
                  value == null || value.isEmpty ? null : value,
                ),
              );
              final category = AppDropdownField<String>(
                label: l10n.category,
                value: state.filter.categoryId ?? '',
                items: ['', ...categoryLabels.keys],
                labelBuilder: (id) =>
                    id.isEmpty ? l10n.all : (categoryLabels[id] ?? id),
                onChanged: (value) => context.read<LedgerBloc>().setCategory(
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

  String _typeLabel(AppLocalizations l10n, TransactionType type) {
    return switch (type) {
      TransactionType.expense => l10n.expense,
      TransactionType.income => l10n.income,
      TransactionType.transfer => l10n.transfer,
    };
  }
}
