import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/auth_usecases.dart';
import 'package:dompetektif/features/settings/presentation/cubit/settings_data_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

class WalletsPage extends StatelessWidget {
  const WalletsPage({super.key});

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
                                            ? _WalletCard(
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
    final success = await context.read<SettingsDataCubit>().deleteWallet(
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
        value: context.read<SettingsDataCubit>(),
        child: _WalletEditorSheet(wallet: wallet),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.balance,
    required this.onEdit,
    required this.onDelete,
  });

  final Wallet wallet;
  final WalletBalance? balance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typeLabel = switch (wallet.type) {
      WalletType.cash => l10n.cash,
      WalletType.bank => l10n.bank,
      WalletType.ewallet => l10n.ewallet,
    };
    return AppCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              WalletAvatar(wallet: wallet, size: 44),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            wallet.name,
                            style: context.texts.titleSmall?.copyWith(
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (wallet.isShared) ...[
                          const SizedBox(width: 5),
                          Icon(
                            Icons.groups_2_outlined,
                            size: 13,
                            color: context.dompet.accent,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          typeLabel,
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 9.5,
                          ),
                        ),
                        if (wallet.isShared) ...[
                          const SizedBox(width: 6),
                          StatusPill(
                            label: l10n.shared,
                            tone: PillTone.accent,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.currentBalance.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontSize: 7.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            MoneyFormatter.format(
              balance?.balance.amountMinor ?? wallet.openingBalance.amountMinor,
              localeCode: l10n.locale.languageCode,
            ),
            style: AppTypography.money(
              fontSize: 27,
              color: context.dompet.ink,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniAmount(
                  label: l10n.income,
                  value: balance?.monthIncome.amountMinor ?? 0,
                  color: context.dompet.success,
                ),
              ),
              Container(width: 1, height: 28, color: context.dompet.line),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniAmount(
                  label: l10n.expense,
                  value: balance?.monthExpense.amountMinor ?? 0,
                  color: context.dompet.evidence,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAmount extends StatelessWidget {
  const _MiniAmount({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: context.texts.labelSmall?.copyWith(fontSize: 7),
        ),
        const SizedBox(height: 2),
        Text(
          MoneyFormatter.format(
            value,
            localeCode: l10n.locale.languageCode,
            compact: true,
          ),
          style: context.texts.labelMedium?.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _WalletEditorSheet extends StatefulWidget {
  const _WalletEditorSheet({this.wallet});

  final Wallet? wallet;

  @override
  State<_WalletEditorSheet> createState() => _WalletEditorSheetState();
}

class _WalletEditorSheetState extends State<_WalletEditorSheet> {
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
    final state = context.watch<SettingsDataCubit>().state;
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
    final success = await context.read<SettingsDataCubit>().saveWallet(wallet);
    if (!mounted || !success) return;
    showAppSnackBar(context, l10n.walletCreated);
    Navigator.of(context).pop();
  }
}
