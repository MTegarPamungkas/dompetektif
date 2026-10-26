import 'package:dompetektif/domain/entities/export_request.dart';
import 'package:dompetektif/domain/repositories/app_repository.dart';
import 'package:dompetektif/domain/repositories/ledger_repository.dart';
import 'package:dompetektif/domain/repositories/wallet_repository.dart';

class ExportLedger {
  const ExportLedger(this._transactions, this._wallets, this._exporter);

  final TransactionRepository _transactions;
  final WalletRepository _wallets;
  final ExportRepository _exporter;

  Future<ExportResult> call({
    required DateTime from,
    required DateTime to,
    required ExportFormat format,
    required String localeCode,
    String? walletId,
  }) async {
    final entries = await _transactions.getLedger();
    final wallet = walletId == null ? null : await _wallets.getWallet(walletId);
    final end = DateTime(to.year, to.month, to.day, 23, 59, 59, 999);
    final filtered = entries.where((entry) {
      final occurredAt = entry.transaction.occurredAt;
      if (occurredAt.isBefore(from) || occurredAt.isAfter(end)) return false;
      if (walletId != null &&
          entry.transaction.walletId != walletId &&
          entry.transaction.toWalletId != walletId) {
        return false;
      }
      return true;
    }).toList();

    return _exporter.export(
      ExportRequest(
        entries: filtered,
        periodStart: from,
        periodEnd: to,
        localeCode: localeCode,
        walletName: wallet?.name,
      ),
      format,
    );
  }
}
