import 'package:equatable/equatable.dart';

enum SyncPhase {
  idle,
  syncing,
  offline,
  error,
  demo;

  bool get isBusy => this == SyncPhase.syncing;
}

class SyncStatus extends Equatable {
  const SyncStatus({
    this.phase = SyncPhase.idle,
    this.pendingCount = 0,
    this.lastSyncedAt,
    this.message,
  });

  const SyncStatus.demo({this.pendingCount = 0})
    : phase = SyncPhase.demo,
      lastSyncedAt = null,
      message = null;

  final SyncPhase phase;
  final int pendingCount;
  final DateTime? lastSyncedAt;
  final String? message;

  bool get isOffline => phase == SyncPhase.offline || phase == SyncPhase.demo;

  SyncStatus copyWith({
    SyncPhase? phase,
    int? pendingCount,
    DateTime? lastSyncedAt,
    String? message,
    bool clearMessage = false,
  }) {
    return SyncStatus(
      phase: phase ?? this.phase,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [phase, pendingCount, lastSyncedAt, message];
}
