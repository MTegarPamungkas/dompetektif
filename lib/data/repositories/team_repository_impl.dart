import 'package:dompetektif/data/datasources/cloud_gateway.dart';
import 'package:dompetektif/data/mappers/entity_mappers.dart';
import 'package:dompetektif/data/repositories/local_repository_base.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/repositories/wallet_repository.dart';

class TeamRepositoryImpl extends LocalRepositoryBase implements TeamRepository {
  TeamRepositoryImpl(super.store, super.sync, super.auth, this._gateway);

  final CloudGateway _gateway;

  @override
  Stream<List<WalletMember>> watchMembers(String walletId) {
    return store.watch('wallet_members').map((rows) {
      final members =
          rows
              .where((row) => row['wallet_id'] == walletId)
              .map(memberFromRow)
              .toList()
            ..sort((a, b) {
              if (a.role != b.role) return a.role.index.compareTo(b.role.index);
              return a.displayName.compareTo(b.displayName);
            });
      return members;
    });
  }

  @override
  Stream<List<CaseNote>> watchNotes(String walletId) {
    return store.watch('case_notes').map((rows) {
      final notes =
          rows
              .where((row) => row['wallet_id'] == walletId)
              .map(caseNoteFromRow)
              .where((note) => !note.isDeleted)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return notes;
    });
  }

  @override
  Stream<List<CaseNote>> watchAllNotes() {
    return store.watch('case_notes').map((rows) {
      final notes =
          rows.map(caseNoteFromRow).where((note) => !note.isDeleted).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notes;
    });
  }

  @override
  Stream<List<OnlineMember>> watchPresence(String walletId) =>
      _gateway.watchPresence(walletId);

  @override
  Future<void> sendNote(CaseNote note) async {
    if (note.body.trim().isEmpty) {
      throw ArgumentError('Pesan tidak boleh kosong.');
    }
    final now = DateTime.now();
    final updated = note.copyWith(
      body: note.body.trim(),
      createdAt: note.createdAt,
      updatedAt: now,
    );
    await upsertRow('case_notes', caseNoteToRow(updated), updatedAt: now);
  }

  @override
  Future<String> createInvite(String walletId) =>
      _gateway.createInvite(walletId);

  @override
  Future<void> joinWallet(String code) async {
    await _gateway.joinWallet(code.trim().toUpperCase());
    sync.requestSync();
  }
}
