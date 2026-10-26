import 'dart:math' as math;

import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:flutter/material.dart';

Color colorFromHex(String hex, {Color fallback = const Color(0xFFE8B84B)}) {
  final normalized = hex.replaceAll('#', '').trim();
  if (normalized.length != 6 && normalized.length != 8) return fallback;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return fallback;
  return Color(normalized.length == 6 ? 0xFF000000 | value : value);
}

IconData categoryIcon(String key) {
  return switch (key) {
    'restaurant' => Icons.restaurant_rounded,
    'transport' => Icons.directions_car_rounded,
    'shopping' => Icons.shopping_bag_rounded,
    'receipt' => Icons.receipt_long_rounded,
    'health' => Icons.favorite_rounded,
    'entertainment' => Icons.movie_rounded,
    'salary' => Icons.account_balance_wallet_rounded,
    'briefcase' => Icons.work_rounded,
    'income' => Icons.savings_rounded,
    'dots' => Icons.more_horiz_rounded,
    _ => Icons.category_rounded,
  };
}

IconData walletIcon(String key) {
  return switch (key) {
    'bank' => Icons.account_balance_rounded,
    'phone' => Icons.phone_android_rounded,
    'team' => Icons.groups_rounded,
    _ => Icons.wallet_rounded,
  };
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.category,
    this.size = 42,
    this.iconOverride,
  });

  final Category? category;
  final double size;
  final IconData? iconOverride;

  @override
  Widget build(BuildContext context) {
    final color = category == null
        ? context.dompet.inkMuted
        : colorFromHex(category!.colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.13,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Icon(
        iconOverride ?? categoryIcon(category?.iconKey ?? 'category'),
        color: color,
        size: size * 0.47,
      ),
    );
  }
}

class WalletAvatar extends StatelessWidget {
  const WalletAvatar({super.key, required this.wallet, this.size = 42});

  final Wallet wallet;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(wallet.colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(
        wallet.isShared ? Icons.groups_rounded : walletIcon(wallet.iconKey),
        color: color,
        size: size * 0.47,
      ),
    );
  }
}

class AmountText extends StatelessWidget {
  const AmountText({
    super.key,
    required this.amount,
    this.signed = false,
    this.compact = false,
    this.hidden = false,
    this.style,
    this.positiveColor,
    this.negativeColor,
    this.color,
  });

  final int amount;
  final bool signed;
  final bool compact;
  final bool hidden;
  final TextStyle? style;
  final Color? positiveColor;
  final Color? negativeColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final effective =
        color ??
        (amount < 0
            ? (negativeColor ?? context.dompet.evidence)
            : (amount > 0 && signed
                  ? (positiveColor ?? context.dompet.success)
                  : context.dompet.ink));
    return Text(
      MoneyFormatter.format(
        amount,
        localeCode: l10n.locale.languageCode,
        signed: signed,
        compact: compact,
        hidden: hidden,
      ),
      style: (style ?? context.texts.titleMedium)?.copyWith(
        color: effective,
        fontWeight: FontWeight.w700,
        fontFeatures: AppTypography.tabular,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class MoneyText extends StatelessWidget {
  const MoneyText({
    super.key,
    required this.money,
    this.signed = false,
    this.compact = false,
    this.hidden = false,
    this.style,
    this.color,
  });

  final Money money;
  final bool signed;
  final bool compact;
  final bool hidden;
  final TextStyle? style;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Text(
      MoneyFormatter.format(
        money.amountMinor,
        currency: money.currency,
        localeCode: l10n.locale.languageCode,
        signed: signed,
        compact: compact,
        hidden: hidden,
      ),
      style: (style ?? context.texts.titleMedium)?.copyWith(
        color: color ?? context.dompet.ink,
        fontWeight: FontWeight.w700,
        fontFeatures: AppTypography.tabular,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

enum PillTone { neutral, accent, evidence, success, info }

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
    this.compact = false,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (tone) {
      PillTone.accent => (context.dompet.accent, context.dompet.accentSoft),
      PillTone.evidence => (
        context.dompet.evidence,
        context.dompet.evidenceSoft,
      ),
      PillTone.success => (context.dompet.success, context.dompet.successSoft),
      PillTone.info => (
        context.dompet.info,
        context.dompet.info.withValues(alpha: 0.14),
      ),
      PillTone.neutral => (
        context.dompet.inkMuted,
        context.dompet.surfaceMuted,
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.allPill,
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 11 : 13, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              color: foreground,
              letterSpacing: 0.25,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionAmount extends StatelessWidget {
  const TransactionAmount({
    super.key,
    required this.transaction,
    this.hidden = false,
    this.style,
  });

  final Transaction transaction;
  final bool hidden;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final amount = transaction.amount.amountMinor;
    final signed = transaction.type == TransactionType.income
        ? amount
        : (transaction.type == TransactionType.expense ? -amount : amount);
    final color = switch (transaction.type) {
      TransactionType.income => context.dompet.success,
      TransactionType.expense => context.dompet.ink,
      TransactionType.transfer => context.dompet.info,
    };
    return AmountText(
      amount: signed,
      hidden: hidden,
      style: style,
      color: color,
    );
  }
}

class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    super.key,
    required this.ratio,
    this.height = 7,
    this.color,
  });

  final double ratio;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final clamped = ratio.clamp(0.0, 1.0);
    final effective =
        color ??
        (ratio >= 1
            ? context.dompet.evidence
            : (ratio >= 0.8 ? context.dompet.warning : context.dompet.success));
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: height,
        backgroundColor: context.dompet.surfaceMuted,
        valueColor: AlwaysStoppedAnimation(effective),
      ),
    );
  }
}

class CashflowBars extends StatelessWidget {
  const CashflowBars({
    super.key,
    required this.points,
    this.height = 150,
    this.showLegend = true,
  });

