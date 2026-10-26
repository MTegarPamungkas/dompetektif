import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:flutter/material.dart';

class ChatCard extends StatelessWidget {
  const ChatCard({
    super.key,
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
                      return NoteBubble(
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

class NoteBubble extends StatelessWidget {
  const NoteBubble({super.key, required this.note, required this.mine});

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
