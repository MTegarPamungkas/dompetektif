import 'package:dompetektif/core/utils/money_formatter.dart';
import 'package:dompetektif/domain/entities/recurring_rule.dart';
import 'package:dompetektif/domain/usecases/recurring_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyFormatter', () {
    test('formats IDR without decimals', () {
      expect(MoneyFormatter.format(1500000, localeCode: 'id'), 'Rp 1.500.000');
      expect(MoneyFormatter.format(1500000, localeCode: 'en'), 'Rp 1,500,000');
    });

    test('formats compact values for charts and cards', () {
      expect(
        MoneyFormatter.format(1250000, compact: true, localeCode: 'id'),
        'Rp 1,3 jt',
      );
      expect(
        MoneyFormatter.format(1250000, compact: true, localeCode: 'en'),
        'Rp 1.3M',
      );
    });

    test('formats two-decimal currencies', () {
      expect(
        MoneyFormatter.format(1234, currency: 'USD', localeCode: 'en'),
        'USD 12.34',
      );
    });

    test('parses Indonesian grouping and shorthand suffixes', () {
      expect(MoneyFormatter.parse('Rp 1.500.000'), 1500000);
      expect(MoneyFormatter.parse('250rb'), 250000);
      expect(MoneyFormatter.parse('1,5jt'), 1500000);
      expect(MoneyFormatter.parse('2 miliar'), 2000000000);
      expect(MoneyFormatter.parse(''), isNull);
      expect(MoneyFormatter.parse('tidak ada angka'), isNull);
    });

    test('hides sensitive amounts with bullets', () {
      expect(MoneyFormatter.format(1500000, hidden: true), '••••••');
    });
  });

  group('RunDueRecurring.advance', () {
    test('advances daily and weekly intervals', () {
      final from = DateTime(2026, 10, 26, 9, 30);
      expect(
        RunDueRecurring.advance(from, RecurrenceFrequency.daily, 3),
        DateTime(2026, 10, 29, 9, 30),
      );
      expect(
        RunDueRecurring.advance(from, RecurrenceFrequency.weekly, 2),
        DateTime(2026, 11, 9, 9, 30),
      );
    });

    test('clamps monthly runs to the last day of short months', () {
      expect(
        RunDueRecurring.advance(
          DateTime(2026, 1, 31, 8),
          RecurrenceFrequency.monthly,
          1,
        ),
        DateTime(2026, 2, 28, 8),
      );
      expect(
        RunDueRecurring.advance(
          DateTime(2028, 1, 31, 8),
          RecurrenceFrequency.monthly,
          1,
        ),
        DateTime(2028, 2, 29, 8),
      );
    });

    test('handles monthly intervals crossing a year boundary', () {
      expect(
        RunDueRecurring.advance(
          DateTime(2026, 11, 30, 7, 15),
          RecurrenceFrequency.monthly,
          3,
        ),
        DateTime(2027, 2, 28, 7, 15),
      );
    });

    test('supports yearly and invalid interval fallbacks', () {
      expect(
        RunDueRecurring.advance(
          DateTime(2024, 2, 29, 7),
          RecurrenceFrequency.yearly,
          1,
        ),
        DateTime(2025, 2, 28, 7),
      );
      expect(
        RunDueRecurring.advance(
          DateTime(2026, 10, 26),
          RecurrenceFrequency.daily,
          0,
        ),
        DateTime(2026, 10, 27),
      );
    });
  });
}
