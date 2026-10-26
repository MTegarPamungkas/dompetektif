import 'dart:async';

import 'package:dompetektif/app/app_shell.dart';
import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/app_surfaces.dart';
import 'package:dompetektif/core/widgets/case_mark.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dompetektif/features/auth/presentation/pages/auth_page.dart';
import 'package:dompetektif/features/budgets/presentation/bloc/budget_bloc.dart';
import 'package:dompetektif/features/budgets/presentation/pages/budgets_page.dart';
import 'package:dompetektif/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:dompetektif/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:dompetektif/features/evidence/presentation/bloc/evidence_bloc.dart';
import 'package:dompetektif/features/evidence/presentation/pages/evidence_page.dart';
import 'package:dompetektif/features/evidence/presentation/pages/receipt_detail_page.dart';
import 'package:dompetektif/features/evidence/presentation/pages/scan_receipt_page.dart';
import 'package:dompetektif/features/ledger/presentation/bloc/ledger_bloc.dart';
import 'package:dompetektif/features/ledger/presentation/bloc/transaction_form_bloc.dart';
import 'package:dompetektif/features/ledger/presentation/pages/ledger_page.dart';
import 'package:dompetektif/features/ledger/presentation/pages/transaction_editor_page.dart';
import 'package:dompetektif/features/reports/presentation/bloc/report_bloc.dart';
import 'package:dompetektif/features/reports/presentation/pages/report_detail_page.dart';
import 'package:dompetektif/features/reports/presentation/pages/reports_page.dart';
import 'package:dompetektif/features/settings/presentation/bloc/settings_data_bloc.dart';
import 'package:dompetektif/features/settings/presentation/pages/categories_page.dart';
import 'package:dompetektif/features/settings/presentation/pages/recurring_page.dart';
import 'package:dompetektif/features/settings/presentation/pages/settings_page.dart';
import 'package:dompetektif/features/settings/presentation/pages/wallets_page.dart';
import 'package:dompetektif/features/team/presentation/bloc/team_bloc.dart';
import 'package:dompetektif/features/team/presentation/pages/team_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(AuthBloc auth) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(auth.stream),
    redirect: (context, state) {
      final session = auth.state;
      final location = state.matchedLocation;
      if (session.resolving) {
        return location == '/splash' ? null : '/splash';
      }
      if (!session.signedIn) {
        return location == '/auth' ? null : '/auth';
      }
      if (location == '/auth' || location == '/splash' || location == '/') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _SplashPage(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<DashboardBloc>(),
                  child: const DashboardPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ledger',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<LedgerBloc>(),
                  child: const LedgerPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/evidence',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<EvidenceBloc>(),
                  child: const EvidencePage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<ReportBloc>(),
                  child: const ReportsPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/team',
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<TeamBloc>(),
                  child: const TeamPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/wallets',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SettingsDataBloc>(),
          child: const WalletsPage(),
        ),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SettingsDataBloc>(),
          child: const CategoriesPage(),
        ),
      ),
      GoRoute(
        path: '/recurring',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<SettingsDataBloc>(),
          child: const RecurringPage(),
        ),
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<BudgetBloc>(),
          child: const BudgetsPage(),
        ),
      ),
      GoRoute(
        path: '/transaction/new',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<TransactionFormBloc>(param1: null),
          child: const TransactionEditorPage(),
        ),
      ),
      GoRoute(
        path: '/transaction/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return BlocProvider(
            create: (_) => getIt<TransactionFormBloc>(param1: id),
            child: TransactionEditorPage(transactionId: id),
          );
        },
      ),
      GoRoute(
        path: '/receipt/scan',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<EvidenceBloc>(),
          child: const ScanReceiptPage(),
        ),
      ),
      GoRoute(
        path: '/receipt/:id',
        builder: (context, state) =>
            ReceiptDetailPage(receiptId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/report/:id',
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<ReportBloc>(),
          child: ReportDetailPage(
            reportId: state.pathParameters['id']!,
            report: state.extra is InvestigationReport
                ? state.extra as InvestigationReport
                : null,
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: CaseBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: context.l10n.notFound,
                body: state.uri.toString(),
                action: FilledButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: Text(context.l10n.dashboard),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: CaseBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CaseMark(size: 78),
                const SizedBox(height: 26),
                Text(
                  'DOMPETEKTIF',
                  style: context.texts.labelLarge?.copyWith(
                    letterSpacing: 4.6,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.dompet.ink,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: context.texts.displaySmall?.copyWith(
                      fontSize: 25,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.dompet.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
