import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/core/widgets/case_mark.dart';
import 'package:dompetektif/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';

class BrandPanel extends StatelessWidget {
  const BrandPanel({super.key, required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 38, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CaseMark(size: 46),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DOMPETEKTIF',
                    style: context.texts.labelMedium?.copyWith(
                      letterSpacing: 2.4,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    l10n.caseFile,
                    style: context.texts.labelSmall?.copyWith(
                      color: context.dompet.accent,
                      letterSpacing: 3.4,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (state.isDemo)
                StatusPill(
                  label: l10n.demoMode,
                  tone: PillTone.accent,
                  icon: Icons.science_outlined,
                ),
            ],
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.authTitle,
                      style: context.texts.displayLarge?.copyWith(
                        fontSize: 64,
                        height: 0.96,
                        letterSpacing: -1.1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.tagline,
                      style: context.texts.titleMedium?.copyWith(
                        color: context.dompet.accent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Text(
                        l10n.authSubtitle,
                        style: context.texts.bodyLarge?.copyWith(
                          color: context.dompet.inkMuted,
                          height: 1.65,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: CaseStamp(label: l10n.confidential, subLabel: 'PK-2026'),
              ),
            ],
          ),
          const SizedBox(height: 42),
          const FeatureStrip(),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 13,
                color: context.dompet.inkMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  state.isDemo ? l10n.demoNotice : l10n.cloudNotice,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: context.dompet.inkMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompactBrand extends StatelessWidget {
  const CompactBrand({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const CaseMark(size: 40),
            const SizedBox(width: 11),
            Text(
              'DOMPETEKTIF',
              style: context.texts.labelMedium?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            CaseStamp(label: l10n.confidential, subLabel: 'PK-2026'),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          l10n.authTitle,
          style: context.texts.displaySmall?.copyWith(
            fontSize: 40,
            height: 1,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.tagline,
          style: context.texts.titleSmall?.copyWith(
            color: context.dompet.accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.authSubtitle,
          style: context.texts.bodyMedium?.copyWith(
            color: context.dompet.inkMuted,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class FeatureStrip extends StatelessWidget {
  const FeatureStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (Icons.sync_alt_rounded, l10n.syncAuto),
      (Icons.cloud_off_outlined, l10n.offlineFirst),
      (Icons.auto_awesome_outlined, l10n.reportAiSource),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: context.dompet.surface.withValues(alpha: 0.6),
              borderRadius: AppRadius.allPill,
              border: Border.all(color: context.dompet.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, size: 14, color: context.dompet.accent),
                const SizedBox(width: 7),
                Text(
                  item.$2,
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 0.4,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
