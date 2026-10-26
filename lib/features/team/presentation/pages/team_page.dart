import 'dart:async';

import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:dompetektif/features/team/presentation/cubit/team_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastNoteCount = 0;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userId = context.watch<AuthCubit>().state.user?.id;
    return BlocListener<TeamCubit, TeamState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          (previous.joining && !current.joining) ||
          (previous.inviting && !current.inviting),
      listener: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          showAppSnackBar(context, switch (failure) {
            TeamFailure.load => l10n.errorLoadData,
            TeamFailure.send => l10n.errorSaveData,
            TeamFailure.invite => l10n.errorInvite,
            TeamFailure.join => l10n.invalidInvite,
          }, error: true);
          context.read<TeamCubit>().clearFailure();
        } else if (!state.joining &&
            !state.inviting &&
            state.inviteCode == null) {
          // Success snackbars are emitted by the actions themselves.
        }
      },
      child: BlocConsumer<TeamCubit, TeamState>(
        listenWhen: (previous, current) =>
            previous.notes.length != current.notes.length,
        listener: (context, state) {
          if (state.notes.length > _lastNoteCount) {
            _lastNoteCount = state.notes.length;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_scrollController.hasClients) return;
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
              );
            });
          }
        },
        builder: (context, state) {
          if (state.wallets.isEmpty && !state.loading) {
            return _NoTeamState(
              joining: state.joining,
              onJoin: _joinDialog,
              onCreateWallet: () => context.push('/wallets'),
            );
          }
          return PageScroll(
            children: [
              DossierHeader(
                eyebrow: '${l10n.caseFile} / ${l10n.realtime}',
                title: l10n.team,
                subtitle: l10n.teamSubtitle,
                trailing: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: state.joining ? null : _joinDialog,
                      icon: const Icon(Icons.group_add_outlined, size: 17),
                      label: Text(l10n.joinWithCode),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.push('/wallets'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(l10n.createSharedWallet),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (state.wallets.isNotEmpty) _WalletTeamSwitcher(state: state),
              const SizedBox(height: 16),
              if (state.loading)
                const LoadingState()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final chat = _ChatCard(
                      notes: state.notes,
                      currentUserId: userId,
                      sending: state.sending,
                      controller: _messageController,
                      scrollController: _scrollController,
                      memberCount: state.members.length,
                      onlineCount: state.online.length,
                      onSend: _send,
                    );
                    final side = Column(
                      children: [
                        _MembersCard(state: state),
                        const SizedBox(height: 14),
                        _InviteCard(state: state, onGenerate: _createInvite),
                      ],
                    );
                    if (!wide) {
                      return Column(
                        children: [
                          SizedBox(height: 470, child: chat),
                          const SizedBox(height: 14),
                          side,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: SizedBox(height: 620, child: chat),
                        ),
                        const SizedBox(width: 16),
                        Expanded(flex: 3, child: side),
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

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;
    final success = await context.read<TeamCubit>().sendNote(body);
    if (!mounted) return;
    if (success) {
      _messageController.clear();
      _lastNoteCount++;
    }
  }

  Future<void> _createInvite() async {
    final code = await context.read<TeamCubit>().createInvite();
    if (!mounted || code == null) return;
    showAppSnackBar(context, context.l10n.inviteCreated);
  }

  Future<void> _joinDialog() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.joinWalletTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.inviteCodeExpires,
              style: context.texts.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: controller,
              label: l10n.inviteCode,
              hint: 'CASE-XXXX',
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
              prefixIcon: const Icon(Icons.key_rounded, size: 19),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.join),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || code == null || code.isEmpty) return;
    final success = await context.read<TeamCubit>().joinWallet(code);
    if (!mounted) return;
    if (success) showAppSnackBar(context, l10n.joinedWallet);
  }
}

class _WalletTeamSwitcher extends StatelessWidget {
  const _WalletTeamSwitcher({required this.state});

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
                    context.read<TeamCubit>().selectWallet(wallet.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({
    required this.notes,
    required this.currentUserId,
    required this.sending,
    required this.controller,
    required this.scrollController,
    required this.memberCount,
    required this.onlineCount,
    required this.onSend,
  });

  final List<CaseNote> notes;
  final String? currentUserId;
  final bool sending;
  final TextEditingController controller;
  final ScrollController scrollController;
  final int memberCount;
  final int onlineCount;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: context.dompet.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.dompet.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.dompet.accentSoft,
                    borderRadius: AppRadius.allMd,
                  ),
                  child: Icon(
                    Icons.forum_outlined,
                    size: 17,
                    color: context.dompet.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.caseNotes,
                        style: context.texts.titleSmall?.copyWith(fontSize: 13),
                      ),
                      Text(
                        l10n.teamChatHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(fontSize: 8.5),
                      ),
                    ],
                  ),
                ),
                StatusPill(
                  label:
                      '$onlineCount/$memberCount ${l10n.online.toLowerCase()}',
                  tone: PillTone.success,
                  icon: Icons.bolt_rounded,
                  compact: true,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.dompet.line),
          Expanded(
            child: notes.isEmpty
                ? EmptyState(
                    icon: Icons.forum_outlined,
                    title: l10n.noNotes,
                    body: l10n.teamChatHint,
                    compact: true,
                  )
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteBubble(
                        note: note,
                        mine: note.userId == currentUserId,
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: context.dompet.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: l10n.message,
                      prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 44,
                  height: 44,
                  child: FilledButton(
                    onPressed: sending ? null : onSend,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBubble extends StatelessWidget {
  const _NoteBubble({required this.note, required this.mine});

  final CaseNote note;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: context.dompet.accentSoft,
              child: Text(
                note.authorName.isEmpty
                    ? '?'
                    : note.authorName.substring(0, 1).toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 9,
                  color: context.dompet.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
              decoration: BoxDecoration(
                color: mine
                    ? context.dompet.accentSoft
                    : context.dompet.surfaceMuted,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(mine ? 14 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 14),
                ),
                border: Border.all(
                  color: mine
                      ? context.dompet.accent.withValues(alpha: 0.24)
                      : context.dompet.line,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!mine)
                    Text(
                      note.authorName,
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 8.5,
                        color: context.dompet.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (!mine) const SizedBox(height: 3),
                  Text(
                    note.body,
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (note.isPending) ...[
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 10,
                          color: context.dompet.inkMuted,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        CaseDates.time(
                          note.createdAt,
                          l10n.locale.languageCode,
                        ),
                        style: context.texts.labelSmall?.copyWith(
                          fontSize: 7.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (mine) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({required this.state});

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
                    _MemberAvatar(
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

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name, required this.online});

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

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.state, required this.onGenerate});

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

class _NoTeamState extends StatelessWidget {
  const _NoTeamState({
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
