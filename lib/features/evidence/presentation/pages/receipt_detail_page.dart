import 'dart:typed_data';

import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:dompetektif/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ReceiptDetailPage extends StatefulWidget {
  const ReceiptDetailPage({super.key, required this.receiptId});

  final String receiptId;

  @override
  State<ReceiptDetailPage> createState() => _ReceiptDetailPageState();
}

class _ReceiptDetailPageState extends State<ReceiptDetailPage> {
  Receipt? _receipt;
  Uint8List? _imageBytes;
  List<Wallet> _wallets = const [];
  List<Category> _categories = const [];
  bool _loading = true;
  bool _notFound = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final receipt = await getIt<GetReceipt>()(widget.receiptId);
      final wallets = await getIt<GetWallets>()();
      final categories = await getIt<GetCategories>()(
        kind: CategoryKind.expense,
      );
      Uint8List? image;
      if (receipt != null) {
        image = await getIt<LoadReceiptImage>()(receipt.id);
      }
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _imageBytes = image;
        _wallets = wallets;
        _categories = categories;
        _loading = false;
        _notFound = receipt == null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notFound = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hidden = context.watch<SettingsCubit>().state.hideAmounts;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.openEvidence),
        actions: [
          if (_receipt != null)
            IconButton(
              tooltip: l10n.delete,
              onPressed: _deleting ? null : _delete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: context.dompet.evidence,
              ),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notFound || _receipt == null
          ? PageScroll(
              children: [
                ErrorState(
                  title: l10n.receiptNotFound,
                  body: l10n.tapToRetry,
                  onRetry: _load,
                ),
              ],
            )
          : _buildDetail(context, _receipt!, hidden),
    );
  }

  Widget _buildDetail(BuildContext context, Receipt receipt, bool hidden) {
    final l10n = context.l10n;
    final margin = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 28.0;
    final imageUrl = receipt.remoteImageUrl;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(margin, 18, margin, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.evidence.toUpperCase(),
                          style: context.texts.labelSmall?.copyWith(
                            letterSpacing: 2,
                            fontSize: 8.5,
                            color: context.dompet.accent,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          receipt.merchant.isEmpty
                              ? l10n.unknownMerchant
                              : receipt.merchant,
                          style: context.texts.displaySmall?.copyWith(
                            fontSize: 34,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CaseDates.fullDate(
                            receipt.occurredAt,
                            l10n.locale.languageCode,
                          ),
                          style: context.texts.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CaseStamp(label: l10n.confidential, subLabel: 'EVIDENCE'),
                ],
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  final imageCard = AppCard(
                    padding: const EdgeInsets.all(12),
                    child: _imageBytes == null && imageUrl == null
                        ? Container(
                            height: compact ? 200 : 300,
                            decoration: BoxDecoration(
                              color: context.dompet.surfaceMuted,
                              borderRadius: AppRadius.allMd,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 34,
                                  color: context.dompet.inkMuted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.localImageUnavailable,
                                  style: context.texts.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _openImage(context, imageUrl),
                            child: ClipRRect(
                              borderRadius: AppRadius.allMd,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: compact ? 260 : 360,
                                ),
                                child: _imageBytes != null
                                    ? Image.memory(
                                        _imageBytes!,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          height: 220,
                                          color: context.dompet.surfaceMuted,
                                          alignment: Alignment.center,
                                          child: Text(
                                            l10n.localImageUnavailable,
                                            style: context.texts.bodySmall,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                  );
                  final summaryCard = _ReceiptSummary(
                    receipt: receipt,
                    hidden: hidden,
                    onConvert: receipt.transactionId == null ? _convert : null,
                    onOpenTransaction: receipt.transactionId == null
                        ? null
                        : () => context.push(
                            '/transaction/${receipt.transactionId}',
                          ),
                  );
                  if (compact) {
                    return Column(
                      children: [
                        imageCard,
                        const SizedBox(height: 14),
                        summaryCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: imageCard),
                      const SizedBox(width: 14),
                      Expanded(flex: 4, child: summaryCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 720;
                  final itemsCard = _ItemsCard(receipt: receipt);
                  final rawCard = _RawTextCard(receipt: receipt);
                  if (compact) {
                    return Column(
                      children: [
                        itemsCard,
                        const SizedBox(height: 14),
                        rawCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: itemsCard),
                      const SizedBox(width: 14),
                      Expanded(child: rawCard),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteReceiptTitle,
      body: l10n.deleteReceiptBody,
      confirmLabel: l10n.confirmDelete,
    );
    if (!confirmed || !mounted) return;
    setState(() => _deleting = true);
    try {
      await getIt<DeleteReceipt>()(widget.receiptId);
      if (!mounted) return;
      showAppSnackBar(context, l10n.deleteSuccess);
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showAppSnackBar(context, l10n.errorDeleteData, error: true);
    }
  }

  Future<void> _convert() async {
    final receipt = _receipt;
    if (receipt == null || _wallets.isEmpty || _categories.isEmpty) {
      showAppSnackBar(
        context,
        context.l10n.t(
          'Buat dompet dan kategori terlebih dahulu.',
          'Create a wallet and category first.',
        ),
        error: true,
      );
      return;
    }
    final transactionId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (_) => _ConvertSheet(
        receipt: receipt,
        wallets: _wallets,
        categories: _categories,
      ),
    );
    if (!mounted || transactionId == null) return;
    await _load();
    if (!mounted) return;
    showAppSnackBar(context, context.l10n.transactionSaved);
    context.push('/transaction/$transactionId');
  }

  Future<void> _openImage(BuildContext context, String? url) async {
    if (_imageBytes == null && url == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: _imageBytes != null
                ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                : Image.network(url!, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _ReceiptSummary extends StatelessWidget {
  const _ReceiptSummary({
    required this.receipt,
    required this.hidden,
    required this.onConvert,
    required this.onOpenTransaction,
  });

  final Receipt receipt;
  final bool hidden;
  final VoidCallback? onConvert;
  final VoidCallback? onOpenTransaction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, tone) = switch (receipt.status) {
      ReceiptStatus.attached => (l10n.attached, PillTone.success),
      ReceiptStatus.parsed => (l10n.parsed, PillTone.accent),
      ReceiptStatus.draft => (l10n.draft, PillTone.neutral),
      ReceiptStatus.failed => (l10n.failed, PillTone.evidence),
    };
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusPill(label: label, tone: tone, compact: true),
              const Spacer(),
              if (receipt.imageKey == null)
                StatusPill(
                  label: l10n.noImage,
                  tone: PillTone.neutral,
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.total.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              letterSpacing: 1.3,
              fontSize: 8.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            MoneyFormatter.format(
              receipt.total.amountMinor,
              localeCode: l10n.locale.languageCode,
              hidden: hidden,
            ),
            style: AppTypography.money(
              fontSize: 30,
              color: context.dompet.ink,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          InfoRow(
            label: l10n.merchant,
            value: receipt.merchant.isEmpty
                ? l10n.unknownMerchant
                : receipt.merchant,
          ),
          InfoRow(
            label: l10n.date,
            value: CaseDates.fullDate(
              receipt.occurredAt,
              l10n.locale.languageCode,
            ),
          ),
          InfoRow(
            label: l10n.generatedAt,
            value: CaseDates.dateTime(
              receipt.updatedAt,
              l10n.locale.languageCode,
            ),
          ),
          InfoRow(
            label: l10n.status,
            value: receipt.transactionId == null
                ? l10n.receiptDraft
                : l10n.receiptAttached,
            valueColor: receipt.transactionId == null
                ? context.dompet.inkMuted
                : context.dompet.success,
          ),
          const SizedBox(height: 14),
          if (onOpenTransaction != null)
            FilledButton.tonalIcon(
              onPressed: onOpenTransaction,
              icon: const Icon(Icons.receipt_long_outlined, size: 17),
              label: Text(l10n.openTransaction),
            )
          else
            FilledButton.icon(
              onPressed: onConvert,
              icon: const Icon(Icons.add_link_rounded, size: 17),
              label: Text(l10n.createTransactionFromReceipt),
            ),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.items,
            eyebrow: l10n.details,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          if (receipt.items.isEmpty)
            Text(l10n.noItems, style: context.texts.bodySmall)
          else
            for (final item in receipt.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: context.texts.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ),
                    if (item.quantity > 1)
                      Text(
                        '${l10n.itemQuantity} ${item.quantity} · ',
                        style: context.texts.labelSmall?.copyWith(fontSize: 8),
                      ),
                    MoneyText(
                      money: item.total,
                      style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _RawTextCard extends StatelessWidget {
  const _RawTextCard({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: l10n.rawText,
            eyebrow: l10n.analysis,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.dompet.surfaceMuted,
              borderRadius: AppRadius.allSm,
            ),
            child: Text(
              receipt.rawText.isEmpty ? l10n.noTextDetected : receipt.rawText,
              style: context.texts.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontSize: 9.5,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConvertSheet extends StatefulWidget {
  const _ConvertSheet({
    required this.receipt,
    required this.wallets,
    required this.categories,
  });

  final Receipt receipt;
  final List<Wallet> wallets;
  final List<Category> categories;

  @override
  State<_ConvertSheet> createState() => _ConvertSheetState();
}

class _ConvertSheetState extends State<_ConvertSheet> {
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
