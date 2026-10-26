import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeamActivityCard extends StatelessWidget {
  const TeamActivityCard({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.realtime,
            title: l10n.teamActivity,
            padding: EdgeInsets.zero,
            action: IconButton(
              tooltip: l10n.team,
              onPressed: () => context.go('/team'),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          if (data.teamActivity.isEmpty)
            EmptyState(
              icon: Icons.forum_outlined,
              title: l10n.noNotes,
              compact: true,
            )
          else
            for (final note in data.teamActivity.take(4))
              NotePreview(note: note),
        ],
      ),
    );
  }
}

class NotePreview extends StatelessWidget {
  const NotePreview({super.key, required this.note});

  final CaseNote note;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: context.dompet.accentSoft,
            child: Text(
              note.initials,
              style: context.texts.labelSmall?.copyWith(
                color: context.dompet.accent,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.authorName,
                        style: context.texts.labelSmall?.copyWith(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      CaseDates.time(note.createdAt, l10n.locale.languageCode),
                      style: context.texts.labelSmall?.copyWith(fontSize: 8),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  note.body,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 10.5,
                    height: 1.4,
                  ),
                  maxLines: 2,
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
