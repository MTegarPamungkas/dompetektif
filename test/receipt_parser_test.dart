import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/services/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptParser();

  group('ReceiptParser', () {
    test(
      'extracts merchant, total, date, and line items from an ID receipt',
      () {
        const raw = '''
KOPI KENANGAN
Jl. Senopati No. 12
Tanggal 18/10/2026 14:32
Kopi Susu Gula Aren 2 x 28.000   56.000
Croissant Butter                 32.000
Subtotal                         88.000
Pajak 11%                         9.680
Total bayar                      97.680
QRIS
Terima kasih
''';

        final parsed = parser.parse(raw);

        expect(parsed.merchant, 'Kopi Kenangan');
        expect(parsed.total?.amountMinor, 97680);
        expect(parsed.occurredAt, DateTime(2026, 10, 18));
        expect(parsed.items, isNotEmpty);
        expect(parsed.items.first.quantity, 2);
        expect(parsed.confidence, greaterThanOrEqualTo(0.8));
      },
    );

    test('prefers an explicit grand total over smaller line amounts', () {
      const raw = '''
TOKO BANGUNAN JAYA
Semen 50kg        1 x 75.000    75.000
Pasir             2 x 40.000    80.000
GRAND TOTAL                    155.000
''';

      final parsed = parser.parse(raw);

      expect(parsed.total?.amountMinor, 155000);
    });

    test('handles empty and unstructured OCR text without throwing', () {
      expect(parser.parse('').merchant, isNull);
      expect(parser.parse('   \n \n ').total, isNull);

      final unstructured = parser.parse('nota lama tanpa angka');
      expect(unstructured.rawText, 'nota lama tanpa angka');
      expect(unstructured.total, isNull);
    });
  });

  group('CategoryClassifier', () {
    final now = DateTime(2026, 10, 1);
    final categories = DefaultCategories.all
        .map(
          (template) => Category(
            id: template.id,
            name: template.name,
            kind: template.kind,
            iconKey: template.iconKey,
            colorHex: template.colorHex,
            keywords: template.keywords,
            isSystem: true,
            createdAt: now,
            updatedAt: now,
          ),
        )
        .toList();
    const classifier = CategoryClassifier();

    test('classifies a coffee merchant as food & drinks', () {
      final category = classifier.classify(
        text: 'Kopi Kenangan Senopati',
        categories: categories,
      );

      expect(category?.id, DefaultCategories.foodId);
    });

    test('classifies transport and bills from keywords', () {
      expect(
        classifier
            .classify(text: 'GOJEK trip to office', categories: categories)
            ?.id,
        DefaultCategories.transportId,
      );
      expect(
        classifier
            .classify(
              text: 'Tagihan IndiHome bulan Oktober',
              categories: categories,
            )
            ?.id,
        DefaultCategories.billsId,
      );
    });

    test('falls back to the uncategorized expense bucket', () {
      final category = classifier.classify(
        text: 'Sesuatu yang tidak dikenal',
        categories: categories,
      );

      expect(category?.id, DefaultCategories.otherExpenseId);
    });
  });
}
