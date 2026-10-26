import 'dart:async';
import 'dart:typed_data';

import 'package:dompetektif/data/datasources/cloud_gateway.dart';
import 'package:dompetektif/data/mappers/entity_mappers.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseCloudGateway implements CloudGateway {
  SupabaseCloudGateway(this._client, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final SupabaseClient _client;
  final Uuid _uuid;

  static const Map<String, String> _conflictColumns = {
    'wallet_members': 'wallet_id,user_id',
  };

  @override
  bool get isDemo => false;

  @override
  Future<void> upsert(String table, Map<String, dynamic> row) async {
    await _client.from(table).upsert(row, onConflict: _conflictColumns[table]);
  }

  @override
  Future<void> softDelete(String table, String id, DateTime updatedAt) async {
    if (table == 'wallet_members') {
      await _client.from(table).delete().eq('id', id);
      return;
    }
    final timestamp = updatedAt.toUtc().toIso8601String();
    await _client
        .from(table)
        .update({'deleted_at': timestamp, 'updated_at': timestamp})
        .eq('id', id);
  }

  @override
  Future<List<Map<String, dynamic>>> pull(
    String table, {
    DateTime? since,
    int limit = 200,
  }) async {
    var query = _client.from(table).select();
    if (since != null) {
      query = query.gt('updated_at', since.toUtc().toIso8601String());
    }
    final rows = await query.order('updated_at').limit(limit);
    return rows
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  @override
  Stream<void> watchChanges(List<String> tables) {
    return Stream.multi((controller) {
      final channel = _client.channel('dompetektif-sync-${_uuid.v4()}');
      for (final table in tables) {
        channel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (_) {
            if (!controller.isClosed) controller.add(null);
          },
        );
      }
      channel.subscribe();
      controller.onCancel = () async {
        await _client.removeChannel(channel);
      };
    });
  }

  @override
  Future<String> createInvite(String walletId) async {
    final code = await _client.rpc(
      'create_wallet_invite',
      params: {'p_wallet_id': walletId},
    );
    return code.toString();
  }

  @override
  Future<void> joinWallet(String code) async {
    await _client.rpc('join_wallet_by_code', params: {'p_code': code});
  }

  @override
  Stream<List<OnlineMember>> watchPresence(String walletId) {
    return Stream.multi((controller) {
      final channel = _client.channel('presence:wallet:$walletId');
      final currentUser = _client.auth.currentUser;

      channel.onPresenceSync((_) {
        final members = <OnlineMember>[];
        for (final state in channel.presenceState()) {
          for (final presence in state.presences) {
            final payload = presence.payload;
            final userId = payload['user_id'] as String? ?? state.key;
            if (members.any((member) => member.userId == userId)) continue;
            members.add(
              OnlineMember(
                userId: userId,
                name: payload['name'] as String? ?? 'Investigator',
                avatarUrl: payload['avatar_url'] as String?,
                isCurrentUser: userId == currentUser?.id,
              ),
            );
          }
        }
        if (!controller.isClosed) controller.add(members);
      });

      channel.subscribe((status, error) async {
        if (status == RealtimeSubscribeStatus.subscribed &&
            currentUser != null) {
          final metadata = currentUser.userMetadata ?? const {};
          await channel.track({
            'user_id': currentUser.id,
            'name':
                metadata['display_name'] ?? currentUser.email ?? 'Investigator',
            'avatar_url': metadata['avatar_url'],
          });
        }
      });

      controller.onCancel = () async {
        await _client.removeChannel(channel);
      };
    });
  }

  @override
  Future<InvestigationReport> generateReport({
    required String? walletId,
    required DateTime from,
    required DateTime to,
    required String localeCode,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError(
        'Sesi tidak ditemukan. Masuk kembali untuk memuat laporan.',
      );
    }

    final response = await _client.functions.invoke(
      'investigation-report',
      body: {
        'wallet_id': walletId,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'locale': localeCode,
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw StateError('Format laporan dari server tidak dikenali.');
    }
    final row = Map<String, dynamic>.from(data);
    row['id'] ??= _uuid.v4();
    row['owner_id'] ??= user.id;
    row['wallet_id'] ??= walletId;
    row['period_start'] ??= from.toUtc().toIso8601String();
    row['period_end'] ??= to.toUtc().toIso8601String();
    row['generated_at'] ??= DateTime.now().toUtc().toIso8601String();
    row['updated_at'] ??= row['generated_at'];
    return reportFromRow(row);
  }

  @override
  Future<String?> uploadReceipt(String receiptId, Uint8List bytes) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final path = '${user.id}/$receiptId.jpg';
    final storage = _client.storage.from('receipts');
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    return storage.createSignedUrl(path, 60 * 60 * 24 * 7);
  }
}
