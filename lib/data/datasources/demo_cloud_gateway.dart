import 'dart:async';
import 'dart:typed_data';

import 'package:dompetektif/core/config/app_config.dart';
import 'package:dompetektif/core/utils/case_dates.dart';
import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/data/datasources/cloud_gateway.dart';
import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/data/mappers/entity_mappers.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/dashboard_data.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/usecases/ledger_analytics.dart';
import 'package:uuid/uuid.dart';

/// The local-only gateway used when Supabase credentials are absent.
///
/// It preserves the same contracts as the cloud gateway, so switching to
/// Supabase only changes composition in the DI container.
class DemoCloudGateway implements CloudGateway {
  DemoCloudGateway(this._store, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  final LocalStore _store;
  final Uuid _uuid;

  @override
  bool get isDemo => true;

  @override
  Future<void> upsert(String table, Map<String, dynamic> row) async {}

  @override
  Future<void> softDelete(String table, String id, DateTime updatedAt) async {}

  @override
  Future<List<Map<String, dynamic>>> pull(
    String table, {
    DateTime? since,
    int limit = 200,
  }) async => const [];

  @override
  Stream<void> watchChanges(List<String> tables) => const Stream.empty();

  @override
  Future<String> createInvite(String walletId) async {
    final suffix = walletId.replaceAll('-', '').substring(0, 6).toUpperCase();
    return 'DEMO-$suffix';
  }

  @override
  Future<void> joinWallet(String code) async {
    throw UnsupportedError(
      'Kode undangan hanya aktif saat Supabase terhubung.',
    );
  }

  @override
  Stream<List<OnlineMember>> watchPresence(String walletId) {
    return Stream.value([
      const OnlineMember(
        userId: AppConfig.demoUserId,
        name: AppConfig.demoName,
        isCurrentUser: true,
      ),
      const OnlineMember(
        userId: '00000000-0000-4000-8000-000000000002',
        name: 'Rani Prameswari',
      ),
    ]);
  }

  @override
  Future<InvestigationReport> generateReport({
    required String? walletId,
    required DateTime from,
    required DateTime to,
    required String localeCode,
  }) async {
    final wallets = _store
        .all('wallets')
        .map(walletFromRow)
        .where((wallet) => !wallet.isDeleted)
        .toList();
    final categories = _store
        .all('categories')
        .map(categoryFromRow)
        .where((category) => !category.isDeleted)
        .toList();
    final transactions = _store
        .all('transactions')
        .map(transactionFromRow)
        .where((transaction) => !transaction.isDeleted)
        .toList();
    final budgets = _store
        .all('budgets')
        .map(budgetFromRow)
        .where((budget) => !budget.isDeleted)
        .toList();

    final filtered = transactions.where((transaction) {
      if (transaction.occurredAt.isBefore(from)) return false;
      if (transaction.occurredAt.isAfter(
        DateTime(to.year, to.month, to.day, 23, 59, 59, 999),
      )) {
        return false;
      }
      if (walletId != null && transaction.walletId != walletId) return false;
      return true;
    }).toList();

    const analytics = LedgerAnalytics();
    final totals = analytics.totals(
      transactions: filtered,
      month: from,
      walletId: walletId,
    );
    final categorySpend = analytics.categorySpend(
      transactions: filtered,
      categories: categories,
      month: from,
      walletId: walletId,
    );
    final progress = analytics.budgetProgress(
      budgets: budgets,
      categories: categories,
      transactions: filtered,
      month: from,
    );
    final anomalies = analytics.anomalies(
      transactions: filtered,
      wallets: wallets,
      categories: categories,
      now: from,
      walletId: walletId,
    );

    final isId = localeCode != 'en';
    final periodLabel =
        '${CaseDates.dayMonth(from, localeCode)} – ${CaseDates.dayMonth(to, localeCode)}';
    final top = categorySpend.isEmpty ? null : categorySpend.first;
    final overBudget = progress
        .where((item) => item.status == BudgetStatus.over)
        .toList();
    final warningBudget = progress
        .where((item) => item.status == BudgetStatus.warning)
        .toList();
    final biggest = filtered
        .where((transaction) => transaction.type == TransactionType.expense)
        .fold<Transaction?>(
          null,
          (current, transaction) =>
              current == null ||
                  transaction.amount.amountMinor > current.amount.amountMinor
              ? transaction
              : current,
        );

    final findings = <ReportFinding>[];
    if (top != null) {
      findings.add(
        ReportFinding(
          title: isId ? 'Pusat pengeluaran' : 'Spending hotspot',
          detail: isId
              ? '${top.category.name} menyerap ${MoneyFormatter.percent(top.ratio, localeCode: localeCode)} pengeluaran periode ini (${MoneyFormatter.format(top.amount.amountMinor, localeCode: localeCode)}).'
              : '${top.category.name} absorbed ${MoneyFormatter.percent(top.ratio, localeCode: localeCode)} of this period’s spending (${MoneyFormatter.format(top.amount.amountMinor, localeCode: localeCode)}).',
          severity: top.ratio >= 0.4
              ? FindingSeverity.warning
              : FindingSeverity.info,
        ),
      );
    }
    if (biggest != null) {
      findings.add(
        ReportFinding(
          title: isId ? 'Transaksi terbesar' : 'Largest transaction',
          detail:
              '${biggest.displayTitle.isEmpty ? (isId ? 'Tanpa judul' : 'Untitled') : biggest.displayTitle} — ${MoneyFormatter.format(biggest.amount.amountMinor, localeCode: localeCode)}.',
          severity: FindingSeverity.info,
        ),
      );
    }
    for (final item in [...overBudget, ...warningBudget].take(2)) {
      findings.add(
        ReportFinding(
          title: isId
              ? 'Batas TKP: ${item.category.name}'
              : 'Limit: ${item.category.name}',
          detail: isId
              ? 'Terpakai ${MoneyFormatter.format(item.spent.amountMinor, localeCode: localeCode)} dari ${MoneyFormatter.format(item.budget.amount.amountMinor, localeCode: localeCode)} (${MoneyFormatter.percent(item.ratio, localeCode: localeCode)}).'
              : 'Used ${MoneyFormatter.format(item.spent.amountMinor, localeCode: localeCode)} of ${MoneyFormatter.format(item.budget.amount.amountMinor, localeCode: localeCode)} (${MoneyFormatter.percent(item.ratio, localeCode: localeCode)}).',
          severity: item.status == BudgetStatus.over
              ? FindingSeverity.critical
              : FindingSeverity.warning,
        ),
      );
    }

    final anomalyModels = anomalies
        .map(
          (anomaly) => ReportAnomaly(
            title: anomaly.kind == AnomalyKind.categoryLeak
                ? (isId
                      ? 'Kebocoran di ${anomaly.categoryName ?? 'kategori'}'
                      : 'Leak in ${anomaly.categoryName ?? 'category'}')
                : (isId ? 'Nominal tidak biasa' : 'Unusual amount'),
            detail: isId
                ? '${anomaly.entry.transaction.displayTitle} ${MoneyFormatter.format(anomaly.entry.transaction.amount.amountMinor, localeCode: localeCode)} — ${anomaly.deviation.toStringAsFixed(1)}× rata-rata biasanya.'
                : '${anomaly.entry.transaction.displayTitle} ${MoneyFormatter.format(anomaly.entry.transaction.amount.amountMinor, localeCode: localeCode)} — ${anomaly.deviation.toStringAsFixed(1)}× the usual average.',
            transactionId: anomaly.entry.transaction.id,
            amount: anomaly.entry.transaction.amount,
            severity: anomaly.severity == AnomalySeverity.alert
                ? FindingSeverity.critical
                : FindingSeverity.warning,
          ),
        )
        .toList();

    final recommendations = <String>[
      if (top != null)
        isId
            ? 'Pasang batas mingguan untuk ${top.category.name} dan cek tiap Jumat.'
            : 'Set a weekly cap for ${top.category.name} and check it every Friday.',
      if (overBudget.isNotEmpty)
        isId
            ? 'Geser sisa anggaran dari kategori yang aman untuk menutup ${overBudget.first.category.name}.'
            : 'Move leftover budget from safe categories to cover ${overBudget.first.category.name}.',
      if (anomalies.isNotEmpty)
        isId
            ? 'Buka struk transaksi terbesar dan cek apakah pengeluaran itu berulang.'
            : 'Open the receipt for the largest transaction and check whether it repeats.',
      isId
          ? 'Nyalakan kunci biometrik supaya berkas tetap aman saat bepergian.'
          : 'Keep the biometric lock on so the case file stays safe on the go.',
    ];

    final headline = isId
        ? (overBudget.isEmpty
              ? 'Arus kas terkendali, satu titik perlu diawasi'
              : 'Ada ${overBudget.length} batas yang jebol')
        : (overBudget.isEmpty
              ? 'Cash flow is under control, one lead needs watching'
              : '${overBudget.length} limits went over the line');
    final summary = isId
        ? 'Dari ${filtered.length} transaksi pada $periodLabel, pemasukan ${MoneyFormatter.format(totals.income.amountMinor, localeCode: localeCode)} dan pengeluaran ${MoneyFormatter.format(totals.expense.amountMinor, localeCode: localeCode)}. Selisih bersih ${MoneyFormatter.format(totals.net.amountMinor, signed: true, localeCode: localeCode)}. Laporan ini dibuat dari data di perangkat.'
        : 'Across ${filtered.length} transactions in $periodLabel, income was ${MoneyFormatter.format(totals.income.amountMinor, localeCode: localeCode)} and spending was ${MoneyFormatter.format(totals.expense.amountMinor, localeCode: localeCode)}. Net difference ${MoneyFormatter.format(totals.net.amountMinor, signed: true, localeCode: localeCode)}. This report was built from data on your device.';

    return InvestigationReport(
      id: _uuid.v4(),
      ownerId: AppConfig.demoUserId,
      walletId: walletId,
      periodStart: from,
      periodEnd: to,
      headline: headline,
      summary: summary,
      findings: findings,
      anomalies: anomalyModels,
      recommendations: recommendations,
      source: ReportSource.heuristic,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<String?> uploadReceipt(String receiptId, Uint8List bytes) async =>
      null;
}
