import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/responsive/app_breakpoints.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.medium;
    return DossierHeader(
      eyebrow:
          '${l10n.caseFile} / ${CaseDates.fullDate(DateTime.now(), l10n.locale.languageCode)}',
      title: l10n.welcomeDetective,
      subtitle: l10n.tagline,
      trailing: compact
          ? null
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusPill(
                  label: '${data.recentEntries.length} ${l10n.caseCount}',
                  icon: Icons.description_outlined,
                  tone: PillTone.neutral,
                ),
                StatusPill(
                  label: '${data.recentReceipts.length} ${l10n.evidenceCount}',
                  icon: Icons.folder_copy_outlined,
                  tone: PillTone.accent,
                ),
              ],
            ),
    );
  }
}
