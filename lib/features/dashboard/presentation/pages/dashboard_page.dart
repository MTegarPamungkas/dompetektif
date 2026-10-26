import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/localization/category_names.dart';
import 'package:dompetektif/core/responsive/app_breakpoints.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/app_visuals.dart';
import 'package:dompetektif/domain/entities/app_settings.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:dompetektif/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.loading && state.data == null) {
          return const PageScroll(children: [LoadingState()]);
        }
        if (state.failure && state.data == null) {
          return PageScroll(
            children: [
              ErrorState(
                onRetry: () => context.read<DashboardCubit>().reload(),
              ),
            ],
          );
        }
        final data = state.data ?? const DashboardData.empty();
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 940;
            return PageScroll(
              children: [
                _DashboardHeader(data: data),
                const SizedBox(height: 22),
                if (data.wallets.isEmpty)
                  _NoWalletState()
                else ...[
                  _HeroBalance(data: data, settings: settings),
                  const SizedBox(height: 16),
                  _WalletFilterStrip(data: data, settings: settings),
                  const SizedBox(height: 26),
                  if (data.anomalies.isNotEmpty) ...[
                    _AnomalyBanner(anomaly: data.anomalies.first),
                    const SizedBox(height: 18),
                  ],
                  if (data.budgetAlerts.isNotEmpty) ...[
                    _BudgetAlertStrip(alerts: data.budgetAlerts),
                    const SizedBox(height: 18),
                  ],
                  if (twoColumns)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            children: [
                              _CashflowCard(data: data),
                              const SizedBox(height: 16),
                              _CategoryLeakCard(data: data, settings: settings),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _BudgetWatchCard(data: data),
                              const SizedBox(height: 16),
                              _TeamActivityCard(data: data),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _CashflowCard(data: data),
                    const SizedBox(height: 16),
                    _BudgetWatchCard(data: data),
                    const SizedBox(height: 16),
                    _CategoryLeakCard(data: data, settings: settings),
                    const SizedBox(height: 16),
                    _TeamActivityCard(data: data),
                  ],
                  const SizedBox(height: 26),
                  if (twoColumns)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: _RecentCasesCard(
                            data: data,
                            settings: settings,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: _RecentEvidenceCard(
                            data: data,
                            settings: settings,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    _RecentCasesCard(data: data, settings: settings),
                    const SizedBox(height: 16),
                    _RecentEvidenceCard(data: data, settings: settings),
                  ],
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.data});

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

class _HeroBalance extends StatelessWidget {
  const _HeroBalance({required this.data, required this.settings});

  final DashboardData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final active = data.activeWallet;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: context.dompet.accent.withValues(alpha: 0.2)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.dompet.surfaceElevated,
            context.dompet.surface,
            context.dompet.background.withValues(alpha: 0.9),
          ],
          stops: const [0, 0.58, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: context.dompet.shadow.withValues(alpha: 0.34),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -50,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    context.dompet.accent.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active == null
                              ? l10n.totalBalance
                              : '${l10n.totalBalance} · ${active.wallet.name}',
                          style: context.texts.labelSmall?.copyWith(
                            letterSpacing: 1.6,
                            fontSize: 8.5,
                            color: context.dompet.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            MoneyFormatter.format(
                              data.totalBalance.amountMinor,
                              localeCode: l10n.locale.languageCode,
                              hidden: settings.hideAmounts,
                            ),
                            style: AppTypography.money(
                              fontSize: 45,
                              color: context.dompet.ink,
                              letterSpacing: -1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            _TrendPill(value: data.monthExpenseChange),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                l10n.previousMonthComparison,
                                style: context.texts.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: context.dompet.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CaseStamp(label: l10n.confidential, subLabel: 'PK-2026'),
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final metrics = [
                    _HeroStat(
                      label: compact ? l10n.incomeShort : l10n.income,
                      value: MoneyFormatter.format(
                        data.monthIncome.amountMinor,
                        localeCode: l10n.locale.languageCode,
                        compact: true,
                        hidden: settings.hideAmounts,
                      ),
                      color: context.dompet.success,
                      icon: Icons.south_west_rounded,
                    ),
                    _HeroStat(
                      label: compact ? l10n.expenseShort : l10n.expense,
                      value: MoneyFormatter.format(
                        data.monthExpense.amountMinor,
                        localeCode: l10n.locale.languageCode,
                        compact: true,
                        hidden: settings.hideAmounts,
                      ),
                      color: context.dompet.evidence,
                      icon: Icons.north_east_rounded,
                    ),
                    _HeroStat(
                      label: compact ? l10n.netShort : l10n.net,
                      value: MoneyFormatter.format(
                        data.monthNet.amountMinor,
                        localeCode: l10n.locale.languageCode,
                        compact: true,
                        hidden: settings.hideAmounts,
                      ),
                      color: data.monthNet.isNegative
                          ? context.dompet.warning
                          : context.dompet.info,
                      icon: Icons.compare_arrows_rounded,
                    ),
                  ];
                  if (compact) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final metric in metrics)
                          SizedBox(
                            width: (constraints.maxWidth - 8) / 2,
                            child: metric,
                          ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      for (var index = 0; index < metrics.length; index++) ...[
                        Expanded(child: metrics[index]),
                        if (index < metrics.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final addButton = FilledButton.icon(
                    onPressed: () => context.push('/transaction/new'),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(l10n.addTransaction),
                  );
                  final scanButton = OutlinedButton.icon(
                    onPressed: () => context.push('/receipt/scan'),
                    icon: const Icon(Icons.document_scanner_outlined, size: 17),
                    label: Text(l10n.scanReceipt),
                  );
                  if (constraints.maxWidth < 340) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        addButton,
                        const SizedBox(height: 8),
                        scanButton,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: addButton),
                      const SizedBox(width: 9),
                      Expanded(child: scanButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: context.dompet.background.withValues(alpha: 0.42),
        borderRadius: AppRadius.allMd,
        border: Border.all(color: context.dompet.line.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    fontSize: 7.5,
                    letterSpacing: 0.7,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.money(fontSize: 14, color: color),
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

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final up = value > 0;
    final color = up ? context.dompet.evidence : context.dompet.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allPill,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            MoneyFormatter.percent(
              value.abs(),
              localeCode: l10n.locale.languageCode,
            ),
            style: context.texts.labelSmall?.copyWith(
              color: color,
              fontSize: 8.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletFilterStrip extends StatelessWidget {
  const _WalletFilterStrip({required this.data, required this.settings});

  final DashboardData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              l10n.activeWallet.toUpperCase(),
              style: context.texts.labelSmall?.copyWith(
                fontSize: 8,
                letterSpacing: 1.2,
              ),
            ),
          ),
          _WalletChip(
            label: l10n.allWallets,
            selected: settings.activeWalletId == null,
            onTap: () => context.read<SettingsCubit>().setActiveWallet(null),
          ),
          for (final item in data.wallets)
            _WalletChip(
              label: item.wallet.name,
              selected: settings.activeWalletId == item.wallet.id,
              color: colorFromHex(item.wallet.colorHex),
              onTap: () =>
                  context.read<SettingsCubit>().setActiveWallet(item.wallet.id),
            ),
        ],
      ),
    );
  }
}

class _WalletChip extends StatelessWidget {
  const _WalletChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? context.dompet.accent;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: InkWell(
        borderRadius: AppRadius.allPill,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? tone.withValues(alpha: 0.14)
                : context.dompet.surface,
            borderRadius: AppRadius.allPill,
            border: Border.all(
              color: selected
                  ? tone.withValues(alpha: 0.45)
                  : context.dompet.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? tone : context.dompet.inkMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: context.texts.labelSmall?.copyWith(
                  fontSize: 9.5,
                  color: selected
                      ? context.dompet.ink
                      : context.dompet.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnomalyBanner extends StatelessWidget {
  const _AnomalyBanner({required this.anomaly});

  final Anomaly anomaly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final category = anomaly.categoryName ?? l10n.unusualAmount;
    final merchant = anomaly.entry.transaction.merchant.isEmpty
        ? anomaly.entry.wallet.name
        : anomaly.entry.transaction.merchant;
    final amount = MoneyFormatter.format(
      anomaly.entry.transaction.amount.amountMinor,
      localeCode: l10n.locale.languageCode,
    );
    return AppCard(
      onTap: () => context.push('/transaction/${anomaly.entry.transaction.id}'),
      accent: context.dompet.evidence,
      background: context.dompet.evidenceSoft.withValues(alpha: 0.7),
      borderColor: context.dompet.evidence.withValues(alpha: 0.28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.dompet.evidence.withValues(alpha: 0.14),
              borderRadius: AppRadius.allMd,
            ),
            child: Icon(
              Icons.crisis_alert_rounded,
              color: context.dompet.evidence,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        anomaly.kind == AnomalyKind.categoryLeak
                            ? l10n.anomalyHeadline(category)
                            : l10n.unusualAmount,
                        style: context.texts.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusPill(
                      label: anomaly.severity == AnomalySeverity.alert
                          ? l10n.alert
                          : l10n.watch,
                      tone: PillTone.evidence,
                      icon: Icons.priority_high_rounded,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.anomalyBody(merchant, amount),
                  style: context.texts.bodySmall?.copyWith(
                    height: 1.5,
                    color: context.dompet.inkMuted,
                  ),
                ),
                if (anomaly.deviation > 0) ...[
                  const SizedBox(height: 7),
                  Text(
                    '${anomaly.deviation.toStringAsFixed(1)}${l10n.anomalyDeviation}',
                    style: context.texts.labelSmall?.copyWith(
                      fontSize: 8.5,
                      color: context.dompet.evidence,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right_rounded,
            color: context.dompet.evidence,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertStrip extends StatelessWidget {
  const _BudgetAlertStrip({required this.alerts});

  final List<BudgetProgress> alerts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      accent: context.dompet.warning,
      padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: context.dompet.warning,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alerts.length == 1
                  ? l10n.budgetOver(
                      localizedCategoryName(l10n, alerts.first.category),
                    )
                  : l10n.t(
                      '${alerts.length} Batas TKP perlu perhatian.',
                      '${alerts.length} limits need attention.',
                    ),
              style: context.texts.bodySmall?.copyWith(height: 1.45),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.push('/budgets'),
            child: Text(l10n.manage),
          ),
        ],
      ),
    );
  }
}

class _CashflowCard extends StatelessWidget {
  const _CashflowCard({required this.data});

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

class _CategoryLeakCard extends StatelessWidget {
  const _CategoryLeakCard({required this.data, required this.settings});

  final DashboardData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.thisMonth,
            title: l10n.categoryBreakdown,
            padding: EdgeInsets.zero,
            action: TextButton(
              onPressed: () => context.go('/ledger'),
              child: Text(l10n.viewAll),
            ),
          ),
          const SizedBox(height: 8),
          if (data.categorySpend.isEmpty)
            EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: l10n.noData,
              compact: true,
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 460;
                final donut = CategoryDonut(
                  spend: data.categorySpend,
                  size: compact ? 150 : 168,
                );
                final list = Column(
                  children: [
                    for (final item in data.categorySpend.take(5))
                      _CategorySpendRow(
                        item: item,
                        hidden: settings.hideAmounts,
                      ),
                  ],
                );
                if (compact) {
                  return Column(
                    children: [
                      Center(child: donut),
                      const SizedBox(height: 16),
                      list,
                    ],
                  );
                }
                return Row(
                  children: [
                    donut,
                    const SizedBox(width: 22),
                    Expanded(child: list),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CategorySpendRow extends StatelessWidget {
  const _CategorySpendRow({required this.item, required this.hidden});

  final CategorySpend item;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CategoryAvatar(category: item.category, size: 30),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizedCategoryName(l10n, item.category),
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      MoneyFormatter.format(
                        item.amount.amountMinor,
                        localeCode: l10n.locale.languageCode,
                        compact: true,
                        hidden: hidden,
                      ),
                      style: context.texts.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                BudgetProgressBar(
                  ratio: item.ratio,
                  height: 4,
                  color: colorFromHex(item.category.colorHex),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetWatchCard extends StatelessWidget {
  const _BudgetWatchCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = data.budgetProgress.take(4).toList();
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.budgets,
            title: l10n.budgetWatch,
            padding: EdgeInsets.zero,
            action: IconButton(
              tooltip: l10n.manage,
              onPressed: () => context.push('/budgets'),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          if (progress.isEmpty)
            EmptyState(
              icon: Icons.track_changes_rounded,
              title: l10n.noBudgets,
              compact: true,
            )
          else
            for (final item in progress) _BudgetWatchRow(item: item),
        ],
      ),
    );
  }
}

class _BudgetWatchRow extends StatelessWidget {
  const _BudgetWatchRow({required this.item});

  final BudgetProgress item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = switch (item.status) {
      BudgetStatus.over => context.dompet.evidence,
      BudgetStatus.warning => context.dompet.warning,
      BudgetStatus.safe => context.dompet.success,
    };
    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: () => context.push('/budgets'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: [
            Row(
              children: [
                CategoryAvatar(category: item.category, size: 30),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    localizedCategoryName(l10n, item.category),
                    style: context.texts.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                Text(
                  MoneyFormatter.percent(
                    item.ratio,
                    localeCode: l10n.locale.languageCode,
                  ),
                  style: context.texts.labelSmall?.copyWith(
                    color: tone,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            BudgetProgressBar(ratio: item.ratio, height: 5),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${MoneyFormatter.format(item.spent.amountMinor, localeCode: l10n.locale.languageCode, compact: true)} / ${MoneyFormatter.format(item.budget.amount.amountMinor, localeCode: l10n.locale.languageCode, compact: true)}',
                    style: context.texts.bodySmall?.copyWith(fontSize: 9),
                  ),
                ),
                Text(
                  switch (item.status) {
                    BudgetStatus.over => l10n.budgetStatusOver,
                    BudgetStatus.warning => l10n.budgetStatusWarning,
                    BudgetStatus.safe => l10n.budgetStatusSafe,
                  },
                  style: context.texts.labelSmall?.copyWith(
                    color: tone,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamActivityCard extends StatelessWidget {
  const _TeamActivityCard({required this.data});

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
              _NotePreview(note: note),
        ],
      ),
    );
  }
}

class _NotePreview extends StatelessWidget {
  const _NotePreview({required this.note});

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

class _RecentCasesCard extends StatelessWidget {
  const _RecentCasesCard({required this.data, required this.settings});

  final DashboardData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.ledger,
            title: l10n.recentCases,
            padding: EdgeInsets.zero,
            action: TextButton(
              onPressed: () => context.go('/ledger'),
              child: Text(l10n.viewAll),
            ),
          ),
          const SizedBox(height: 4),
          if (data.recentEntries.isEmpty)
            EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.noTransactions,
              compact: true,
            )
          else
            for (final entry in data.recentEntries.take(6))
              _RecentCaseRow(entry: entry, hidden: settings.hideAmounts),
        ],
      ),
    );
  }
}

class _RecentCaseRow extends StatelessWidget {
  const _RecentCaseRow({required this.entry, required this.hidden});

  final LedgerEntry entry;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final transaction = entry.transaction;
    final categoryName = entry.category == null
        ? ''
        : localizedCategoryName(l10n, entry.category!);
    final title = transaction.merchant.isNotEmpty
        ? transaction.merchant
        : transaction.note.isNotEmpty
        ? transaction.note
        : categoryName.isNotEmpty
        ? categoryName
        : entry.wallet.name;
    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: () => context.push('/transaction/${transaction.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            CategoryAvatar(category: entry.category, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${CaseDates.dayMonth(transaction.occurredAt, l10n.locale.languageCode)} · ${entry.wallet.name}',
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TransactionAmount(
                  transaction: transaction,
                  hidden: hidden,
                  style: context.texts.bodyMedium?.copyWith(fontSize: 12),
                ),
                if (transaction.isPending)
                  StatusPill(
                    label: l10n.statusPending,
                    tone: PillTone.accent,
                    compact: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentEvidenceCard extends StatelessWidget {
  const _RecentEvidenceCard({required this.data, required this.settings});

  final DashboardData data;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            eyebrow: l10n.evidence,
            title: l10n.recentEvidence,
            padding: EdgeInsets.zero,
            action: TextButton(
              onPressed: () => context.go('/evidence'),
              child: Text(l10n.viewAll),
            ),
          ),
          const SizedBox(height: 8),
          if (data.recentReceipts.isEmpty)
            EmptyState(
              icon: Icons.document_scanner_outlined,
              title: l10n.noEvidence,
              compact: true,
              action: OutlinedButton(
                onPressed: () => context.push('/receipt/scan'),
                child: Text(l10n.scanNow),
              ),
            )
          else
            for (final receipt in data.recentReceipts.take(4))
              _ReceiptPreview(receipt: receipt, hidden: settings.hideAmounts),
        ],
      ),
    );
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.receipt, required this.hidden});

  final Receipt receipt;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      borderRadius: AppRadius.allSm,
      onTap: () => context.push('/receipt/${receipt.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: context.dompet.accentSoft,
                borderRadius: AppRadius.allSm,
                border: Border.all(
                  color: context.dompet.accent.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                receipt.imageKey != null
                    ? Icons.receipt_long_rounded
                    : Icons.article_outlined,
                size: 18,
                color: context.dompet.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receipt.merchant.isEmpty
                        ? l10n.unknownMerchant
                        : receipt.merchant,
                    style: context.texts.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CaseDates.dayMonth(
                      receipt.occurredAt,
                      l10n.locale.languageCode,
                    ),
                    style: context.texts.bodySmall?.copyWith(fontSize: 9.5),
                  ),
                ],
              ),
            ),
            MoneyText(
              money: receipt.total,
              hidden: hidden,
              style: context.texts.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoWalletState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      padding: const EdgeInsets.all(30),
      child: EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: l10n.createFirstWallet,
        body: l10n.createFirstWalletBody,
        action: FilledButton.icon(
          onPressed: () => context.push('/wallets'),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.walletCreate),
        ),
      ),
    );
  }
}
