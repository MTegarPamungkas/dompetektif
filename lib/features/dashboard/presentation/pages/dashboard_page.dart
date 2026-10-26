import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/no_wallet_state.dart';
import '../widgets/hero_balance.dart';
import '../widgets/wallet_filter_strip.dart';
import '../widgets/dashboard_alerts.dart';
import '../widgets/cashflow_card.dart';
import '../widgets/category_leak_card.dart';
import '../widgets/budget_watch_card.dart';
import '../widgets/team_activity_card.dart';
import '../widgets/recent_cases_card.dart';
import '../widgets/recent_evidence_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsBloc>().state;
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.loading && state.data == null) {
          return const PageScroll(children: [LoadingState()]);
        }
        if (state.failure && state.data == null) {
          return PageScroll(
            children: [
              ErrorState(onRetry: () => context.read<DashboardBloc>().reload()),
            ],
          );
        }
        final data = state.data ?? const DashboardData.empty();
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth >= 940;
            return PageScroll(
              children: [
                DashboardHeader(data: data),
                const SizedBox(height: 22),
                if (data.wallets.isEmpty)
                  NoWalletState()
                else ...[
                  HeroBalance(data: data, settings: settings),
                  const SizedBox(height: 16),
                  WalletFilterStrip(data: data, settings: settings),
                  const SizedBox(height: 26),
                  if (data.anomalies.isNotEmpty) ...[
                    AnomalyBanner(anomaly: data.anomalies.first),
                    const SizedBox(height: 18),
                  ],
                  if (data.budgetAlerts.isNotEmpty) ...[
                    BudgetAlertStrip(alerts: data.budgetAlerts),
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
                              CashflowCard(data: data),
                              const SizedBox(height: 16),
                              CategoryLeakCard(data: data, settings: settings),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              BudgetWatchCard(data: data),
                              const SizedBox(height: 16),
                              TeamActivityCard(data: data),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    CashflowCard(data: data),
                    const SizedBox(height: 16),
                    BudgetWatchCard(data: data),
                    const SizedBox(height: 16),
                    CategoryLeakCard(data: data, settings: settings),
                    const SizedBox(height: 16),
                    TeamActivityCard(data: data),
                  ],
                  const SizedBox(height: 26),
                  if (twoColumns)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: RecentCasesCard(
                            data: data,
                            settings: settings,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: RecentEvidenceCard(
                            data: data,
                            settings: settings,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    RecentCasesCard(data: data, settings: settings),
                    const SizedBox(height: 16),
                    RecentEvidenceCard(data: data, settings: settings),
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
