import 'package:dompetektif/core/config/app_config.dart';
import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/data/mappers/json_helpers.dart';
import 'package:dompetektif/data/sync/sync_engine.dart';
import 'package:dompetektif/domain/repositories/auth_repository.dart';
import 'package:uuid/uuid.dart';

/// Shared write path for local-first repositories.
///
/// Every mutation is written to Hive first, tagged as pending, and added to the
/// outbox. The sync engine later drains the outbox in the background.
abstract class LocalRepositoryBase {
  LocalRepositoryBase(this.store, this.sync, this.auth, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final LocalStore store;
  final SyncEngine sync;
  final AuthRepository auth;
  final Uuid _uuid;

  String get userId => auth.currentUser?.id ?? AppConfig.demoUserId;

  String newId() => _uuid.v4();

  Future<void> upsertRow(
    String table,
    Map<String, dynamic> row, {
    DateTime? updatedAt,
  }) async {
    final now = updatedAt ?? DateTime.now();
    final payload = Map<String, dynamic>.from(row);
    payload['updated_at'] = isoOrNull(now);
    payload.remove('is_pending');

    final isDemo = sync.isDemoMode;
    await store.put(table, payload, pending: !isDemo);
    if (!isDemo) {
      await store.enqueueOutbox({
        'id': _uuid.v4(),
        'table': table,
        'entity_id': payload['id'],
        'operation': 'upsert',
        'payload': payload,
        'created_at': isoOrNull(now),
        'attempts': 0,
      });
    }
    sync.requestSync();
  }

  Future<void> softDeleteRow(String table, String id, {DateTime? at}) async {
    final now = at ?? DateTime.now();
    final current = store.get(table, id) ?? {'id': id};
    current['deleted_at'] = isoOrNull(now);
    current['updated_at'] = isoOrNull(now);
    current.remove('is_pending');

    final isDemo = sync.isDemoMode;
    await store.put(table, current, pending: !isDemo);
    if (!isDemo) {
      await store.enqueueOutbox({
        'id': _uuid.v4(),
        'table': table,
        'entity_id': id,
        'operation': 'delete',
        'payload': {'id': id, 'deleted_at': isoOrNull(now)},
        'created_at': isoOrNull(now),
        'attempts': 0,
      });
    }
    sync.requestSync();
  }
}
