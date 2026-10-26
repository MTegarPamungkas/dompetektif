import 'package:dompetektif/domain/entities/budget.dart';
import 'package:dompetektif/domain/entities/case_note.dart';
import 'package:dompetektif/data/mappers/json_helpers.dart';
import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/investigation_report.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/receipt.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/entities/wallet.dart';

Map<String, dynamic> walletToRow(Wallet wallet) => {
  'id': wallet.id,
  'owner_id': wallet.ownerId,
  'name': wallet.name,
  'type': wallet.type.name,
  'opening_balance_minor': wallet.openingBalance.amountMinor,
  'currency': wallet.openingBalance.currency,
  'color_hex': wallet.colorHex,
  'icon_key': wallet.iconKey,
  'is_shared': wallet.isShared,
  'created_at': isoOrNull(wallet.createdAt),
  'updated_at': isoOrNull(wallet.updatedAt),
  'deleted_at': isoOrNull(wallet.deletedAt),
};

Wallet walletFromRow(Map<String, dynamic> row) => Wallet(
  id: row['id'] as String,
  ownerId: row['owner_id'] as String,
  name: row['name'] as String,
  type: WalletType.fromKey(row['type'] as String?),
  openingBalance: Money(
    asInt(row['opening_balance_minor']),
    currency: row['currency'] as String? ?? 'IDR',
  ),
  colorHex: row['color_hex'] as String? ?? '#E8B84B',
  iconKey: row['icon_key'] as String? ?? 'wallet',
  isShared: row['is_shared'] as bool? ?? false,
  createdAt: asDate(row['created_at']) ?? DateTime.now(),
  updatedAt: asDate(row['updated_at']) ?? DateTime.now(),
  deletedAt: asDate(row['deleted_at']),
);

Map<String, dynamic> categoryToRow(Category category) => {
  'id': category.id,
  'owner_id': category.ownerId,
  'name': category.name,
  'kind': category.kind.name,
  'icon_key': category.iconKey,
  'color_hex': category.colorHex,
  'keywords': category.keywords,
  'is_system': category.isSystem,
  'created_at': isoOrNull(category.createdAt),
  'updated_at': isoOrNull(category.updatedAt),
  'deleted_at': isoOrNull(category.deletedAt),
};

Category categoryFromRow(Map<String, dynamic> row) => Category(
  id: row['id'] as String,
  ownerId: row['owner_id'] as String?,
  name: row['name'] as String,
  kind: CategoryKind.fromKey(row['kind'] as String?),
  iconKey: row['icon_key'] as String? ?? 'category',
  colorHex: row['color_hex'] as String? ?? '#E8B84B',
  keywords: asStringList(row['keywords']),
  isSystem: row['is_system'] as bool? ?? false,
  createdAt: asDate(row['created_at']) ?? DateTime.now(),
  updatedAt: asDate(row['updated_at']) ?? DateTime.now(),
  deletedAt: asDate(row['deleted_at']),
);

Map<String, dynamic> transactionToRow(Transaction transaction) => {
  'id': transaction.id,
  'wallet_id': transaction.walletId,
  'user_id': transaction.userId,
  'type': transaction.type.name,
  'amount_minor': transaction.amount.amountMinor,
  'currency': transaction.amount.currency,
  'category_id': transaction.categoryId,
  'to_wallet_id': transaction.toWalletId,
  'occurred_at': isoOrNull(transaction.occurredAt),
  'note': transaction.note,
  'merchant': transaction.merchant,
  'receipt_id': transaction.receiptId,
  'recurring_rule_id': transaction.recurringRuleId,
  'created_at': isoOrNull(transaction.createdAt),
  'updated_at': isoOrNull(transaction.updatedAt),
  'deleted_at': isoOrNull(transaction.deletedAt),
};

Transaction transactionFromRow(Map<String, dynamic> row) => Transaction(
  id: row['id'] as String,
  walletId: row['wallet_id'] as String,
  userId: row['user_id'] as String,
  type: TransactionType.fromKey(row['type'] as String?),
  amount: Money(
    asInt(row['amount_minor']),
    currency: row['currency'] as String? ?? 'IDR',
  ),
  categoryId: row['category_id'] as String?,
  toWalletId: row['to_wallet_id'] as String?,
  occurredAt: asDate(row['occurred_at']) ?? DateTime.now(),
  note: row['note'] as String? ?? '',
  merchant: row['merchant'] as String? ?? '',
  receiptId: row['receipt_id'] as String?,
  recurringRuleId: row['recurring_rule_id'] as String?,
  createdAt: asDate(row['created_at']) ?? DateTime.now(),
  updatedAt: asDate(row['updated_at']) ?? DateTime.now(),
  deletedAt: asDate(row['deleted_at']),
  isPending: row['is_pending'] as bool? ?? false,
);

