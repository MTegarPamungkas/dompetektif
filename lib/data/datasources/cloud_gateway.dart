import 'dart:typed_data';

import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';

abstract interface class CloudGateway {
  bool get isDemo;

  Future<void> upsert(String table, Map<String, dynamic> row);

  Future<void> softDelete(String table, String id, DateTime updatedAt);

  Future<List<Map<String, dynamic>>> pull(
    String table, {
    DateTime? since,
    int limit = 200,
  });

  Stream<void> watchChanges(List<String> tables);

  Future<String> createInvite(String walletId);

  Future<void> joinWallet(String code);

  Stream<List<OnlineMember>> watchPresence(String walletId);

  Future<InvestigationReport> generateReport({
    required String? walletId,
    required DateTime from,
    required DateTime to,
    required String localeCode,
  });

  Future<String?> uploadReceipt(String receiptId, Uint8List bytes);
}
