import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:flutter/material.dart';

class RecurringSummary extends StatelessWidget {
  const RecurringSummary({
    super.key,
    required this.total,
    required this.active,
    required this.next,
    required this.running,
    required this.onRunDue,
  });

  final int total;
  final int active;
  final DateTime? next;
  final bool running;
  final VoidCallback onRunDue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final stats = [
            SummaryStat(
              label: compact ? l10n.total : l10n.recurring,
              value: '$total',
              icon: Icons.event_repeat_rounded,
              color: context.dompet.accent,
            ),
            SummaryStat(
              label: l10n.active,
              value: '$active',
              icon: Icons.play_circle_outline_rounded,
              color: context.dompet.success,
            ),
            SummaryStat(
              label: compact ? l10n.nextRunShort : l10n.nextRun,
              value: next == null
                  ? '—'
                  : CaseDates.dayMonth(next!, l10n.locale.languageCode),
              icon: Icons.schedule_rounded,
              color: context.dompet.info,
            ),
          ];
          final button = FilledButton.tonalIcon(
            onPressed: running ? null : onRunDue,
            icon: running
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(l10n.runDue),
          );
          if (compact) {
            final veryCompact = constraints.maxWidth < 330;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (veryCompact) ...[
                  Row(
                    children: [
                      Expanded(child: stats[0]),
                      const SizedBox(width: 8),
                      Expanded(child: stats[1]),
                    ],
                  ),
                  const SizedBox(height: 8),
                  stats[2],
                ] else
                  Row(
                    children: [
                      for (var index = 0; index < stats.length; index++) ...[
                        Expanded(child: stats[index]),
                        if (index < stats.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                const SizedBox(height: 14),
                button,
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < stats.length; index++) ...[
                Expanded(child: stats[index]),
                if (index < stats.length - 1) const SizedBox(width: 10),
              ],
              const SizedBox(width: 8),
              button,
            ],
          );
        },
      ),
    );
  }
}

class SummaryStat extends StatelessWidget {
  const SummaryStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: context.dompet.surfaceMuted.withValues(alpha: 0.6),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.dompet.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(fontSize: 7),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: context.texts.titleSmall?.copyWith(
                    fontSize: 12.5,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
