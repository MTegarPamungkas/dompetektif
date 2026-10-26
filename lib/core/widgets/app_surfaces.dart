import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/responsive/app_breakpoints.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.accent,
    this.background,
    this.borderColor,
    this.radius = AppRadius.lg,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? accent;
  final Color? background;
  final Color? borderColor;
  final Radius radius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: background ?? context.dompet.surface,
        borderRadius: BorderRadius.all(radius),
        border: Border.all(color: borderColor ?? context.dompet.line),
        boxShadow: [
          BoxShadow(
            color: context.dompet.shadow.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.all(radius),
          hoverColor: context.dompet.accentSoft.withValues(alpha: 0.24),
          splashColor: context.dompet.accent.withValues(alpha: 0.08),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (accent == null) return card;
    return Stack(
      children: [
        card,
        Positioned(
          left: 0,
          top: 18,
          bottom: 18,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class DossierHeader extends StatelessWidget {
  const DossierHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.compact = false,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep wide-screen headers on a single line, but move actions below
        // the copy on phones. This avoids cramped titles and horizontal
        // overflows when several action chips are supplied.
        final inlineTrailing = trailing != null && constraints.maxWidth >= 620;
        final eyebrowRow = Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Text(
                eyebrow.toUpperCase(),
                style: context.texts.labelSmall?.copyWith(
                  letterSpacing: 2.2,
                  fontSize: 9.5,
                  color: context.dompet.accent,
                ),
              ),
            ),
            if (inlineTrailing) ...[const SizedBox(width: 18), trailing!],
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            eyebrowRow,
            const SizedBox(height: 10),
            Text(
              title,
              style:
                  (compact
                          ? context.texts.displaySmall
                          : context.texts.displayMedium)
                      ?.copyWith(height: 1.02),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: Text(
                  subtitle!,
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.dompet.inkMuted,
                    height: 1.6,
                  ),
                ),
              ),
            ],
            if (trailing != null && !inlineTrailing) ...[
              const SizedBox(height: 14),
              Align(alignment: Alignment.centerLeft, child: trailing!),
            ],
          ],
        );
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.action,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String title;
  final String? eyebrow;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    style: context.texts.labelSmall?.copyWith(
                      letterSpacing: 1.7,
                      fontSize: 9,
                      color: context.dompet.accent,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(title, style: context.texts.titleLarge),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class CaseStamp extends StatelessWidget {
  const CaseStamp({super.key, required this.label, this.subLabel, this.color});

  final String label;
  final String? subLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? context.dompet.evidence;
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: accent.withValues(alpha: 0.65), width: 1.4),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: context.texts.labelSmall?.copyWith(
                color: accent,
                letterSpacing: 2.4,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                subLabel!,
                style: context.texts.labelSmall?.copyWith(
                  color: accent.withValues(alpha: 0.8),
                  letterSpacing: 1.4,
                  fontSize: 7,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CaseDivider extends StatelessWidget {
  const CaseDivider({
    super.key,
    this.label,
    this.padding = const EdgeInsets.symmetric(vertical: 18),
  });

  final String? label;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (label == null) return Padding(padding: padding, child: const Divider());
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Divider(color: context.dompet.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label!.toUpperCase(),
              style: context.texts.labelSmall?.copyWith(
                letterSpacing: 1.4,
                fontSize: 8.5,
              ),
            ),
          ),
          Expanded(child: Divider(color: context.dompet.line)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: compact ? 22 : 36,
      ),
      decoration: BoxDecoration(
        color: context.dompet.surface.withValues(alpha: 0.65),
        borderRadius: AppRadius.allLg,
        border: Border.all(
          color: context.dompet.line,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 42 : 54,
            height: compact ? 42 : 54,
            decoration: BoxDecoration(
              color: context.dompet.surfaceMuted,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: compact ? 20 : 26,
              color: context.dompet.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.texts.titleMedium,
          ),
          if (body != null) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                body!,
                textAlign: TextAlign.center,
                style: context.texts.bodySmall?.copyWith(height: 1.55),
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.title, this.body, this.onRetry});

  final String? title;
  final String? body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: Icons.report_gmailerrorred_rounded,
      title: title ?? l10n.somethingWrong,
      body: body ?? l10n.tapToRetry,
      action: onRetry == null
          ? null
          : FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l10n.retry),
            ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: context.dompet.accent,
              ),
            ),
            const SizedBox(height: 14),
            Text(label ?? l10n.loading, style: context.texts.bodySmall),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: context.dompet.inkMuted),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: context.texts.bodySmall?.copyWith(
                color: context.dompet.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.texts.bodyMedium?.copyWith(
                color: valueColor ?? context.dompet.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone,
    this.footnote,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? tone;
  final String? footnote;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = tone ?? context.dompet.ink;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 15),
      decoration: BoxDecoration(
        color: context.dompet.surfaceMuted.withValues(alpha: 0.62),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.dompet.line.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: color.withValues(alpha: 0.9)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontSize: 8.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 7 : 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.money(
                fontSize: compact ? 17 : 21,
                color: color,
                letterSpacing: -0.4,
              ),
            ),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 5),
            Text(
              footnote!,
              style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class ContentShell extends StatelessWidget {
  const ContentShell({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final edge = AppBreakpoints.pagePaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: edge),
          child: child,
        ),
      ),
    );
  }
}

class PageScroll extends StatelessWidget {
  const PageScroll({
    super.key,
    required this.children,
    this.top = 26,
    this.bottom = 40,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
  });

  final List<Widget> children;
  final double top;
  final double bottom;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final edge = AppBreakpoints.pagePaddingFor(
      MediaQuery.sizeOf(context).width,
    );
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: SingleChildScrollView(
        primary: true,
        padding: EdgeInsets.fromLTRB(edge, top, edge, bottom),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
