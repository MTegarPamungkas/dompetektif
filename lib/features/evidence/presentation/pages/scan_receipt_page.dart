import 'dart:typed_data';

import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/usecases/wallet_usecases.dart';
import 'package:dompetektif/features/evidence/presentation/cubit/evidence_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _totalController = TextEditingController();
  final _rawTextController = TextEditingController();
  final _textController = TextEditingController();

  Uint8List? _imageBytes;
  OcrResult? _result;
  List<Category> _categories = const [];
  String? _categoryId;
  DateTime _date = DateTime.now();
  List<ReceiptItem> _items = const [];
  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await getIt<GetCategories>()(
        kind: CategoryKind.expense,
      );
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {
      // The form still works without category suggestions.
    }
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _totalController.dispose();
    _rawTextController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scannerSupported = context.read<EvidenceCubit>().isScannerSupported;
    return BlocListener<EvidenceCubit, EvidenceState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppSnackBar(context, switch (failure) {
          EvidenceFailure.load => l10n.errorLoadData,
          EvidenceFailure.scan => l10n.scanFailed,
          EvidenceFailure.parse => l10n.parseFailed,
          EvidenceFailure.save => l10n.errorSaveData,
          EvidenceFailure.delete => l10n.errorDeleteData,
        }, error: true);
        context.read<EvidenceCubit>().clearFailure();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(l10n.receiptScanTitle),
        ),
        body: BlocBuilder<EvidenceCubit, EvidenceState>(
          builder: (context, state) {
            final margin = MediaQuery.sizeOf(context).width < 600 ? 16.0 : 28.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(margin, 18, margin, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DossierHeader(
                        eyebrow: '${l10n.caseFile} / OCR',
                        title: l10n.receiptScanTitle,
                        subtitle: l10n.receiptScanSubtitle,
                        compact: true,
                        trailing: CaseStamp(
                          label: l10n.confidential,
                          subLabel: 'EVIDENCE',
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_result == null) ...[
                        if (scannerSupported)
                          _CaptureCard(
                            busy: state.processing,
                            onCamera: () => _pick(ImageSource.camera),
                            onGallery: () => _pick(ImageSource.gallery),
                          )
                        else
                          AppCard(
                            accent: context.dompet.warning,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: context.dompet.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    l10n.cameraUnavailable,
                                    style: context.texts.bodySmall?.copyWith(
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 14),
                        _PasteTextCard(
                          controller: _textController,
                          busy: state.processing,
                          onAnalyze: _analyzeText,
                        ),
                        if (state.processing) ...[
                          const SizedBox(height: 14),
                          const LoadingState(label: 'Menganalisis…'),
                        ],
                      ] else
                        _buildReview(context, state),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReview(BuildContext context, EvidenceState state) {
    final l10n = context.l10n;
    final result = _result!;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 260),
                color: context.dompet.surfaceMuted,
                child: Image.memory(
                  _imageBytes!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          AppCard(
            accent: context.dompet.accent,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.receiptReview,
                        style: context.texts.headlineSmall?.copyWith(
                          fontSize: 22,
                        ),
                      ),
                    ),
                    StatusPill(
                      label:
                          '${l10n.confidence} ${MoneyFormatter.percent(result.confidence, localeCode: l10n.locale.languageCode)}',
                      tone: result.confidence >= 0.55
                          ? PillTone.success
                          : PillTone.accent,
                      icon: Icons.auto_awesome_rounded,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.receiptReviewHint,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 10,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _merchantController,
                  label: l10n.merchant,
                  hint: l10n.receiptMerchantHint,
                  prefixIcon: const Icon(Icons.storefront_outlined, size: 19),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 13),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 520;
                    final total = AppMoneyField(
                      controller: _totalController,
                      label: l10n.receiptTotalHint,
                      helper: l10n.totalFromReceipt,
                    );
                    final category = AppDropdownField<String>(
                      label: l10n.category,
                      value: _categoryId,
                      items: _categories
                          .map((category) => category.id)
                          .toList(),
                      labelBuilder: (id) {
                        final category = _categories.firstWhere(
                          (category) => category.id == id,
                        );
                        return localizedCategoryName(l10n, category);
                      },
                      prefixIcon: Icons.category_outlined,
                      validator: (value) =>
                          value == null ? l10n.categoryRequired : null,
                      onChanged: (value) => setState(() => _categoryId = value),
                    );
                    if (compact) {
                      return Column(
                        children: [total, const SizedBox(height: 13), category],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: total),
                        const SizedBox(width: 12),
                        Expanded(child: category),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 13),
                AppDateField(
                  label: l10n.receiptDateHint,
                  value: _date,
                  onChanged: (value) => setState(() => _date = value),
                ),
                if (result.suggestedCategoryName != null &&
                    result.suggestedCategoryId != _categoryId) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: context.dompet.accent,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '${l10n.categorySuggestion}: ${result.suggestedCategoryName}',
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 10,
                            color: context.dompet.accent,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(
                          () => _categoryId = result.suggestedCategoryId,
                        ),
                        child: Text(l10n.useSuggestion),
                      ),
                    ],
                  ),
                ],
                if (_items.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  CaseDivider(label: l10n.items),
                  for (final item in _items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: context.texts.bodySmall?.copyWith(
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                          if (item.quantity > 1)
                            Text(
                              '${l10n.itemQuantity} ${item.quantity} · ',
                              style: context.texts.labelSmall?.copyWith(
                                fontSize: 8,
                              ),
                            ),
                          MoneyText(
                            money: item.total,
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: AppRadius.allSm,
                  onTap: () => setState(() => _showRawText = !_showRawText),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          _showRawText
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: context.dompet.inkMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.rawText,
                          style: context.texts.labelMedium?.copyWith(
                            color: context.dompet.inkMuted,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showRawText)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.dompet.surfaceMuted,
                      borderRadius: AppRadius.allSm,
                    ),
                    child: Text(
                      result.rawText,
                      style: context.texts.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 9.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.saving
                            ? null
                            : () => setState(() {
                                _result = null;
                                _imageBytes = null;
                                _items = const [];
                                _merchantController.clear();
                                _totalController.clear();
                                _categoryId = null;
                              }),
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: Text(l10n.scanNow),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: state.saving ? null : _save,
                        icon: state.saving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          state.saving ? l10n.saving : l10n.saveEvidence,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.scanTip,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 10,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2000,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
      final result = await context.read<EvidenceCubit>().scanImage(bytes);
      if (!mounted || result == null) return;
      if (result.rawText.trim().isEmpty) {
        showAppSnackBar(context, context.l10n.noTextDetected, error: true);
        return;
      }
      _applyResult(result);
    } catch (_) {
      if (!mounted) return;
      showAppSnackBar(context, context.l10n.scanFailed, error: true);
    }
  }

  Future<void> _analyzeText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      showAppSnackBar(context, context.l10n.noTextDetected, error: true);
      return;
    }
    final result = await context.read<EvidenceCubit>().analyzeText(text);
    if (!mounted || result == null) return;
    _applyResult(result);
  }

  void _applyResult(OcrResult result) {
    setState(() {
      _result = result;
      _items = result.items;
      _merchantController.text = result.merchant ?? '';
      _totalController.text = result.total == null
          ? ''
          : MoneyFormatter.input(result.total!.amountMinor);
      _rawTextController.text = result.rawText;
      _date = result.occurredAt ?? DateTime.now();
      _categoryId = result.suggestedCategoryId;
    });
    showAppSnackBar(context, context.l10n.receiptTextAnalyzed);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = MoneyFormatter.parse(_totalController.text);
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, context.l10n.invalidAmount, error: true);
      return;
    }
    final l10n = context.l10n;
    final now = DateTime.now();
    final receipt = Receipt(
      id: getIt<Uuid>().v4(),
      ownerId: '',
      merchant: _merchantController.text.trim(),
      total: Money(amount),
      occurredAt: _date,
      rawText: _rawTextController.text,
      items: _items,
      status: ReceiptStatus.parsed,
      createdAt: now,
      updatedAt: now,
    );
    final success = await context.read<EvidenceCubit>().saveReceipt(
      receipt,
      imageBytes: _imageBytes,
    );
    if (!mounted || !success) return;
    showAppSnackBar(context, l10n.savedEvidence);
    context.pop();
  }
}

