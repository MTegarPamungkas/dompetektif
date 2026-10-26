import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoWalletState extends StatelessWidget {
  const NoWalletState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(30),
      child: EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.createFirstWallet,
        body: l10n.createFirstWalletBody,
        action: FilledButton.icon(
          onPressed: () => context.push('/wallets'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.walletCreate),
        ),
      ),
    );
  }
}
