import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/entities/transaction.dart';
import 'package:dompetektif/domain/repositories/ledger_repository.dart';
import 'package:dompetektif/domain/services/device_services.dart';
import 'package:uuid/uuid.dart';

class WatchRecurringRules {
  const WatchRecurringRules(this._repository);

  final RecurringRepository _repository;

  Stream<List<RecurringRule>> call() => _repository.watchRules();
}

class SaveRecurringRule {
  const SaveRecurringRule(this._repository);

  final RecurringRepository _repository;

  Future<void> call(RecurringRule rule) => _repository.saveRule(rule);
}

class DeleteRecurringRule {
  const DeleteRecurringRule(this._repository);

  final RecurringRepository _repository;

  Future<void> call(String id) => _repository.deleteRule(id);
}

class RunDueRecurring {
  RunDueRecurring(
    this._rules,
    this._transactions,
    this._notifications, {
    Uuid uuid = const Uuid(),
  }) : _uuid = uuid;

  final RecurringRepository _rules;
  final TransactionRepository _transactions;
  final NotificationService _notifications;
  final Uuid _uuid;

  Future<int> call({DateTime? now}) async {
    final anchor = now ?? DateTime.now();
    final rules = await _rules.getRules();
    var created = 0;

    for (final rule in rules) {
      if (rule.isDeleted || !rule.isActive) continue;
      if (rule.nextRunAt.isAfter(anchor)) continue;

      var next = rule.nextRunAt;
      var guard = 0;
      while (!next.isAfter(anchor) && guard < 36) {
        if (rule.endAt != null && next.isAfter(rule.endAt!)) break;
        await _transactions.saveTransaction(
          Transaction(
            id: _uuid.v4(),
            walletId: rule.walletId,
            userId: rule.ownerId,
            type: rule.type,
            amount: rule.amount,
            categoryId: rule.type == TransactionType.transfer
                ? null
                : rule.categoryId,
            toWalletId: rule.type == TransactionType.transfer
                ? rule.toWalletId
                : null,
            occurredAt: next,
            note: rule.note,
            merchant: rule.merchant,
            recurringRuleId: rule.id,
            createdAt: anchor,
            updatedAt: anchor,
          ),
        );
        created++;
        next = advance(next, rule.frequency, rule.interval);
        guard++;
      }

      final expired = rule.endAt != null && next.isAfter(rule.endAt!);
      await _rules.saveRule(rule.copyWith(nextRunAt: next, isActive: !expired));

      if (!expired) {
        await _notifications.scheduleRecurringReminder(
          id: rule.id.hashCode & 0x7fffffff,
          title: rule.merchant.trim().isEmpty ? rule.note : rule.merchant,
          body: 'Transaksi berulang dijadwalkan pada ${next.toIso8601String()}',
          when: next,
        );
      }
    }

    return created;
  }

  static DateTime advance(
    DateTime from,
    RecurrenceFrequency frequency,
    int interval,
  ) {
    final safeInterval = interval < 1 ? 1 : interval;
    return switch (frequency) {
      RecurrenceFrequency.daily => from.add(Duration(days: safeInterval)),
      RecurrenceFrequency.weekly => from.add(Duration(days: 7 * safeInterval)),
      RecurrenceFrequency.monthly => _addMonths(from, safeInterval),
      RecurrenceFrequency.yearly => _addMonths(from, 12 * safeInterval),
    };
  }

  static DateTime _addMonths(DateTime from, int months) {
    final targetMonth = from.month - 1 + months;
    final year = from.year + targetMonth ~/ 12;
    final month = targetMonth % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = from.day > lastDay ? lastDay : from.day;
    return DateTime(
      year,
      month,
      day,
      from.hour,
      from.minute,
      from.second,
      from.millisecond,
      from.microsecond,
    );
  }
}