class _CaptureCard extends StatelessWidget {
  const _CaptureCard({
    required this.busy,
    required this.onCamera,
    required this.onGallery,
  });

  final bool busy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: context.dompet.accentSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.dompet.accent.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              Icons.document_scanner_rounded,
              size: 32,
              color: context.dompet.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.receiptScanTitle,
            style: context.texts.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            l10n.scanHintAndroid,
            style: context.texts.bodySmall?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy ? null : onCamera,
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: Text(l10n.takePhoto),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: Text(l10n.pickFromGallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasteTextCard extends StatelessWidget {
  const _PasteTextCard({
    required this.controller,
    required this.busy,
    required this.onAnalyze,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.content_paste_rounded,
                size: 18,
                color: context.dompet.accent,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.pasteReceipt,
                style: context.texts.titleSmall?.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.pasteReceiptHint,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 10,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 7,
            style: context.texts.bodySmall?.copyWith(
              fontFamily: 'monospace',
              fontSize: 10.5,
              height: 1.5,
            ),
            decoration: InputDecoration(
              hintText: l10n.t(
                'KOPI SENJA\nTotal 45.000\n15/10/2026',
                'SUNSET COFFEE\nTotal 45,000\n10/15/2026',
              ),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonalIcon(
              onPressed: busy ? null : onAnalyze,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 17),
              label: Text(busy ? l10n.analyzing : l10n.analyzeText),
            ),
          ),
        ],
      ),
    );
  }
}