Map<String, dynamic> budgetToRow(Budget budget) => {
  'id': budget.id,
  'owner_id': budget.ownerId,
  'wallet_id': budget.walletId,
  'category_id': budget.categoryId,
  'amount_minor': budget.amount.amountMinor,
  'currency': budget.amount.currency,
  'month': dateOnly(budget.month),
  'alert_threshold': budget.alertThreshold,
  'created_at': isoOrNull(budget.createdAt),
  'updated_at': isoOrNull(budget.updatedAt),
  'deleted_at': isoOrNull(budget.deletedAt),
};

Budget budgetFromRow(Map<String, dynamic> row) => Budget(
  id: row['id'] as String,
  ownerId: row['owner_id'] as String,
  walletId: row['wallet_id'] as String?,
  categoryId: row['category_id'] as String,
  amount: Money(
    asInt(row['amount_minor']),
    currency: row['currency'] as String? ?? 'IDR',
  ),
  month: asDate(row['month']) ?? DateTime.now(),
  alertThreshold: asDouble(row['alert_threshold'], fallback: 0.8),
  createdAt: asDate(row['created_at']) ?? DateTime.now(),
  updatedAt: asDate(row['updated_at']) ?? DateTime.now(),
  deletedAt: asDate(row['deleted_at']),
);

Map<String, dynamic> recurringToRow(RecurringRule rule) => {
  'id': rule.id,
  'owner_id': rule.ownerId,
  'wallet_id': rule.walletId,
  'type': rule.type.name,
  'amount_minor': rule.amount.amountMinor,
  'currency': rule.amount.currency,
  'category_id': rule.categoryId,
  'to_wallet_id': rule.toWalletId,
  'note': rule.note,
  'merchant': rule.merchant,
  'frequency': rule.frequency.name,
  'interval': rule.interval,
  'next_run_at': isoOrNull(rule.nextRunAt),
  'end_at': isoOrNull(rule.endAt),
  'is_active': rule.isActive,
  'created_at': isoOrNull(rule.createdAt),
  'updated_at': isoOrNull(rule.updatedAt),
  'deleted_at': isoOrNull(rule.deletedAt),
};

RecurringRule recurringFromRow(Map<String, dynamic> row) => RecurringRule(
  id: row['id'] as String,
  ownerId: row['owner_id'] as String,
  walletId: row['wallet_id'] as String,
  type: TransactionType.fromKey(row['type'] as String?),
  amount: Money(
    asInt(row['amount_minor']),
    currency: row['currency'] as String? ?? 'IDR',
  ),
  categoryId: row['category_id'] as String?,
  toWalletId: row['to_wallet_id'] as String?,
  note: row['note'] as String? ?? '',
  merchant: row['merchant'] as String? ?? '',
  frequency: RecurrenceFrequency.fromKey(row['frequency'] as String?),
  interval: asInt(row['interval'], fallback: 1),
  nextRunAt: asDate(row['next_run_at']) ?? DateTime.now(),
  endAt: asDate(row['end_at']),
  isActive: row['is_active'] as bool? ?? true,
  createdAt: asDate(row['created_at']) ?? DateTime.now(),
  updatedAt: asDate(row['updated_at']) ?? DateTime.now(),
  deletedAt: asDate(row['deleted_at']),
);

Map<String, dynamic> caseNoteToRow(CaseNote note) => {
  'id': note.id,
  'wallet_id': note.walletId,
  'transaction_id': note.transactionId,
  'user_id': note.userId,
  'author_name': note.authorName,
  'avatar_url': note.avatarUrl,
  'body': note.body,
  'created_at': isoOrNull(note.createdAt),
  'updated_at': isoOrNull(note.updatedAt),
  'deleted_at': isoOrNull(note.deletedAt),
};

CaseNote caseNoteFromRow(Map<String, dynamic> row) => CaseNote(
  id: row['id'] as String,
  walletId: row['wallet_id'] as String,
  transactionId: row['transaction_id'] as String?,
  userId: row['user_id'] as String,
  authorName: row['author_name'] as String? ?? 'Investigator',
  avatarUrl: row['avatar_url'] as String?,
  body: row['body'] as String? ?? '',
  createdAt: asDate(row['created_at']) ?? DateTime.now(),
  updatedAt: asDate(row['updated_at']) ?? DateTime.now(),
  deletedAt: asDate(row['deleted_at']),
  isPending: row['is_pending'] as bool? ?? false,
);

Map<String, dynamic> receiptToRow(Receipt receipt) => {
  'id': receipt.id,
  'owner_id': receipt.ownerId,
  'wallet_id': receipt.walletId,
  'transaction_id': receipt.transactionId,
  'merchant': receipt.merchant,
  'total_minor': receipt.total.amountMinor,
  'currency': receipt.total.currency,
  'occurred_at': isoOrNull(receipt.occurredAt),
  'raw_text': receipt.rawText,
  'items': receipt.items
      .map(
        (item) => {
          'name': item.name,
          'quantity': item.quantity,
          'total_minor': item.total.amountMinor,
          'currency': item.total.currency,
        },
      )
      .toList(),
  'image_key': receipt.imageKey,
  'remote_image_url': receipt.remoteImageUrl,
  'status': receipt.status.name,
  'created_at': isoOrNull(receipt.createdAt),
  'updated_at': isoOrNull(receipt.updatedAt),
  'deleted_at': isoOrNull(receipt.deletedAt),
};

