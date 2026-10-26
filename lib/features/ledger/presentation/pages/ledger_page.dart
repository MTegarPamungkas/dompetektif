import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/features/ledger/presentation/bloc/ledger_bloc.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/ledger_sections.dart';
import '../widgets/ledger_list.dart';

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
    final settings = context.watch<SettingsBloc>().state;
    return BlocListener<LedgerBloc, LedgerState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppSnackBar(context, switch (failure) {
          LedgerFailure.load => l10n.errorLoadData,
          LedgerFailure.save => l10n.errorSaveData,
          LedgerFailure.delete => l10n.errorDeleteData,
        }, error: true);
        context.read<LedgerBloc>().clearFailure();
      },
      child: BlocBuilder<LedgerBloc, LedgerState>(
        builder: (context, state) {
          final entries = state.filteredEntries;
          return PageScroll(
            children: [
              DossierHeader(
                eyebrow:
                    '${l10n.caseFile} / ${entries.length} ${l10n.caseCount}',
                title: l10n.ledger,
                subtitle: l10n.t(
                  'Setiap transaksi adalah barang bukti. Filter catatanmu untuk menemukan pola yang janggal.',
                  'Every transaction is evidence. Filter your records to surface unusual patterns.',
                ),
                trailing: FilledButton.icon(
                  onPressed: () => context.push('/transaction/new'),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.addTransaction),
                ),
              ),
              const SizedBox(height: 22),
              LedgerSummary(entries: entries, hidden: settings.hideAmounts),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppSearchField(
                      controller: _searchController,
                      onChanged: (value) =>
                          context.read<LedgerBloc>().setQuery(value),
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
                  child: FilterPanel(
                    state: state,
                    onClearSearch: _searchController.clear,
                  ),
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
                    'Catat pengeluaran pertamamu atau lampirkan struk untuk mulai membangun berkas.',
                    'Record your first expense or attach a receipt to start your case file.',
                  ),
                  action: FilledButton.icon(
                    onPressed: () => context.push('/transaction/new'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.addTransaction),
                  ),
                )
              else
                GroupedEntries(entries: entries, hidden: settings.hideAmounts),
            ],
          );
        },
      ),
    );
  }
}
