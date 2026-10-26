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

    test('reads a two-column receipt with labels and amounts lined up', () {
      // This is the reading order produced by reconstructOcrLayout for a photo
      // whose columns ML Kit recognized as separate blocks.
      const raw = '''
KOPI SENJA
Jl. Contoh No. 123, Jakarta
Telp: 0812-3456-7890
NPWP:
01.234.567.8-901.000
Tanggal : 15/10/2026 19:42
Kasir : Andi
No. Nota: 20261015-0042
Kopi Susu  1 x 25.000  25.000
Roti Bakar  1 x 20.000  20.000
Air Mineral  1 x 8.000  8.000
Subtotal  53.000
Pajak 10%  5.300
Total Bayar  58.300
Tunai  60.000
Kembali  1.700
Terima kasih atas kunjungan Anda
''';

      final parsed = parser.parse(raw);

      expect(parsed.merchant, 'Kopi Senja');
      expect(parsed.total?.amountMinor, 58300);
      expect(parsed.occurredAt, DateTime(2026, 10, 15));
      expect(parsed.items.map((item) => item.name), [
        'Kopi Susu',
        'Roti Bakar',
        'Air Mineral',
      ]);
    });

    test('never treats phone, NPWP, or nota numbers as money', () {
      const raw = '''
TOKO MAKMUR
Telp: 0812-3456-7890
NPWP: 01.234.567.8-901.000
No. Nota: 20261015-0042
Total 45.000
''';

      final parsed = parser.parse(raw);

      expect(parsed.total?.amountMinor, 45000);
      expect(
        parsed.items.where((item) => item.name.toLowerCase().contains('telp')),
        isEmpty,
      );
    });

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

    test('repeated receipt words beat a single utility keyword', () {
      // Alphabetical order would otherwise let "Bills" win a tie because
      // "air" (the water utility keyword) appears in "Air Mineral".
      final alphabetical = [...categories]
        ..sort((a, b) => a.name.compareTo(b.name));

      final category = classifier.classify(
        text: 'Kopi Senja Kopi Susu Roti Bakar Air Mineral',
        categories: alphabetical,
      );

      expect(category?.id, DefaultCategories.foodId);
    });
  });
}