Receipt receiptFromRow(Map<String, dynamic> row) => Receipt(
  id: row['id'] as String,
  ownerId: row['owner_id'] as String,
  walletId: row['wallet_id'] as String?,
  transactionId: row['transaction_id'] as String?,
  merchant: row['merchant'] as String? ?? '',
  total: Money(
    asInt(row['total_minor']),
    currency: row['currency'] as String? ?? 'IDR',
  ),
  occurredAt: asDate(row['occurred_at']) ?? DateTime.now(),
  rawText: row['raw_text'] as String? ?? '',
  items: (row['items'] as List? ?? [])
      .whereType<Map>()
      .map(
        (item) => ReceiptItem(
          name: item['name'] as String? ?? '',
          quantity: asInt(item['quantity'], fallback: 1),
          total: Money(
            asInt(item['total_minor']),
            currency: item['currency'] as String? ?? 'IDR',
          ),
        ),
      )
      .toList(),
  imageKey: row['image_key'] as String?,
  remoteImageUrl: row['remote_image_url'] as String?,
  status: ReceiptStatus.fromKey(row['status'] as String?),
  createdAt: asDate(row['created_at']) ?? DateTime.now(),
  updatedAt: asDate(row['updated_at']) ?? DateTime.now(),
  deletedAt: asDate(row['deleted_at']),
);

Map<String, dynamic> reportToRow(InvestigationReport report) => {
  'id': report.id,
  'owner_id': report.ownerId,
  'wallet_id': report.walletId,
  'period_start': isoOrNull(report.periodStart),
  'period_end': isoOrNull(report.periodEnd),
  'headline': report.headline,
  'summary': report.summary,
  'findings': report.findings
      .map(
        (finding) => {
          'title': finding.title,
          'detail': finding.detail,
          'severity': finding.severity.name,
        },
      )
      .toList(),
  'anomalies': report.anomalies
      .map(
        (anomaly) => {
          'title': anomaly.title,
          'detail': anomaly.detail,
          'transaction_id': anomaly.transactionId,
          'amount_minor': anomaly.amount?.amountMinor,
          'currency': anomaly.amount?.currency,
          'severity': anomaly.severity.name,
        },
      )
      .toList(),
  'recommendations': report.recommendations,
  'source': report.source.name,
  'generated_at': isoOrNull(report.generatedAt),
  'updated_at': isoOrNull(report.generatedAt),
};

InvestigationReport reportFromRow(Map<String, dynamic> row) =>
    InvestigationReport(
      id: row['id'] as String,
      ownerId: row['owner_id'] as String,
      walletId: row['wallet_id'] as String?,
      periodStart: asDate(row['period_start']) ?? DateTime.now(),
      periodEnd: asDate(row['period_end']) ?? DateTime.now(),
      headline: row['headline'] as String? ?? '',
      summary: row['summary'] as String? ?? '',
      findings: (row['findings'] as List? ?? [])
          .whereType<Map>()
          .map(
            (finding) => ReportFinding(
              title: finding['title'] as String? ?? '',
              detail: finding['detail'] as String? ?? '',
              severity: FindingSeverity.fromKey(finding['severity'] as String?),
            ),
          )
          .toList(),
      anomalies: (row['anomalies'] as List? ?? [])
          .whereType<Map>()
          .map(
            (anomaly) => ReportAnomaly(
              title: anomaly['title'] as String? ?? '',
              detail: anomaly['detail'] as String? ?? '',
              transactionId: anomaly['transaction_id'] as String?,
              amount: anomaly['amount_minor'] == null
                  ? null
                  : Money(
                      asInt(anomaly['amount_minor']),
                      currency: anomaly['currency'] as String? ?? 'IDR',
                    ),
              severity: FindingSeverity.fromKey(anomaly['severity'] as String?),
            ),
          )
          .toList(),
      recommendations: asStringList(row['recommendations']),
      source: ReportSource.fromKey(row['source'] as String?),
      generatedAt: asDate(row['generated_at']) ?? DateTime.now(),
    );

Map<String, dynamic> memberToRow(WalletMember member) => {
  'id': member.id,
  'wallet_id': member.walletId,
  'user_id': member.userId,
  'role': member.role.name,
  'display_name': member.displayName,
  'email': member.email,
  'avatar_url': member.avatarUrl,
  'joined_at': isoOrNull(member.joinedAt),
  'updated_at': isoOrNull(member.joinedAt ?? DateTime.now()),
};

WalletMember memberFromRow(Map<String, dynamic> row) => WalletMember(
  id: row['id'] as String? ?? '${row['wallet_id']}_${row['user_id']}',
  walletId: row['wallet_id'] as String,
  userId: row['user_id'] as String,
  role: WalletRole.fromKey(row['role'] as String?),
  displayName: row['display_name'] as String? ?? 'Investigator',
  email: row['email'] as String? ?? '',
  avatarUrl: row['avatar_url'] as String?,
  joinedAt: asDate(row['joined_at']),
);
