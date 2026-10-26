import 'dart:async';

import 'package:dompetektif/domain/entities/sync_status.dart';

sealed class SyncEvent {
  const SyncEvent();
}

final class SyncStarted extends SyncEvent {
  const SyncStarted();
}

final class SyncStatusChanged extends SyncEvent {
  const SyncStatusChanged(this.status);

  final SyncStatus status;
}

final class SyncNowRequested extends SyncEvent {
  const SyncNowRequested(this.completer);

  final Completer<void> completer;
}
