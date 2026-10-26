import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/wallet_cards.dart';
import '../widgets/wallet_editor_sheet.dart';

class WalletsPage extends StatelessWidget {
  const WalletsPage({super.key});

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
          final balances = {
            for (final item in state.balances) item.wallet.id: item,
          };
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(l10n.wallets),
              actions: [
                IconButton(
                  tooltip: l10n.walletCreate,
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
                      '${l10n.caseFile} / ${state.wallets.length} ${l10n.wallets.toLowerCase()}',
                  title: l10n.wallets,
                  subtitle: l10n.walletsSubtitle,
                  trailing: FilledButton.icon(
                    onPressed: () => _openEditor(context, null),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.walletCreate),
                  ),
                ),
                const SizedBox(height: 22),
                if (state.loading)
                  const LoadingState()
                else if (state.wallets.isEmpty)
                  EmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: l10n.createFirstWallet,
                    body: l10n.createFirstWalletBody,
                    action: FilledButton.icon(
                      onPressed: () => _openEditor(context, null),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.walletCreate),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 860 ? 2 : 1;
                      return Column(
                        children: [
                          for (
                            var index = 0;
                            index < state.wallets.length;
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
                                        child:
                                            index + column <
                                                state.wallets.length
                                            ? WalletCard(
                                                wallet: state
                                                    .wallets[index + column],
                                                balance:
                                                    balances[state
                                                        .wallets[index + column]
                                                        .id],
                                                onEdit: () => _openEditor(
                                                  context,
                                                  state.wallets[index + column],
                                                ),
                                                onDelete: () => _delete(
                                                  context,
                                                  state.wallets[index + column],
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

  Future<void> _delete(BuildContext context, Wallet wallet) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteWalletTitle,
      body: l10n.deleteWalletBody,
      confirmLabel: l10n.confirmDelete,
    );
    if (!confirmed || !context.mounted) return;
    final success = await context.read<SettingsDataBloc>().deleteWallet(
      wallet.id,
    );
    if (!context.mounted) return;
    if (success) showAppSnackBar(context, l10n.deleteSuccess);
  }

  Future<void> _openEditor(BuildContext context, Wallet? wallet) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => BlocProvider.value(
        value: context.read<SettingsDataBloc>(),
        child: WalletEditorSheet(wallet: wallet),
      ),
    );
  }
}
