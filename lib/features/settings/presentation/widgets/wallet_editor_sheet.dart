import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

const _walletPalette = [
  '#E8B84B',
  '#6FB7A8',
  '#E0705C',
  '#7C9CF5',
  '#C98BDB',
  '#8FBF6F',
  '#E2A03F',
  '#5BA7C9',
];

class WalletEditorSheet extends StatefulWidget {
  const WalletEditorSheet({super.key, this.wallet});

  final Wallet? wallet;

  @override
  State<WalletEditorSheet> createState() => WalletEditorSheetState();
}

class WalletEditorSheetState extends State<WalletEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  WalletType _type = WalletType.cash;
  bool _shared = false;
  String _color = _walletPalette.first;

  @override
  void initState() {
    super.initState();
    final wallet = widget.wallet;
    _nameController = TextEditingController(text: wallet?.name ?? '');
    _balanceController = TextEditingController(
      text: wallet == null
          ? ''
          : MoneyFormatter.input(wallet.openingBalance.amountMinor),
    );
    _type = wallet?.type ?? WalletType.cash;
    _shared = wallet?.isShared ?? false;
    _color = wallet?.colorHex ?? _walletPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<SettingsDataBloc>().state;
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.wallet == null ? l10n.walletCreate : l10n.walletEdit,
                  style: context.texts.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(l10n.walletsSubtitle, style: context.texts.bodySmall),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _nameController,
                  label: l10n.walletName,
                  hint: l10n.t('Contoh: Dompet Harian', 'e.g. Daily wallet'),
                  prefixIcon: const Icon(Icons.wallet_outlined, size: 19),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? l10n.nameRequired : null,
                ),
                const SizedBox(height: 13),
                AppMoneyField(
                  controller: _balanceController,
                  label: l10n.openingBalance,
                  helper: l10n.t(
                    'Saldo awal saat dompet mulai dipakai.',
                    'Starting balance when this wallet goes live.',
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  l10n.walletType.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 1.3,
                    fontSize: 8.5,
                  ),
                ),
                const SizedBox(height: 8),
                AppSegmented<WalletType>(
                  values: WalletType.values,
                  selected: _type,
                  expanded: true,
                  labelBuilder: (type) => switch (type) {
                    WalletType.cash => l10n.cash,
                    WalletType.bank => l10n.bank,
                    WalletType.ewallet => l10n.ewallet,
                  },
                  onChanged: (type) => setState(() => _type = type),
                ),
                const SizedBox(height: 15),
                Text(
                  l10n.chooseColor.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 1.3,
                    fontSize: 8.5,
                  ),
                ),
                const SizedBox(height: 8),
                AppColorPicker(
                  colors: _walletPalette,
                  selected: _color,
                  onChanged: (color) => setState(() => _color = color),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                  value: _shared,
                  onChanged: (value) => setState(() => _shared = value),
                  title: Text(
                    l10n.sharedWallet,
                    style: context.texts.bodyMedium?.copyWith(fontSize: 12),
                  ),
                  subtitle: Text(
                    l10n.sharedWalletSubtitle,
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                  ),
                ),
                const SizedBox(height: 18),
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
    final l10n = context.l10n;
    final opening = MoneyFormatter.parse(_balanceController.text) ?? 0;
    final current = widget.wallet;
    final now = DateTime.now();
    final wallet = Wallet(
      id: current?.id ?? getIt<Uuid>().v4(),
      ownerId: current?.ownerId ?? getIt<GetCurrentUser>()()?.id ?? '',
      name: _nameController.text.trim(),
      type: _type,
      openingBalance: Money(opening),
      colorHex: _color,
      iconKey: _type.name,
      isShared: _shared,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );
    final success = await context.read<SettingsDataBloc>().saveWallet(wallet);
    if (!mounted || !success) return;
    showAppSnackBar(context, l10n.walletCreated);
    Navigator.of(context).pop();
  }
}
