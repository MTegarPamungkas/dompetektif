import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/features/evidence/presentation/cubit/evidence_cubit.dart';
import 'package:dompetektif/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

enum _EvidenceFilter { all, linked, draft, failed }

class EvidencePage extends StatefulWidget {
  const EvidencePage({super.key});

  @override
  State<EvidencePage> createState() => _EvidencePageState();
}

class _EvidencePageState extends State<EvidencePage> {
  _EvidenceFilter _filter = _EvidenceFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.watch<SettingsCubit>().state;
    return BlocListener<EvidenceCubit, EvidenceState>(
      listenWhen: (previous, current) => previous.failure != current.failure,
      listener: (context, state) {
        final failure = state.failure;
        if (failure == null) return;
        showAppSnackBar(context, switch (failure) {
          EvidenceFailure.load => l10n.errorLoadData,
          EvidenceFailure.scan => l10n.errorOcr,
          EvidenceFailure.parse => l10n.errorOcr,
          EvidenceFailure.save => l10n.errorSaveData,
          EvidenceFailure.delete => l10n.errorDeleteData,
        }, error: true);
        context.read<EvidenceCubit>().clearFailure();
      },
      child: BlocBuilder<EvidenceCubit, EvidenceState>(
        builder: (context, state) {
          final receipts = state.receipts.where((receipt) {
            return switch (_filter) {
              _EvidenceFilter.all => true,
              _EvidenceFilter.linked =>
                receipt.status == ReceiptStatus.attached ||
                    receipt.transactionId != null,
              _EvidenceFilter.draft =>
                receipt.status == ReceiptStatus.draft ||
                    receipt.status == ReceiptStatus.parsed,
              _EvidenceFilter.failed => receipt.status == ReceiptStatus.failed,
            };
          }).toList();
          return PageScroll(
            children: [
              DossierHeader(
                eyebrow:
                    '${l10n.caseFile} / ${state.receipts.length} ${l10n.evidenceCount}',
                title: l10n.evidenceVault,
                subtitle: l10n.vaultSubtitle,
                trailing: FilledButton.icon(
                  onPressed: () => context.push('/receipt/scan'),
                  icon: const Icon(Icons.document_scanner_outlined, size: 18),
                  label: Text(l10n.scanReceipt),
                ),
              ),
              const SizedBox(height: 22),
              _EvidenceSummary(
                receipts: state.receipts,
                hidden: settings.hideAmounts,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  ChoiceChip(
                    label: Text(l10n.allEvidence),
                    selected: _filter == _EvidenceFilter.all,
                    onSelected: (_) =>
                        setState(() => _filter = _EvidenceFilter.all),
                  ),
                  ChoiceChip(
                    label: Text(l10n.evidenceLinked),
                    selected: _filter == _EvidenceFilter.linked,
                    onSelected: (_) =>
                        setState(() => _filter = _EvidenceFilter.linked),
                  ),
                  ChoiceChip(
                    label: Text(l10n.draft),
                    selected: _filter == _EvidenceFilter.draft,
                    onSelected: (_) =>
                        setState(() => _filter = _EvidenceFilter.draft),
                  ),
                  ChoiceChip(
                    label: Text(l10n.failed),
                    selected: _filter == _EvidenceFilter.failed,
                    onSelected: (_) =>
                        setState(() => _filter = _EvidenceFilter.failed),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.loading)
                const LoadingState()
              else if (receipts.isEmpty)
                EmptyState(
                  icon: Icons.document_scanner_outlined,
                  title: l10n.noEvidence,
                  body: l10n.noEvidenceBody,
                  action: FilledButton.icon(
                    onPressed: () => context.push('/receipt/scan'),
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    label: Text(l10n.scanNow),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 1020
                        ? 3
                        : (constraints.maxWidth >= 660 ? 2 : 1);
                    return Column(
                      children: [
                        for (
                          var index = 0;
                          index < receipts.length;
                          index += columns
                        )
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var column = 0; column < columns; column++)
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: column < columns - 1 ? 12 : 0,
                                      ),
                                      child: index + column < receipts.length
                                          ? _ReceiptCard(
                                              receipt: receipts[index + column],
                                              hidden: settings.hideAmounts,
                                              onDelete: () => _delete(
                                                receipts[index + column],
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
          );
        },
      ),
    );
  }

  Future<void> _delete(Receipt receipt) async {
    final l10n = context.l10n;
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.deleteReceiptTitle,
      body: l10n.deleteReceiptBody,
      confirmLabel: l10n.confirmDelete,
    );
    if (!confirmed || !mounted) return;
    final success = await context.read<EvidenceCubit>().deleteReceipt(
      receipt.id,
    );
    if (!mounted) return;
    if (success) showAppSnackBar(context, l10n.deleteSuccess);
  }
}

class _EvidenceSummary extends StatelessWidget {
  const _EvidenceSummary({required this.receipts, required this.hidden});

  final List<Receipt> receipts;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = receipts.fold<int>(
      0,
      (sum, receipt) => sum + receipt.total.amountMinor,
    );
    final linked = receipts
        .where((receipt) => receipt.transactionId != null)
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final tiles = [
          MetricTile(
            label: l10n.evidenceCount,
            value: '${receipts.length}',
            icon: Icons.folder_copy_outlined,
            tone: context.dompet.accent,
            compact: compact,
          ),
          MetricTile(
            label: l10n.total,
            value: MoneyFormatter.format(
              total,
              localeCode: l10n.locale.languageCode,
              compact: compact,
              hidden: hidden,
            ),
            icon: Icons.receipt_long_outlined,
            compact: compact,
          ),
          MetricTile(
            label: l10n.evidenceLinked,
            value: '$linked / ${receipts.length}',
            icon: Icons.link_rounded,
            tone: context.dompet.success,
            compact: compact,
          ),
        ];
        if (compact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: tiles[0]),
                  const SizedBox(width: 8),
                  Expanded(child: tiles[1]),
                ],
              ),
              const SizedBox(height: 8),
              tiles[2],
            ],
          );
        }
        return Row(
          children: [
            for (var index = 0; index < tiles.length; index++) ...[
              Expanded(child: tiles[index]),
              if (index < tiles.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.receipt,
    required this.hidden,
    required this.onDelete,
  });

  final Receipt receipt;
  final bool hidden;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (statusLabel, tone) = switch (receipt.status) {
      ReceiptStatus.attached => (l10n.attached, PillTone.success),
      ReceiptStatus.parsed => (l10n.parsed, PillTone.accent),
      ReceiptStatus.draft => (l10n.draft, PillTone.neutral),
      ReceiptStatus.failed => (l10n.failed, PillTone.evidence),
    };
    return AppCard(
      onTap: () => context.push('/receipt/${receipt.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 58,
                decoration: BoxDecoration(
                  color: context.dompet.accentSoft,
                  borderRadius: AppRadius.allSm,
                  border: Border.all(
                    color: context.dompet.accent.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      color: context.dompet.accent,
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      receipt.imageKey == null ? 'TXT' : 'IMG',
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 6.5,
                        color: context.dompet.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.merchant.isEmpty
                          ? l10n.unknownMerchant
                          : receipt.merchant,
                      style: context.texts.titleSmall?.copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      CaseDates.fullDate(
                        receipt.occurredAt,
                        l10n.locale.languageCode,
                      ),
                      style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.delete,
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: context.dompet.inkMuted,
                ),
                onSelected: (_) => onDelete(),
                itemBuilder: (context) => [
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
          const SizedBox(height: 14),
          Row(
            children: [
              StatusPill(label: statusLabel, tone: tone, compact: true),
              const Spacer(),
              MoneyText(
                money: receipt.total,
                hidden: hidden,
                style: context.texts.titleSmall?.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (receipt.items.isNotEmpty)
            Text(
              '${receipt.items.length} ${l10n.items.toLowerCase()}',
              style: context.texts.bodySmall?.copyWith(fontSize: 9),
            )
          else
            Text(
              receipt.rawText.isEmpty ? l10n.noTextDetected : l10n.rawText,
              style: context.texts.bodySmall?.copyWith(fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
