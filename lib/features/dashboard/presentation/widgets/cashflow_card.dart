import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:flutter/material.dart';

class CashflowCard extends StatelessWidget {
  const CashflowCard({super.key, required this.data});

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
            eyebrow: l10n.analysis,
            title: l10n.cashflow,
            padding: EdgeInsets.zero,
            action: StatusPill(
              label: l10n.lastMonth,
              icon: Icons.timeline_rounded,
              compact: true,
            ),
          ),
          const SizedBox(height: 18),
          CashflowBars(points: data.cashflow),
        ],
      ),
    );
  }
}
