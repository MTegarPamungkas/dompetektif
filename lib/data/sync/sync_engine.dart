import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dompetektif/data/datasources/cloud_gateway.dart';
import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/domain/entities/app_user.dart';
import 'package:dompetektif/domain/entities/sync_status.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';
import 'package:dompetektif/domain/repositories/auth_repository.dart';

class SyncEngine implements SyncRepository {
  SyncEngine({
    required LocalStore store,
    required CloudGateway gateway,
    required AuthRepository auth,
    required Connectivity connectivity,
  }) : _store = store,
       _gateway = gateway,
       _auth = auth,
       _connectivity = connectivity;

  final LocalStore _store;
  final CloudGateway _gateway;
  final AuthRepository _auth;
  final Connectivity _connectivity;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncStatus _status = const SyncStatus();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<int>? _pendingSubscription;
  StreamSubscription<void>? _changeSubscription;
  Timer? _syncDebounce;
  Timer? _pullDebounce;
  bool _online = true;
  bool _running = false;
  bool _started = false;

  static const List<String> syncTables = [
    'categories',
    'wallets',
    'wallet_members',
    'transactions',
    'budgets',
    'recurring_rules',
    'case_notes',
    'receipts',
    'reports',
  ];

  @override
  SyncStatus get current => _status;

  bool get isDemoMode => _gateway.isDemo;

  @override
  Stream<SyncStatus> watchStatus() async* {
    yield _status;
    yield* _statusController.stream;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _pendingSubscription = _store.watchOutboxCount().listen((count) {
      _setStatus(_status.copyWith(pendingCount: count));
    });

    try {
      final results = await _connectivity.checkConnectivity();
      _online = !_isOffline(results);
    } catch (_) {
      _online = true;
    }

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) {
      final wasOnline = _online;
      _online = !_isOffline(results);
      if (!_online) {
        _setStatus(
          _status.copyWith(
            phase: SyncPhase.offline,
            message: 'Tidak ada koneksi. Perubahan disimpan di perangkat.',
          ),
        );
      } else if (!wasOnline) {
        requestSync();
      }
    });

    _authSubscription = _auth.watchUser().listen((user) {
      if (user == null) {
        _setStatus(
          _status.copyWith(
            phase: SyncPhase.offline,
            message: 'Masuk untuk menyinkronkan berkas.',
          ),
        );
      } else {
        requestSync();
      }
    });

    if (!_gateway.isDemo) {
      _changeSubscription = _gateway
          .watchChanges(syncTables)
          .listen((_) => _schedulePull());
    }

    if (_gateway.isDemo) {
      _setStatus(SyncStatus.demo(pendingCount: _store.outboxItems().length));
      return;
    }

    if (_auth.currentUser == null) {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.offline,
          message: 'Masuk untuk menyinkronkan berkas.',
        ),
      );
      return;
    }

    if (_online) {
      requestSync();
    } else {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.offline,
          message: 'Tidak ada koneksi. Perubahan disimpan di perangkat.',
        ),
      );
    }
  }

  void requestSync() {
    if (_gateway.isDemo) {
      _setStatus(SyncStatus.demo(pendingCount: _store.outboxItems().length));
      return;
    }
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 500), syncNow);
  }

  void _schedulePull() {
    if (_gateway.isDemo) return;
    _pullDebounce?.cancel();
    _pullDebounce = Timer(
      const Duration(milliseconds: 400),
      () => pullChanges(),
    );
  }

  @override
  Future<void> syncNow() async {
    if (_gateway.isDemo) {
      _setStatus(SyncStatus.demo(pendingCount: _store.outboxItems().length));
      return;
    }
    if (_running) return;
    if (!_online) {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.offline,
          message: 'Tidak ada koneksi. Perubahan disimpan di perangkat.',
        ),
      );
      return;
    }
    if (_auth.currentUser == null) return;

    _running = true;
    _setStatus(
      _status.copyWith(
        phase: SyncPhase.syncing,
        message: null,
        clearMessage: true,
      ),
    );

    try {
      await _pushOutbox();
      await pullChanges();
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.idle,
          lastSyncedAt: DateTime.now(),
          message: null,
          clearMessage: true,
        ),
      );
    } catch (error) {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.error,
          message: 'Sinkronisasi tertunda: $error',
        ),
      );
    } finally {
      _running = false;
    }
  }

  Future<void> pullChanges() async {
    if (_gateway.isDemo || !_online || _auth.currentUser == null) return;

    try {
      for (final table in syncTables) {
        var cursor = _store.getMeta('sync_cursor_$table') as String?;
        while (true) {
          final rows = await _gateway.pull(
            table,
            since: cursor == null ? null : DateTime.tryParse(cursor),
            limit: 200,
          );
          if (rows.isEmpty) break;

          for (final row in rows) {
            _mergeRemoteRow(table, row);
          }

          final lastUpdated = rows.last['updated_at']?.toString();
          if (lastUpdated == null) break;
          cursor = lastUpdated;
          await _store.setMeta('sync_cursor_$table', cursor);
          if (rows.length < 200) break;
        }
      }
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.idle,
          lastSyncedAt: DateTime.now(),
          pendingCount: _store.outboxItems().length,
          message: null,
          clearMessage: true,
        ),
      );
    } catch (error) {
      _setStatus(
        _status.copyWith(
          phase: SyncPhase.error,
          message: 'Gagal menarik pembaruan: $error',
        ),
      );
    }
  }

  void _mergeRemoteRow(String table, Map<String, dynamic> row) {
    final id = row['id']?.toString();
    if (id == null) return;
    final local = _store.get(table, id);
    if (local == null) {
      _store.put(table, row);
      return;
    }

    final localUpdated = DateTime.tryParse(
      local['updated_at']?.toString() ?? '',
    );
    final remoteUpdated = DateTime.tryParse(
      row['updated_at']?.toString() ?? '',
    );
    if (remoteUpdated == null) return;
    if (localUpdated == null || remoteUpdated.isAfter(localUpdated)) {
      _store.put(table, row, pending: local['is_pending'] == true);
    }
  }

  Future<void> _pushOutbox() async {
    for (final item in _store.outboxItems()) {
      final id = item['id'] as String;
      final table = item['table'] as String;
      final entityId = item['entity_id'] as String;
      final operation = item['operation'] as String;
      final payload = Map<String, dynamic>.from(
        item['payload'] as Map? ?? const {},
      )..remove('is_pending');

      try {
        if (operation == 'delete') {
          await _gateway.softDelete(
            table,
            entityId,
            DateTime.tryParse(item['created_at']?.toString() ?? '') ??
                DateTime.now(),
          );
        } else {
          await _gateway.upsert(table, payload);
        }
        await _store.removeOutbox(id);
        await _store.markSynced(table, entityId);
      } catch (error) {
        await _store.enqueueOutbox({
          ...item,
          'attempts': (item['attempts'] as int? ?? 0) + 1,
          'last_error': error.toString(),
        });
        rethrow;
      }
    }
  }

  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty || results.contains(ConnectivityResult.none);
  }

  void _setStatus(SyncStatus status) {
    _status = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> dispose() async {
    _syncDebounce?.cancel();
    _pullDebounce?.cancel();
    await _connectivitySubscription?.cancel();
    await _authSubscription?.cancel();
    await _pendingSubscription?.cancel();
    await _changeSubscription?.cancel();
    await _statusController.close();
  }
}
