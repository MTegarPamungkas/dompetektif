import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/features/team/presentation/bloc/team_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WalletTeamSwitcher extends StatelessWidget {
  const WalletTeamSwitcher({super.key, required this.state});

  final TeamState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 9),
            child: Text(
              context.l10n.sharedWallets.toUpperCase(),
              style: context.texts.labelSmall?.copyWith(
                letterSpacing: 1.3,
                fontSize: 8,
              ),
            ),
          ),
          for (final wallet in state.wallets)
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: ChoiceChip(
                avatar: Icon(
                  Icons.groups_2_outlined,
                  size: 15,
                  color: wallet.id == state.selectedWalletId
                      ? context.dompet.accent
                      : context.dompet.inkMuted,
                ),
                label: Text(wallet.name),
                selected: wallet.id == state.selectedWalletId,
                onSelected: (_) =>
                    context.read<TeamBloc>().selectWallet(wallet.id),
              ),
            ),
        ],
      ),
    );
  }
}

class MembersCard extends StatelessWidget {
  const MembersCard({super.key, required this.state});

  final TeamState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final onlineIds = state.onlineUserIds;
    return AppCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.onlineNow,
            title: l10n.members,
            padding: EdgeInsets.zero,
            action: StatusPill(
              label: '${state.members.length}',
              tone: PillTone.neutral,
              compact: true,
            ),
          ),
          const SizedBox(height: 5),
          if (state.members.isEmpty)
            Text(l10n.noMembers, style: context.texts.bodySmall)
          else
            for (final member in state.members)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    MemberAvatar(
                      name: member.displayName,
                      online: onlineIds.contains(member.userId),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.displayName,
                            style: context.texts.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            member.email,
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 8.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      switch (member.role) {
                        WalletRole.owner => l10n.roleOwner,
                        WalletRole.editor => l10n.roleEditor,
                        WalletRole.viewer => l10n.roleViewer,
                      },
                      style: context.texts.labelSmall?.copyWith(fontSize: 7.5),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, required this.online});

  final String name;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: context.dompet.accentSoft,
          child: Text(
            name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: context.dompet.accent,
            ),
          ),
        ),
        Positioned(
          right: -1,
          bottom: -1,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: online ? context.dompet.success : context.dompet.inkMuted,
              shape: BoxShape.circle,
              border: Border.all(color: context.dompet.surface, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class InviteCard extends StatelessWidget {
  const InviteCard({super.key, required this.state, required this.onGenerate});

  final TeamState state;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = state.inviteCode;
    return AppCard(
      accent: context.dompet.accent,
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                size: 18,
                color: context.dompet.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.inviteMember,
                  style: context.texts.titleSmall?.copyWith(fontSize: 13),
                ),
              ),
              StatusPill(
                label: l10n.realtime,
                tone: PillTone.info,
                icon: Icons.bolt_rounded,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n.inviteCodeExpires,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 9.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          if (code != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: context.dompet.background.withValues(alpha: 0.5),
                borderRadius: AppRadius.allMd,
                border: Border.all(
                  color: context.dompet.accent.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      code,
                      style: AppTypography.money(
                        fontSize: 17,
                        color: context.dompet.accent,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.copy,
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (!context.mounted) return;
                      showAppSnackBar(context, l10n.copied);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: state.inviting ? null : onGenerate,
            icon: state.inviting
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.key_rounded, size: 16),
            label: Text(code == null ? l10n.invite : l10n.inviteCode),
          ),
        ],
      ),
    );
  }
}

class NoTeamState extends StatelessWidget {
  const NoTeamState({
    super.key,
    required this.joining,
    required this.onJoin,
    required this.onCreateWallet,
  });

  final bool joining;
  final VoidCallback onJoin;
  final VoidCallback onCreateWallet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PageScroll(
      children: [
        DossierHeader(
          eyebrow: '${l10n.caseFile} / ${l10n.team}',
          title: l10n.team,
          subtitle: l10n.teamSubtitle,
        ),
        const SizedBox(height: 22),
        AppCard(
          padding: const EdgeInsets.all(28),
          child: EmptyState(
            icon: Icons.groups_2_outlined,
            title: l10n.noSharedWallet,
            body: l10n.sharedWalletHint,
            action: Wrap(
              spacing: 9,
              runSpacing: 9,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onCreateWallet,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.createSharedWallet),
                ),
                OutlinedButton.icon(
                  onPressed: joining ? null : onJoin,
                  icon: const Icon(Icons.group_add_outlined, size: 17),
                  label: Text(l10n.joinWithCode),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
