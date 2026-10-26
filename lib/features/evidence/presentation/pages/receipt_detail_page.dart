import 'dart:typed_data';

import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/usecases/ledger_usecases.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/receipt_sections.dart';
import '../widgets/convert_sheet.dart';

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
    final hidden = context.watch<SettingsBloc>().state.hideAmounts;
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
                  final summaryCard = ReceiptSummary(
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
                  final itemsCard = ItemsCard(receipt: receipt);
                  final rawCard = RawTextCard(receipt: receipt);
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
          'Buat dompet dan kategori dulu, ya.',
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
      builder: (_) => ConvertSheet(
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
