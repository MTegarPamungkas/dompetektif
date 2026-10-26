import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/responsive/app_breakpoints.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/features/ledger/presentation/cubit/transaction_form_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TransactionEditorPage extends StatefulWidget {
  const TransactionEditorPage({super.key, this.transactionId});

  final String? transactionId;

  @override
  State<TransactionEditorPage> createState() => _TransactionEditorPageState();
}

class _TransactionEditorPageState extends State<TransactionEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _walletId;
  String? _toWalletId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  bool _hydrated = false;
  bool _walletInitialized = false;

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
    return BlocListener<TransactionFormCubit, TransactionFormState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          (previous.saving && !current.saving),
      listener: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          showAppSnackBar(context, switch (failure) {
            TransactionFormFailure.load => l10n.errorLoadData,
            TransactionFormFailure.save => l10n.errorSaveData,
            TransactionFormFailure.delete => l10n.errorDeleteData,
          }, error: true);
          context.read<TransactionFormCubit>().clearFailure();
        }
      },
      child: BlocConsumer<TransactionFormCubit, TransactionFormState>(
        listenWhen: (previous, current) =>
            previous.entry != current.entry ||
            previous.wallets.length != current.wallets.length,
        listener: (context, state) => _hydrate(state),
        builder: (context, state) {
          final isEditing = widget.transactionId != null;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? l10n.edit : l10n.addTransaction,
                    style: context.texts.titleLarge,
                  ),
                  Text(
                    l10n.caseFile,
                    style: context.texts.labelSmall?.copyWith(
                      letterSpacing: 1.8,
                      fontSize: 7.5,
                      color: context.dompet.accent,
                    ),
                  ),
                ],
              ),
              actions: [
                if (isEditing)
                  IconButton(
                    tooltip: l10n.delete,
                    onPressed: state.deleting ? null : () => _delete(state),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: context.dompet.evidence,
                    ),
                  ),
                const SizedBox(width: 6),
              ],
            ),
            body: state.loading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, TransactionFormState state) {
    final l10n = context.l10n;
    final entry = state.entry?.transaction;
    final categories = state.categories
        .where(
          (category) => _type == TransactionType.expense
              ? category.kind == CategoryKind.expense
              : category.kind == CategoryKind.income,
        )
        .toList();
    final wallets = state.wallets;
    final margin = AppBreakpoints.pagePaddingFor(
      MediaQuery.sizeOf(context).width,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margin, 20, margin, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entry?.receiptId != null) ...[
                  AppCard(
                    accent: context.dompet.accent,
                    padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_file_rounded,
                          size: 18,
                          color: context.dompet.accent,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            l10n.attachReceipt,
                            style: context.texts.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push('/receipt/${entry!.receiptId}'),
                          child: Text(l10n.openEvidence),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.type.toUpperCase(),
                        style: context.texts.labelSmall?.copyWith(
                          letterSpacing: 1.4,
                          fontSize: 8.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppSegmented<TransactionType>(
                        values: TransactionType.values,
                        selected: _type,
                        expanded: true,
                        labelBuilder: (type) {
                          final narrow = MediaQuery.sizeOf(context).width < 360;
                          return switch (type) {
                            TransactionType.expense =>
                              narrow ? l10n.expenseShort : l10n.expense,
                            TransactionType.income =>
                              narrow ? l10n.incomeShort : l10n.income,
                            TransactionType.transfer => l10n.transfer,
                          };
                        },
                        onChanged: (type) => setState(() {
                          _type = type;
                          _categoryId = null;
                          _toWalletId = null;
                        }),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.amount.toUpperCase(),
                        style: context.texts.labelSmall?.copyWith(
                          letterSpacing: 1.4,
                          fontSize: 8.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: AppTypography.money(
                          fontSize: 34,
                          color: context.dompet.ink,
                          letterSpacing: -1,
                        ),
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          prefixStyle: AppTypography.money(
                            fontSize: 24,
                            color: context.dompet.inkMuted,
                          ),
                          hintText: '0',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                        ),
                        validator: (value) {
                          final parsed = MoneyFormatter.parse(value ?? '');
                          if (parsed == null || parsed <= 0) {
                            return l10n.amountRequired;
                          }
                          return null;
                        },
                      ),
                      Divider(color: context.dompet.line),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 520;
                          final walletField = AppDropdownField<String>(
                            label: l10n.wallet,
                            value: _walletId,
                            items: wallets.map((wallet) => wallet.id).toList(),
                            labelBuilder: (id) => wallets
                                .firstWhere((wallet) => wallet.id == id)
                                .name,
                            prefixIcon: Icons.wallet_outlined,
                            validator: (value) =>
                                value == null ? l10n.walletRequired : null,
                            onChanged: (value) => setState(() {
                              _walletId = value;
                              if (_toWalletId == value) _toWalletId = null;
                            }),
                          );
                          final categoryField = AppDropdownField<String>(
                            label: l10n.category,
                            value: _categoryId,
                            items: categories
                                .map((category) => category.id)
                                .toList(),
                            labelBuilder: (id) => localizedCategoryName(
                              l10n,
                              categories.firstWhere(
                                (category) => category.id == id,
                              ),
                            ),
                            prefixIcon: Icons.category_outlined,
                            validator: (value) =>
                                value == null ? l10n.categoryRequired : null,
                            onChanged: (value) =>
                                setState(() => _categoryId = value),
                          );
                          if (_type == TransactionType.transfer) {
                            final destinationField = AppDropdownField<String>(
                              label: l10n.destinationWallet,
                              value: _toWalletId,
                              items: wallets
                                  .where((wallet) => wallet.id != _walletId)
                                  .map((wallet) => wallet.id)
                                  .toList(),
                              labelBuilder: (id) => wallets
                                  .firstWhere((wallet) => wallet.id == id)
                                  .name,
                              prefixIcon: Icons.arrow_forward_rounded,
                              validator: (value) => value == null
                                  ? l10n.destinationRequired
                                  : null,
                              onChanged: (value) =>
                                  setState(() => _toWalletId = value),
                            );
                            if (compact) {
                              return Column(
                                children: [
                                  walletField,
                                  const SizedBox(height: 10),
                                  destinationField,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: walletField),
                                const SizedBox(width: 10),
                                Expanded(child: destinationField),
                              ],
                            );
                          }
                          if (compact) {
                            return Column(
                              children: [
                                walletField,
                                const SizedBox(height: 10),
                                categoryField,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: walletField),
                              const SizedBox(width: 10),
                              Expanded(child: categoryField),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppDateField(
                        label: l10n.date,
                        value: _date,
                        onChanged: (date) => setState(() => _date = date),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _merchantController,
                        label: l10n.merchant,
                        hint: l10n.t(
                          'Contoh: Kopi Kenangan',
                          'e.g. Blue Bottle Coffee',
                        ),
                        prefixIcon: const Icon(
                          Icons.storefront_outlined,
                          size: 19,
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _noteController,
                        label: l10n.note,
                        hint: l10n.t(
                          'Keterangan tambahan untuk berkas',
                          'Additional context for the case file',
                        ),
                        maxLines: 3,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 44),
                          child: Icon(Icons.notes_rounded, size: 19),
                        ),
                      ),
                    ],
                  ),
                ),
                if (entry != null) ...[
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        InfoRow(
                          label: l10n.createdAtLabel,
                          value: CaseDates.dateTime(
                            entry.createdAt,
                            l10n.locale.languageCode,
                          ),
                        ),
                        InfoRow(
                          label: l10n.updatedAtLabel,
                          value: CaseDates.dateTime(
                            entry.updatedAt,
                            l10n.locale.languageCode,
                          ),
                        ),
                        if (entry.isPending)
                          InfoRow(
                            label: l10n.status,
                            value: l10n.statusPending,
                            valueColor: context.dompet.accent,
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: state.saving
                        ? null
                        : () => _save(context, state),
                    icon: state.saving
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded, size: 19),
                    label: Text(
                      state.saving
                          ? l10n.saving
                          : (widget.transactionId == null
                                ? l10n.saveTransaction
                                : l10n.saveChanges),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hydrate(TransactionFormState state) {
    if (state.loading) return;
    if (!_walletInitialized && state.wallets.isNotEmpty) {
      _walletInitialized = true;
      _walletId = _walletId ?? state.wallets.first.id;
    }
    final entry = state.entry?.transaction;
    if (entry != null && !_hydrated) {
      _hydrated = true;
      _type = entry.type;
      _walletId = entry.walletId;
      _toWalletId = entry.toWalletId;
      _categoryId = entry.categoryId;
      _date = entry.occurredAt;
      _amountController.text = MoneyFormatter.input(entry.amount.amountMinor);
      _merchantController.text = entry.merchant;
      _noteController.text = entry.note;
    }
    if (_categoryId == null &&
        state.categories.isNotEmpty &&
        widget.transactionId == null) {
      final kind = _type == TransactionType.income
          ? CategoryKind.income
          : CategoryKind.expense;
      if (_type != TransactionType.transfer) {
        final matches = state.categories.where(
          (category) => category.kind == kind,
        );
        if (matches.isNotEmpty) _categoryId = matches.first.id;
      }
    }
  }

  Future<void> _save(BuildContext context, TransactionFormState state) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = MoneyFormatter.parse(_amountController.text);
    if (amount == null || amount <= 0 || _walletId == null) return;
    final success = await context.read<TransactionFormCubit>().save(
      type: _type,
      amountMinor: amount,
      walletId: _walletId!,
      toWalletId: _toWalletId,
      categoryId: _categoryId,
      occurredAt: _date,
      note: _noteController.text,
      merchant: _merchantController.text,
    );
    if (!context.mounted || !success) return;
    showAppSnackBar(context, context.l10n.saveTransactionSuccess);
    context.pop();
  }

  Future<void> _delete(TransactionFormState state) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteTransactionTitle,
      body: l10n.deleteTransactionBody,
      confirmLabel: l10n.confirmDelete,
    );
    if (!confirmed || !mounted) return;
    final success = await context.read<TransactionFormCubit>().delete();
    if (!mounted) return;
    if (success) {
      showAppSnackBar(context, l10n.deleteSuccess);
      context.pop();
    }
  }
}
