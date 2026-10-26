import 'package:dompetektif/core/config/app_config.dart';
import 'package:dompetektif/data/datasources/local_store.dart';
import 'package:dompetektif/data/mappers/entity_mappers.dart';
import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';
import 'package:dompetektif/domain/services/receipt_parser.dart';

/// Creates a believable investigation in local storage so the app can be
/// evaluated without Supabase credentials. It runs once per seed version.
class DemoSeeder {
  DemoSeeder(this._store);

  final LocalStore _store;
  final DateTime _now = DateTime.now();

  static const _seedVersion = '2026-10-v1';

  Future<void> seedIfNeeded() async {
    if (_store.getMeta('seed_version') == _seedVersion &&
        _store.all('wallets').isNotEmpty) {
      return;
    }

    final now = _now;
    final categories = _categories(now);
    final categoryById = {
      for (final category in categories) category.id: category,
    };
    final wallets = _wallets(now);

    final transactions = <Transaction>[];
    final receipts = <Receipt>[];
    var txCounter = 0;
    var receiptCounter = 0;

    String nextTxId() =>
        '40000000-0000-4000-8000-${(++txCounter).toString().padLeft(12, '0')}';
    String nextReceiptId() =>
        '70000000-0000-4000-8000-${(++receiptCounter).toString().padLeft(12, '0')}';

    Transaction addTransaction({
      required String walletId,
      required TransactionType type,
      required int amount,
      required DateTime occurredAt,
      String? categoryId,
      String? toWalletId,
      String merchant = '',
      String note = '',
      String? receiptId,
      String? id,
    }) {
      final transaction = Transaction(
        id: id ?? nextTxId(),
        walletId: walletId,
        userId: AppConfig.demoUserId,
        type: type,
        amount: Money(amount),
        categoryId: categoryId,
        toWalletId: toWalletId,
        occurredAt: occurredAt,
        note: note,
        merchant: merchant,
        receiptId: receiptId,
        createdAt: occurredAt,
        updatedAt: occurredAt,
      );
      transactions.add(transaction);
      return transaction;
    }

    DateTime currentAgo(int daysAgo, int hour, [int minute = 0]) {
      final candidate = now.subtract(Duration(days: daysAgo));
      if (candidate.month != now.month || candidate.year != now.year) {
        return DateTime(now.year, now.month, 1, hour, minute);
      }
      return DateTime(
        candidate.year,
        candidate.month,
        candidate.day,
        hour,
        minute,
      );
    }

    DateTime monthDay(int monthsAgo, int day, int hour, [int minute = 0]) {
      final base = DateTime(now.year, now.month - monthsAgo, 1);
      final lastDay = DateTime(base.year, base.month + 1, 0).day;
      final safeDay = day > lastDay ? lastDay : day;
      return DateTime(base.year, base.month, safeDay, hour, minute);
    }

    // Three months of history give the anomaly detector something to compare.
    for (final monthsAgo in [2, 1]) {
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.income,
        amount: 18500000,
        occurredAt: monthDay(monthsAgo, 25, 9),
        categoryId: DefaultCategories.salaryId,
        merchant: 'Gaji Bulanan',
        note: 'Transfer payroll',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.expense,
        amount: 450000,
        occurredAt: monthDay(monthsAgo, 1, 8),
        categoryId: DefaultCategories.billsId,
        merchant: 'PLN',
        note: 'Token listrik',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.expense,
        amount: 385000,
        occurredAt: monthDay(monthsAgo, 1, 9),
        categoryId: DefaultCategories.billsId,
        merchant: 'IndiHome',
        note: 'Internet rumah',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000003',
        type: TransactionType.expense,
        amount: 186000,
        occurredAt: monthDay(monthsAgo, 4, 19),
        categoryId: DefaultCategories.entertainmentId,
        merchant: 'Netflix',
        note: 'Langganan bulanan',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 48000,
        occurredAt: monthDay(monthsAgo, 2, 8),
        categoryId: DefaultCategories.foodId,
        merchant: 'Kopi Kenangan',
        note: 'Kopi pagi',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 127500,
        occurredAt: monthDay(monthsAgo, 5, 18),
        categoryId: DefaultCategories.foodId,
        merchant: 'Indomaret',
        note: 'Belanja mingguan',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 85000,
        occurredAt: monthDay(monthsAgo, 9, 12),
        categoryId: DefaultCategories.foodId,
        merchant: 'GoFood',
        note: 'Makan siang',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 65000,
        occurredAt: monthDay(monthsAgo, 12, 19),
        categoryId: DefaultCategories.foodId,
        merchant: 'Warung Bu Tini',
        note: 'Makan malam',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 52000,
        occurredAt: monthDay(monthsAgo, 16, 8),
        categoryId: DefaultCategories.foodId,
        merchant: 'Kopi Kenangan',
        note: 'Kopi pagi',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 310000,
        occurredAt: monthDay(monthsAgo, 20, 17),
        categoryId: DefaultCategories.foodId,
        merchant: 'Superindo',
        note: 'Belanja bulanan',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 200000,
        occurredAt: monthDay(monthsAgo, 23, 20),
        categoryId: DefaultCategories.foodId,
        merchant: 'Bakery',
        note: 'Kue untuk rapat',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 120000,
        occurredAt: monthDay(monthsAgo, 26, 21),
        categoryId: DefaultCategories.foodId,
        merchant: 'GoFood',
        note: 'Makan malam',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 35000,
        occurredAt: monthDay(monthsAgo, 3, 8),
        categoryId: DefaultCategories.transportId,
        merchant: 'Gojek',
        note: 'Ke kantor',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.expense,
        amount: 250000,
        occurredAt: monthDay(monthsAgo, 8, 18),
        categoryId: DefaultCategories.transportId,
        merchant: 'Pertamina',
        note: 'Isi bensin',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000003',
        type: TransactionType.expense,
        amount: 28000,
        occurredAt: monthDay(monthsAgo, 14, 9),
        categoryId: DefaultCategories.transportId,
        merchant: 'Gojek',
        note: 'Perjalanan singkat',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 75000,
        occurredAt: monthDay(monthsAgo, 21, 7),
        categoryId: DefaultCategories.transportId,
        merchant: 'Parkir',
        note: 'Parkir gedung',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.expense,
        amount: 450000,
        occurredAt: monthDay(monthsAgo, 6, 13),
        categoryId: DefaultCategories.shoppingId,
        merchant: 'Shopee',
        note: 'Peralatan rumah',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.expense,
        amount: 499000,
        occurredAt: monthDay(monthsAgo, 18, 15),
        categoryId: DefaultCategories.shoppingId,
        merchant: 'Uniqlo',
        note: 'Baju kerja',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.expense,
        amount: 150000,
        occurredAt: monthDay(monthsAgo, 10, 11),
        categoryId: DefaultCategories.billsId,
        merchant: 'Telkomsel',
        note: 'Pulsa dan data',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 120000,
        occurredAt: monthDay(monthsAgo, 15, 20),
        categoryId: DefaultCategories.entertainmentId,
        merchant: 'Bioskop',
        note: 'Nonton akhir pekan',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000001',
        type: TransactionType.expense,
        amount: 185000,
        occurredAt: monthDay(monthsAgo, 11, 10),
        categoryId: DefaultCategories.healthId,
        merchant: 'Apotek',
        note: 'Vitamin',
      );
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.transfer,
        amount: 500000,
        occurredAt: monthDay(monthsAgo, 7, 10),
        toWalletId: '30000000-0000-4000-8000-000000000003',
        note: 'Top up GoPay',
      );
    }

    // Current month: enough activity to make budgets, charts, and anomalies real.
    if (now.day >= 25) {
      addTransaction(
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.income,
        amount: 18500000,
        occurredAt: DateTime(now.year, now.month, 25, 9),
        categoryId: DefaultCategories.salaryId,
        merchant: 'Gaji Bulanan',
        note: 'Transfer payroll',
      );
    }

    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.income,
      amount: 4500000,
      occurredAt: currentAgo(12, 14),
      categoryId: DefaultCategories.freelanceId,
      merchant: 'Proyek Sampingan',
      note: 'Pelunasan klien',
    );

    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.expense,
      amount: 450000,
      occurredAt: currentAgo(20, 8),
      categoryId: DefaultCategories.billsId,
      merchant: 'PLN',
      note: 'Token listrik',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.expense,
      amount: 385000,
      occurredAt: currentAgo(20, 9),
      categoryId: DefaultCategories.billsId,
      merchant: 'IndiHome',
      note: 'Internet rumah',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000003',
      type: TransactionType.expense,
      amount: 186000,
      occurredAt: currentAgo(20, 19),
      categoryId: DefaultCategories.entertainmentId,
      merchant: 'Netflix',
      note: 'Langganan bulanan',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 48000,
      occurredAt: currentAgo(18, 8),
      categoryId: DefaultCategories.foodId,
      merchant: 'Kopi Kenangan',
      note: 'Kopi pagi',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 35000,
      occurredAt: currentAgo(18, 9),
      categoryId: DefaultCategories.transportId,
      merchant: 'Gojek',
      note: 'Ke kantor',
    );

    final indomaretReceiptId = nextReceiptId();
    final indomaret = addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 127500,
      occurredAt: currentAgo(18, 18),
      categoryId: DefaultCategories.foodId,
      merchant: 'Indomaret',
      note: 'Belanja mingguan',
      receiptId: indomaretReceiptId,
    );
    receipts.add(
      Receipt(
        id: indomaretReceiptId,
        ownerId: AppConfig.demoUserId,
        walletId: indomaret.walletId,
        transactionId: indomaret.id,
        merchant: 'Indomaret',
        total: Money(127500),
        occurredAt: indomaret.occurredAt,
        rawText: 'INDOMARET\nJl. Kemang Raya No. 12\n18/10/2026 18:42\nSusu UHT 2 36.000\nRoti Tawar 18.000\nKopi Sachet 25.500\nAir Mineral 12.000\nCokelat 36.000\nTotal 127.500\nTunai 150.000\nKembali 22.500',
        items: const [
          ReceiptItem(name: 'Susu UHT', quantity: 2, total: Money(36000)),
          ReceiptItem(name: 'Roti Tawar', total: Money(18000)),
          ReceiptItem(name: 'Kopi Sachet', total: Money(25500)),
          ReceiptItem(name: 'Air Mineral', total: Money(12000)),
        ],
        status: ReceiptStatus.parsed,
        createdAt: indomaret.occurredAt,
        updatedAt: indomaret.occurredAt,
      ),
    );

    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.expense,
      amount: 450000,
      occurredAt: currentAgo(16, 13),
      categoryId: DefaultCategories.shoppingId,
      merchant: 'Shopee',
      note: 'Peralatan rumah',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 185000,
      occurredAt: currentAgo(16, 10),
      categoryId: DefaultCategories.healthId,
      merchant: 'Apotek',
      note: 'Vitamin',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 85000,
      occurredAt: currentAgo(14, 12),
      categoryId: DefaultCategories.foodId,
      merchant: 'GoFood',
      note: 'Makan siang',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.expense,
      amount: 250000,
      occurredAt: currentAgo(14, 18),
      categoryId: DefaultCategories.transportId,
      merchant: 'Pertamina',
      note: 'Isi bensin',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.expense,
      amount: 499000,
      occurredAt: currentAgo(12, 15),
      categoryId: DefaultCategories.shoppingId,
      merchant: 'Uniqlo',
      note: 'Baju kerja',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 120000,
      occurredAt: currentAgo(12, 20),
      categoryId: DefaultCategories.entertainmentId,
      merchant: 'Bioskop',
      note: 'Nonton akhir pekan',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 65000,
      occurredAt: currentAgo(10, 19),
      categoryId: DefaultCategories.foodId,
      merchant: 'Warung Bu Tini',
      note: 'Makan malam',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.expense,
      amount: 150000,
      occurredAt: currentAgo(10, 11),
      categoryId: DefaultCategories.billsId,
      merchant: 'Telkomsel',
      note: 'Pulsa dan data',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 52000,
      occurredAt: currentAgo(8, 8),
      categoryId: DefaultCategories.foodId,
      merchant: 'Kopi Kenangan',
      note: 'Kopi pagi',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000003',
      type: TransactionType.expense,
      amount: 28000,
      occurredAt: currentAgo(8, 9),
      categoryId: DefaultCategories.transportId,
      merchant: 'Gojek',
      note: 'Perjalanan singkat',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 310000,
      occurredAt: currentAgo(8, 17),
      categoryId: DefaultCategories.foodId,
      merchant: 'Superindo',
      note: 'Belanja bulanan',
    );

    final konserReceiptId = nextReceiptId();
    final konser = addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.expense,
      amount: 2800000,
      occurredAt: currentAgo(6, 20),
      categoryId: DefaultCategories.entertainmentId,
      merchant: 'Konser Musik',
      note: 'Tiket konser dan merchandise',
      receiptId: konserReceiptId,
    );
    receipts.add(
      Receipt(
        id: konserReceiptId,
        ownerId: AppConfig.demoUserId,
        walletId: konser.walletId,
        transactionId: konser.id,
        merchant: 'Konser Musik',
        total: Money(2800000),
        occurredAt: konser.occurredAt,
        rawText: 'KONSER MUSIK 2026\nTiket VIP 1.500.000\nMerchandise 800.000\nMakanan 300.000\nTotal 2.600.000\nBiaya layanan 200.000\nGrand Total 2.800.000',
        items: const [
          ReceiptItem(name: 'Tiket VIP', total: Money(1500000)),
          ReceiptItem(name: 'Merchandise', total: Money(800000)),
          ReceiptItem(name: 'Makanan', total: Money(300000)),
        ],
        status: ReceiptStatus.attached,
        createdAt: konser.occurredAt,
        updatedAt: konser.occurredAt,
      ),
    );

    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.expense,
      amount: 750000,
      occurredAt: currentAgo(4, 12),
      categoryId: DefaultCategories.foodId,
      merchant: 'Katering Rapat',
      note: 'Katering untuk rapat tim',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000004',
      type: TransactionType.expense,
      amount: 1200000,
      occurredAt: currentAgo(3, 10),
      categoryId: DefaultCategories.billsId,
      merchant: 'Sewa Kantor Tim',
      note: 'Sewa ruang kerja bersama',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000004',
      type: TransactionType.expense,
      amount: 120000,
      occurredAt: currentAgo(3, 15),
      categoryId: DefaultCategories.foodId,
      merchant: 'Kopi Rapat',
      note: 'Kopi untuk rapat tim',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000004',
      type: TransactionType.expense,
      amount: 300000,
      occurredAt: currentAgo(3, 16),
      categoryId: DefaultCategories.transportId,
      merchant: 'Transport Survei',
      note: 'Transport tim ke lokasi',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 200000,
      occurredAt: currentAgo(2, 20),
      categoryId: DefaultCategories.foodId,
      merchant: 'Bakery',
      note: 'Kue untuk rapat',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 95000,
      occurredAt: currentAgo(1, 12),
      categoryId: DefaultCategories.foodId,
      merchant: 'GoFood',
      note: 'Makan siang',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000001',
      type: TransactionType.expense,
      amount: 45000,
      occurredAt: currentAgo(0, 8),
      categoryId: DefaultCategories.foodId,
      merchant: 'Kopi Kenangan',
      note: 'Kopi pagi',
    );
    addTransaction(
      walletId: '30000000-0000-4000-8000-000000000002',
      type: TransactionType.transfer,
      amount: 500000,
      occurredAt: currentAgo(7, 10),
      toWalletId: '30000000-0000-4000-8000-000000000003',
      note: 'Top up GoPay',
    );

    // Receipt without a transaction yet, so the evidence vault has a draft.
    final draftReceiptId = nextReceiptId();
    receipts.add(
      Receipt(
        id: draftReceiptId,
        ownerId: AppConfig.demoUserId,
        walletId: '30000000-0000-4000-8000-000000000001',
        merchant: 'Kopi Kenangan',
        total: Money(48000),
        occurredAt: currentAgo(18, 8),
        rawText: 'KOPI KENANGAN\nKemang\n18/10/2026 08:14\nKopi Susu Gula Aren 1 28.000\nCroissant 20.000\nTotal 48.000\nTunai 50.000\nKembali 2.000',
        items: const [
          ReceiptItem(name: 'Kopi Susu Gula Aren', total: Money(28000)),
          ReceiptItem(name: 'Croissant', total: Money(20000)),
        ],
        status: ReceiptStatus.parsed,
        createdAt: currentAgo(18, 8),
        updatedAt: currentAgo(18, 8),
      ),
    );

    final budgets = _budgets(now, categoryById);
    final recurring = _recurring(now);
    final notes = _notes(now);
    final report = _report(now);

    await _store.putMany('categories', categories.map(categoryToRow).toList());
    await _store.putMany('wallets', wallets.map(walletToRow).toList());
    await _store.putMany(
      'wallet_members',
      _members(now).map(memberToRow).toList(),
    );
    await _store.putMany(
      'transactions',
      transactions.map(transactionToRow).toList(),
    );
    await _store.putMany('budgets', budgets.map(budgetToRow).toList());
    await _store.putMany(
      'recurring_rules',
      recurring.map(recurringToRow).toList(),
    );
    await _store.putMany('receipts', receipts.map(receiptToRow).toList());
    await _store.putMany('case_notes', notes.map(caseNoteToRow).toList());
    await _store.putMany('reports', [reportToRow(report)]);
    await _store.setMeta('seed_version', _seedVersion);
  }

  List<Category> _categories(DateTime now) {
    return DefaultCategories.all
        .map(
          (template) => Category(
            id: template.id,
            ownerId: AppConfig.demoUserId,
            name: template.name,
            kind: template.kind,
            iconKey: template.iconKey,
            colorHex: template.colorHex,
            keywords: template.keywords,
            isSystem: true,
            createdAt: now.subtract(const Duration(days: 120)),
            updatedAt: now.subtract(const Duration(days: 120)),
          ),
        )
        .toList();
  }

  List<Wallet> _wallets(DateTime now) {
    return [
      Wallet(
        id: '30000000-0000-4000-8000-000000000001',
        ownerId: AppConfig.demoUserId,
        name: 'Dompet Harian',
        type: WalletType.cash,
        openingBalance: const Money(850000),
        colorHex: '#E8B84B',
        iconKey: 'wallet',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 120)),
      ),
      Wallet(
        id: '30000000-0000-4000-8000-000000000002',
        ownerId: AppConfig.demoUserId,
        name: 'BCA',
        type: WalletType.bank,
        openingBalance: const Money(12500000),
        colorHex: '#7FB6A4',
        iconKey: 'bank',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 120)),
      ),
      Wallet(
        id: '30000000-0000-4000-8000-000000000003',
        ownerId: AppConfig.demoUserId,
        name: 'GoPay',
        type: WalletType.ewallet,
        openingBalance: const Money(350000),
        colorHex: '#8CA8C9',
        iconKey: 'phone',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 120)),
      ),
      Wallet(
        id: '30000000-0000-4000-8000-000000000004',
        ownerId: AppConfig.demoUserId,
        name: 'Kas Tim Investigasi',
        type: WalletType.bank,
        openingBalance: const Money(4000000),
        colorHex: '#D98C6A',
        iconKey: 'team',
        isShared: true,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 90)),
      ),
    ];
  }

  List<WalletMember> _members(DateTime now) {
    return [
      WalletMember(
        id: 'b0000000-0000-4000-8000-000000000001',
        walletId: '30000000-0000-4000-8000-000000000001',
        userId: AppConfig.demoUserId,
        role: WalletRole.owner,
        displayName: AppConfig.demoName,
        email: AppConfig.demoEmail,
        joinedAt: now.subtract(const Duration(days: 120)),
      ),
      WalletMember(
        id: 'b0000000-0000-4000-8000-000000000002',
        walletId: '30000000-0000-4000-8000-000000000002',
        userId: AppConfig.demoUserId,
        role: WalletRole.owner,
        displayName: AppConfig.demoName,
        email: AppConfig.demoEmail,
        joinedAt: now.subtract(const Duration(days: 120)),
      ),
      WalletMember(
        id: 'b0000000-0000-4000-8000-000000000003',
        walletId: '30000000-0000-4000-8000-000000000003',
        userId: AppConfig.demoUserId,
        role: WalletRole.owner,
        displayName: AppConfig.demoName,
        email: AppConfig.demoEmail,
        joinedAt: now.subtract(const Duration(days: 120)),
      ),
      WalletMember(
        id: 'b0000000-0000-4000-8000-000000000004',
        walletId: '30000000-0000-4000-8000-000000000004',
        userId: AppConfig.demoUserId,
        role: WalletRole.owner,
        displayName: AppConfig.demoName,
        email: AppConfig.demoEmail,
        joinedAt: now.subtract(const Duration(days: 90)),
      ),
      WalletMember(
        id: 'b0000000-0000-4000-8000-000000000005',
        walletId: '30000000-0000-4000-8000-000000000004',
        userId: '00000000-0000-4000-8000-000000000002',
        role: WalletRole.editor,
        displayName: 'Rani Prameswari',
        email: 'rani@dompetektif.app',
        joinedAt: now.subtract(const Duration(days: 60)),
      ),
      WalletMember(
        id: 'b0000000-0000-4000-8000-000000000006',
        walletId: '30000000-0000-4000-8000-000000000004',
        userId: '00000000-0000-4000-8000-000000000003',
        role: WalletRole.viewer,
        displayName: 'Bagas Nugraha',
        email: 'bagas@dompetektif.app',
        joinedAt: now.subtract(const Duration(days: 42)),
      ),
    ];
  }

  List<Budget> _budgets(DateTime now, Map<String, Category> categoryById) {
    final month = DateTime(now.year, now.month);
    final entries = <(String, int)>[
      (DefaultCategories.foodId, 2000000),
      (DefaultCategories.transportId, 1000000),
      (DefaultCategories.shoppingId, 1500000),
      (DefaultCategories.billsId, 3000000),
      (DefaultCategories.entertainmentId, 800000),
      (DefaultCategories.healthId, 500000),
    ];

    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final (categoryId, amount) = entry.value;
      final category = categoryById[categoryId]!;
      return Budget(
        id: '50000000-0000-4000-8000-${(index + 1).toString().padLeft(12, '0')}',
        ownerId: AppConfig.demoUserId,
        categoryId: category.id,
        amount: Money(amount),
        month: month,
        alertThreshold: 0.8,
        createdAt: month,
        updatedAt: month,
      );
    }).toList();
  }

  List<RecurringRule> _recurring(DateTime now) {
    DateTime nextDay(int day) {
      final candidate = DateTime(now.year, now.month, day, 9);
      if (candidate.isBefore(now)) {
        return DateTime(now.year, now.month + 1, day, 9);
      }
      return candidate;
    }

    return [
      RecurringRule(
        id: '60000000-0000-4000-8000-000000000001',
        ownerId: AppConfig.demoUserId,
        walletId: '30000000-0000-4000-8000-000000000002',
        type: TransactionType.income,
        amount: const Money(18500000),
        categoryId: DefaultCategories.salaryId,
        merchant: 'Gaji Bulanan',
        note: 'Transfer payroll',
        frequency: RecurrenceFrequency.monthly,
        nextRunAt: nextDay(25),
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      RecurringRule(
        id: '60000000-0000-4000-8000-000000000002',
        ownerId: AppConfig.demoUserId,
        walletId: '30000000-0000-4000-8000-000000000003',
        type: TransactionType.expense,
        amount: const Money(186000),
        categoryId: DefaultCategories.entertainmentId,
        merchant: 'Netflix',
        note: 'Langganan bulanan',
        frequency: RecurrenceFrequency.monthly,
        nextRunAt: nextDay(2),
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      RecurringRule(
        id: '60000000-0000-4000-8000-000000000003',
        ownerId: AppConfig.demoUserId,
        walletId: '30000000-0000-4000-8000-000000000004',
        type: TransactionType.expense,
        amount: const Money(1200000),
        categoryId: DefaultCategories.billsId,
        merchant: 'Sewa Kantor Tim',
        note: 'Sewa ruang kerja bersama',
        frequency: RecurrenceFrequency.monthly,
        nextRunAt: nextDay(10),
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
    ];
  }

  List<CaseNote> _notes(DateTime now) {
    return [
      CaseNote(
        id: '80000000-0000-4000-8000-000000000001',
        walletId: '30000000-0000-4000-8000-000000000004',
        userId: '00000000-0000-4000-8000-000000000002',
        authorName: 'Rani Prameswari',
        body: 'Struk konser 2,8 juta ada di meja pantry. Nominalnya jauh di atas pola hiburan kita.',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      CaseNote(
        id: '80000000-0000-4000-8000-000000000002',
        walletId: '30000000-0000-4000-8000-000000000004',
        userId: AppConfig.demoUserId,
        authorName: AppConfig.demoName,
        body: 'Sudah kucocokkan transfer GoPay. Selisih 50 ribu ternyata biaya admin, bukan kebocoran.',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      CaseNote(
        id: '80000000-0000-4000-8000-000000000003',
        walletId: '30000000-0000-4000-8000-000000000004',
        userId: '00000000-0000-4000-8000-000000000003',
        authorName: 'Bagas Nugraha',
        body: 'Sewa kantor bulan ini sudah dibayar. Bukti transfer kutaruh di folder Barang Bukti.',
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }

  InvestigationReport _report(DateTime now) {
    final periodStart = DateTime(now.year, now.month - 1, 1);
    final periodEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    return InvestigationReport(
      id: '90000000-0000-4000-8000-000000000001',
      ownerId: AppConfig.demoUserId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      headline: 'Arus kas stabil, hiburan naik tipis',
      summary: 'Bulan lalu pengeluaran terkendali. Kenaikan kecil datang dari hiburan dan makan di luar, sementara pemasukan tetap sesuai jadwal payroll.',
      findings: const [
        ReportFinding(
          title: 'Pusat pengeluaran',
          detail: 'Makanan & Minuman menyerap 31% pengeluaran. Sebagian besar berupa kopi pagi dan pesan antar.',
          severity: FindingSeverity.warning,
        ),
        ReportFinding(
          title: 'Batas TKP aman',
          detail: 'Semua Batas TKP bulan lalu berakhir di bawah 80%, dengan margin terbesar pada Tagihan.',
          severity: FindingSeverity.info,
        ),
      ],
      anomalies: const [],
      recommendations: const [
        'Kurangi pesan antar menjadi dua kali seminggu.',
        'Pertahankan transfer otomatis ke tabungan begitu gaji masuk.',
      ],
      source: ReportSource.heuristic,
      generatedAt: periodEnd,
    );
  }
}
