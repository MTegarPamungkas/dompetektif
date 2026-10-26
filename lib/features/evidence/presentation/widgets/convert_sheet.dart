import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:flutter/material.dart';

class ConvertSheet extends StatefulWidget {
  const ConvertSheet({
    super.key,
    required this.receipt,
    required this.wallets,
    required this.categories,
  });

  final Receipt receipt;
  final List<Wallet> wallets;
  final List<Category> categories;

  @override
  State<ConvertSheet> createState() => ConvertSheetState();
}

class ConvertSheetState extends State<ConvertSheet> {
  String? _walletId;
  String? _categoryId;
  late final TextEditingController _amountController;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _walletId = widget.wallets.first.id;
    _categoryId = widget.categories.first.id;
    _date = widget.receipt.occurredAt;
    _amountController = TextEditingController(
      text: MoneyFormatter.input(widget.receipt.total.amountMinor),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.createTransactionFromReceipt,
              style: context.texts.headlineSmall,
            ),
            const SizedBox(height: 5),
            Text(
              l10n.transactionFromReceiptHint,
              style: context.texts.bodySmall?.copyWith(height: 1.45),
            ),
            const SizedBox(height: 16),
            AppMoneyField(controller: _amountController, label: l10n.amount),
            const SizedBox(height: 12),
            AppDropdownField<String>(
              label: l10n.wallet,
              value: _walletId,
              items: widget.wallets.map((wallet) => wallet.id).toList(),
              labelBuilder: (id) =>
                  widget.wallets.firstWhere((wallet) => wallet.id == id).name,
              prefixIcon: Icons.wallet_outlined,
              onChanged: (value) => setState(() => _walletId = value),
            ),
            const SizedBox(height: 12),
            AppDropdownField<String>(
              label: l10n.category,
              value: _categoryId,
              items: widget.categories.map((category) => category.id).toList(),
              labelBuilder: (id) => localizedCategoryName(
                l10n,
                widget.categories.firstWhere((category) => category.id == id),
              ),
              prefixIcon: Icons.category_outlined,
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 12),
            AppDateField(
              label: l10n.date,
              value: _date,
              onChanged: (value) => setState(() => _date = value),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_saving ? l10n.saving : l10n.create),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = MoneyFormatter.parse(_amountController.text);
    if (amount == null ||
        amount <= 0 ||
        _walletId == null ||
        _categoryId == null) {
      showAppSnackBar(context, context.l10n.invalidAmount, error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final transaction = await getIt<CreateTransactionFromReceipt>()(
        receipt: widget.receipt,
        walletId: _walletId!,
        amountMinor: amount,
        categoryId: _categoryId!,
        occurredAt: _date,
      );
      if (!mounted) return;
      Navigator.of(context).pop(transaction.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, context.l10n.errorSaveData, error: true);
    }
  }
}
