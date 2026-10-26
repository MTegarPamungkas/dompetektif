import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:flutter/material.dart';

class CaptureCard extends StatelessWidget {
  const CaptureCard({
    super.key,
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
            l10n.receiptCaptureTitle,
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

class PasteTextCard extends StatelessWidget {
  const PasteTextCard({
    super.key,
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
