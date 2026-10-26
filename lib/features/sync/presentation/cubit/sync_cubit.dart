import 'dart:async';

import 'package:dompetektif/domain/entities/sync_status.dart';
import 'package:dompetektif/domain/usecases/sync_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SyncCubit extends Cubit<SyncStatus> {
  SyncCubit(this._watch, this._syncNow) : super(const SyncStatus()) {
    _subscription = _watch().listen(emit);
  }

  final WatchSyncStatus _watch;
  final SyncNow _syncNow;

  StreamSubscription<SyncStatus>? _subscription;

  Future<void> syncNow() async {
    await _syncNow();
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