  final List<CashflowPoint> points;
  final double height;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text(l10n.noData, style: context.texts.bodySmall)),
      );
    }

    final maxValue = points.fold<int>(
      1,
      (max, point) => math.max(
        max,
        math.max(point.income.amountMinor, point.expense.amountMinor),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLegend) ...[
          Row(
            children: [
              _LegendDot(color: context.dompet.success, label: l10n.income),
              const SizedBox(width: 14),
              _LegendDot(color: context.dompet.evidence, label: l10n.expense),
            ],
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < points.length; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _Bar(
                                  ratio:
                                      points[index].income.amountMinor /
                                      maxValue,
                                  color: context.dompet.success,
                                  tooltip: MoneyFormatter.format(
                                    points[index].income.amountMinor,
                                    localeCode: l10n.locale.languageCode,
                                    compact: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: _Bar(
                                  ratio:
                                      points[index].expense.amountMinor /
                                      maxValue,
                                  color: context.dompet.evidence,
                                  tooltip: MoneyFormatter.format(
                                    points[index].expense.amountMinor,
                                    localeCode: l10n.locale.languageCode,
                                    compact: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _monthLabel(points[index].month, l10n),
                          style: context.texts.labelSmall?.copyWith(
                            letterSpacing: 0.2,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _monthLabel(DateTime month, AppLocalizations l10n) {
    const id = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    const en = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final names = l10n.isId ? id : en;
    return names[month.month - 1];
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.ratio, required this.color, required this.tooltip});

  final double ratio;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final safe = ratio.isFinite ? ratio.clamp(0.0, 1.0) : 0.0;
    return Tooltip(
      message: tooltip,
      child: FractionallySizedBox(
        heightFactor: safe == 0 ? 0.015 : math.max(0.04, safe),
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.82),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: context.texts.labelSmall?.copyWith(letterSpacing: 0.2),
        ),
      ],
    );
  }
}

class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    super.key,
    required this.spend,
    this.size = 168,
    this.strokeWidth = 18,
  });

  final List<CategorySpend> spend;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = spend.fold<int>(
      0,
      (sum, item) => sum + item.amount.amountMinor,
    );
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DonutPainter(
          spend: spend,
          trackColor: context.dompet.surfaceMuted,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.total,
                style: context.texts.labelSmall?.copyWith(letterSpacing: 1.4),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: size * 0.62,
                  child: Text(
                    MoneyFormatter.format(
                      total,
                      localeCode: l10n.locale.languageCode,
                      compact: true,
                    ),
                    textAlign: TextAlign.center,
                    style: AppTypography.money(
                      fontSize: size * 0.13,
                      color: context.dompet.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.spend,
    required this.trackColor,
    required this.strokeWidth,
  });

  final List<CategorySpend> spend;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawCircle(center, radius, paint);

    if (spend.isEmpty) return;
    var start = -math.pi / 2;
    const gap = 0.035;
    for (final item in spend.take(7)) {
      final sweep = math.max(0.0, item.ratio * math.pi * 2 - gap);
      if (sweep <= 0) continue;
      paint.color = colorFromHex(item.category.colorHex);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.spend != spend ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
