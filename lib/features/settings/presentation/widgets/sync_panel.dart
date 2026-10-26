import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/sync_status.dart';
import 'package:flutter/material.dart';

import 'settings_cards.dart';

class SyncPanel extends StatelessWidget {
  const SyncPanel({super.key, required this.status, required this.onSync});

  final SyncStatus status;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, tone, icon) = switch (status.phase) {
      SyncPhase.demo => (
        l10n.demoMode,
        PillTone.accent,
        Icons.science_outlined,
      ),
      SyncPhase.syncing => (l10n.syncing, PillTone.info, Icons.sync_rounded),
      SyncPhase.offline => (
        l10n.offline,
        PillTone.neutral,
        Icons.cloud_off_outlined,
      ),
      SyncPhase.error => (
        l10n.syncFailed,
        PillTone.evidence,
        Icons.error_outline_rounded,
      ),
      SyncPhase.idle => (
        l10n.cloudMode,
        PillTone.success,
        Icons.cloud_done_outlined,
      ),
    };
    final statusCopy = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingIcon(icon: Icons.sync_rounded),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cloudStatus,
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              StatusPill(label: label, tone: tone, icon: icon, compact: true),
            ],
          ),
        ),
      ],
    );
    final syncButton = OutlinedButton.icon(
      onPressed: status.phase == SyncPhase.demo || status.phase.isBusy
          ? null
          : onSync,
      icon: status.phase.isBusy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded, size: 16),
      label: Text(l10n.syncNow),
    );
    final pending = InfoRow(
      label: l10n.pendingChanges,
      value: status.pendingCount == 0
          ? l10n.noPendingChanges
          : '${status.pendingCount}',
      valueColor: status.pendingCount == 0
          ? context.dompet.success
          : context.dompet.warning,
    );
    final lastSynced = InfoRow(
      label: l10n.lastSynced,
      value: status.lastSyncedAt == null
          ? l10n.neverSynced
          : CaseDates.dateTime(status.lastSyncedAt!, l10n.locale.languageCode),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 430;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (narrow) ...[
                statusCopy,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: syncButton),
              ] else
                Row(
                  children: [
                    Expanded(child: statusCopy),
                    const SizedBox(width: 12),
                    syncButton,
                  ],
                ),
              const SizedBox(height: 10),
              if (constraints.maxWidth < 360)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [pending, const SizedBox(height: 4), lastSynced],
                )
              else
                Row(
                  children: [
                    Expanded(child: pending),
                    const SizedBox(width: 16),
                    Expanded(child: lastSynced),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
