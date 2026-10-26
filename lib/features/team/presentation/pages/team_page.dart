import 'dart:async';

import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_controls.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dompetektif/features/team/presentation/bloc/team_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/team_widgets.dart';
import '../widgets/chat_card.dart';

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
    final userId = context.watch<AuthBloc>().state.user?.id;
    return BlocListener<TeamBloc, TeamState>(
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
          context.read<TeamBloc>().clearFailure();
        } else if (!state.joining &&
            !state.inviting &&
            state.inviteCode == null) {
          // Success snackbars are emitted by the actions themselves.
        }
      },
      child: BlocConsumer<TeamBloc, TeamState>(
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
            return NoTeamState(
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
              if (state.wallets.isNotEmpty) WalletTeamSwitcher(state: state),
              const SizedBox(height: 16),
              if (state.loading)
                const LoadingState()
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    final chat = ChatCard(
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
                        MembersCard(state: state),
                        const SizedBox(height: 14),
                        InviteCard(state: state, onGenerate: _createInvite),
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
    final success = await context.read<TeamBloc>().sendNote(body);
    if (!mounted) return;
    if (success) {
      _messageController.clear();
      _lastNoteCount++;
    }
  }

  Future<void> _createInvite() async {
    final code = await context.read<TeamBloc>().createInvite();
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
    final success = await context.read<TeamBloc>().joinWallet(code);
    if (!mounted) return;
    if (success) showAppSnackBar(context, l10n.joinedWallet);
  }
}
