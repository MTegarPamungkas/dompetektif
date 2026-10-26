import 'dart:async';

import 'package:dompetektif/app/app_maintenance.dart';
import 'package:dompetektif/core/di/injection_container.dart';
import 'package:dompetektif/core/localization/app_localizations.dart';
import 'package:dompetektif/core/responsive/app_breakpoints.dart';
import 'package:dompetektif/core/theme/app_theme.dart';
import 'package:dompetektif/core/widgets/case_mark.dart';
import 'package:dompetektif/domain/entities/sync_status.dart';
import 'package:dompetektif/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:dompetektif/features/sync/presentation/cubit/sync_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  Timer? _maintenanceTimer;
  bool _maintenanceRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runMaintenance());
    _maintenanceTimer = Timer.periodic(
      const Duration(minutes: 20),
      (_) => _runMaintenance(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _runMaintenance();
  }

  Future<void> _runMaintenance() async {
    if (!mounted || _maintenanceRunning) return;
    _maintenanceRunning = true;
    try {
      await getIt<AppMaintenance>().run(context.l10n);
    } catch (_) {
      // Maintenance never blocks the case desk.
    } finally {
      _maintenanceRunning = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _maintenanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usesSide = context.usesSideNavigation;
    final index = widget.navigationShell.currentIndex;
    final destinations = _destinations(context.l10n);

    return Scaffold(
      body: Row(
        children: [
          if (usesSide)
            _SideNavigation(
              index: index,
              destinations: destinations,
              expanded: MediaQuery.sizeOf(context).width >= 1180,
              onSelect: _onSelect,
            ),
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    title: destinations[index].label,
                    eyebrow: context.l10n.caseFile,
                    compact: !usesSide,
                    onSettings: () => context.push('/settings'),
                  ),
                  Expanded(
                    child: CaseBackground(child: widget.navigationShell),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: usesSide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: _onSelect,
              destinations: [
                for (final destination in destinations)
                  NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.selectedIcon),
                    label: destination.label,
                  ),
              ],
            ),
    );
  }

  void _onSelect(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  List<_Destination> _destinations(AppLocalizations l10n) => [
    _Destination(
      label: l10n.dashboard,
      icon: Icons.grid_view_outlined,
      selectedIcon: Icons.grid_view_rounded,
    ),
    _Destination(
      label: l10n.ledger,
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
    ),
    _Destination(
      label: l10n.evidence,
      icon: Icons.folder_copy_outlined,
      selectedIcon: Icons.folder_copy_rounded,
    ),
    _Destination(
      label: l10n.reports,
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
    ),
    _Destination(
      label: l10n.team,
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
    ),
  ];
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.eyebrow,
    required this.compact,
    required this.onSettings,
  });

  final String title;
  final String eyebrow;
  final bool compact;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final edge = compact ? 16.0 : 28.0;
    final width = MediaQuery.sizeOf(context).width;
    final showSyncChip = width >= 360;
    final showSettingsIcon = width >= 440;
    return Container(
      padding: EdgeInsets.fromLTRB(
        edge,
        compact ? 12 : 16,
        edge,
        compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: context.dompet.background.withValues(alpha: 0.82),
        border: Border(
          bottom: BorderSide(color: context.dompet.line.withValues(alpha: 0.7)),
        ),
      ),
      child: Row(
        children: [
          if (compact) ...[
            const CaseMark(size: 34, showShadow: false),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: context.texts.labelSmall?.copyWith(
                    letterSpacing: 1.8,
                    fontSize: 8,
                    color: context.dompet.accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: compact
                      ? context.texts.titleLarge?.copyWith(fontSize: 20)
                      : context.texts.headlineSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (showSyncChip) ...[const _SyncChip(), const SizedBox(width: 6)],
          if (showSettingsIcon) ...[
            IconButton(
              tooltip: context.l10n.openSettings,
              onPressed: onSettings,
              icon: const Icon(Icons.tune_rounded),
            ),
            const SizedBox(width: 2),
          ],
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              final name = state.user?.displayName ?? context.l10n.demoUser;
              final initials = _initials(name);
              return Tooltip(
                message: name,
                child: InkWell(
                  onTap: onSettings,
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: context.dompet.accentSoft,
                    child: Text(
                      initials,
                      style: context.texts.labelMedium?.copyWith(
                        color: context.dompet.accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.length > 1
        ? parts.last.substring(0, 1).toUpperCase()
        : '';
    return '$first$last';
  }
}

class _SideNavigation extends StatelessWidget {
  const _SideNavigation({
    required this.index,
    required this.destinations,
    required this.expanded,
    required this.onSelect,
  });

  final int index;
  final List<_Destination> destinations;
  final bool expanded;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final width = expanded ? 228.0 : 86.0;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.dompet.surface,
        border: Border(right: BorderSide(color: context.dompet.line)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? 18 : 20,
                20,
                expanded ? 18 : 20,
                22,
              ),
              child: expanded
                  ? Row(
                      children: [
                        const CaseMark(size: 38),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DOMPETEKTIF',
                                style: context.texts.labelSmall?.copyWith(
                                  letterSpacing: 1.2,
                                  fontSize: 10,
                                  color: context.dompet.ink,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.appTaglineShort,
                                style: context.texts.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: context.dompet.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Center(child: CaseMark(size: 38)),
            ),
            for (var i = 0; i < destinations.length; i++)
              _NavItem(
                destination: destinations[i],
                selected: i == index,
                expanded: expanded,
                onTap: () => onSelect(i),
              ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? 14 : 12),
              child: const Divider(),
            ),
            _SettingsItem(expanded: expanded),
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.fromLTRB(
                expanded ? 14 : 10,
                8,
                expanded ? 14 : 10,
                16,
              ),
              child: const _SyncChip(side: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? context.dompet.accent
        : context.dompet.inkMuted;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 9, vertical: 3),
      child: InkWell(
        borderRadius: AppRadius.allMd,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected ? context.dompet.accentSoft : Colors.transparent,
            borderRadius: AppRadius.allMd,
            border: Border.all(
              color: selected
                  ? context.dompet.accent.withValues(alpha: 0.2)
                  : Colors.transparent,
            ),
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      size: 20,
                      color: foreground,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        destination.label,
                        style: context.texts.labelLarge?.copyWith(
                          color: selected
                              ? context.dompet.ink
                              : context.dompet.inkMuted,
                          fontSize: 12.5,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (selected)
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: context.dompet.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                )
              : Tooltip(
                  message: destination.label,
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 21,
                    color: foreground,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: expanded ? 12 : 9, vertical: 2),
      child: InkWell(
        borderRadius: AppRadius.allMd,
        onTap: () => context.push('/settings'),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: 12,
          ),
          child: expanded
              ? Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 20,
                      color: context.dompet.inkMuted,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.settings,
                      style: context.texts.labelLarge?.copyWith(
                        color: context.dompet.inkMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                )
              : Tooltip(
                  message: context.l10n.settings,
                  child: Icon(
                    Icons.tune_rounded,
                    size: 21,
                    color: context.dompet.inkMuted,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SyncChip extends StatelessWidget {
  const _SyncChip({this.side = false});

  final bool side;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncStatus>(
      builder: (context, status) {
        final l10n = context.l10n;
        final (label, icon, tone) = switch (status.phase) {
          SyncPhase.demo => (
            l10n.demoMode,
            Icons.science_outlined,
            context.dompet.accent,
          ),
          SyncPhase.syncing => (
            l10n.syncing,
            Icons.sync_rounded,
            context.dompet.info,
          ),
          SyncPhase.offline => (
            l10n.offline,
            Icons.cloud_off_rounded,
            context.dompet.inkMuted,
          ),
          SyncPhase.error => (
            l10n.connectionProblem,
            Icons.error_outline_rounded,
            context.dompet.evidence,
          ),
          SyncPhase.idle =>
            status.pendingCount > 0
                ? (
                    '${status.pendingCount}',
                    Icons.cloud_upload_outlined,
                    context.dompet.accent,
                  )
                : (
                    l10n.statusSynced,
                    Icons.cloud_done_outlined,
                    context.dompet.success,
                  ),
        };

        return Tooltip(
          message: l10n.syncNow,
          child: InkWell(
            borderRadius: AppRadius.allPill,
            onTap: status.phase == SyncPhase.syncing
                ? null
                : () => context.read<SyncCubit>().syncNow(),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: side ? 9 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.1),
                borderRadius: AppRadius.allPill,
                border: Border.all(color: tone.withValues(alpha: 0.24)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status.phase == SyncPhase.syncing)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.7,
                        color: tone,
                      ),
                    )
                  else
                    Icon(icon, size: 13, color: tone),
                  if (side) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: context.texts.labelSmall?.copyWith(
                          color: tone,
                          fontSize: 8.5,
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: context.texts.labelSmall?.copyWith(
                        color: tone,
                        fontSize: 8.5,
                        letterSpacing: 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
