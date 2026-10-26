import 'dart:async';

import 'package:dompetektif/domain/entities/sync_status.dart';
import 'package:dompetektif/domain/usecases/sync_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sync_event.dart';

export 'sync_event.dart';

class SyncBloc extends Bloc<SyncEvent, SyncStatus> {
  SyncBloc(this._watch, this._syncNow) : super(const SyncStatus()) {
    on<SyncStarted>(_onStarted);
    on<SyncStatusChanged>(_onStatusChanged);
    on<SyncNowRequested>(_onSyncNow);
    add(const SyncStarted());
  }

  final WatchSyncStatus _watch;
  final SyncNow _syncNow;
  StreamSubscription<SyncStatus>? _subscription;

  Future<void> _onStarted(SyncStarted event, Emitter<SyncStatus> emit) async {
    await _subscription?.cancel();
    _subscription = _watch().listen((status) => add(SyncStatusChanged(status)));
  }

  void _onStatusChanged(SyncStatusChanged event, Emitter<SyncStatus> emit) {
    emit(event.status);
  }

  Future<void> _onSyncNow(
    SyncNowRequested event,
    Emitter<SyncStatus> emit,
  ) async {
    try {
      await _syncNow();
    } finally {
      if (!event.completer.isCompleted) event.completer.complete();
    }
  }

  Future<void> syncNow() async {
    final completer = Completer<void>();
    add(SyncNowRequested(completer));
    await completer.future;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
