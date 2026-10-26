import 'dart:ui';

import 'package:dompetektif/data/services/ocr_text_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reconstructOcrLayout', () {
    test('pairs two-column labels with their amounts', () {
      // ML Kit emits the label column first and the amount column afterwards,
      // even though the lines share the same vertical position.
      final lines = <OcrLine>[
        const OcrLine(
          text: 'KOPI SENJA',
          bounds: Rect.fromLTWH(40, 30, 160, 18),
        ),
        const OcrLine(
          text: 'Kopi Susu',
          bounds: Rect.fromLTWH(40, 200, 110, 18),
        ),
        const OcrLine(text: 'Subtotal', bounds: Rect.fromLTWH(40, 260, 90, 18)),
        const OcrLine(
          text: 'Total Bayar',
          bounds: Rect.fromLTWH(40, 300, 120, 18),
        ),
        const OcrLine(
          text: '1 x 25.000',
          bounds: Rect.fromLTWH(220, 200, 110, 18),
        ),
        const OcrLine(text: '25.000', bounds: Rect.fromLTWH(420, 200, 80, 18)),
        const OcrLine(text: '53.000', bounds: Rect.fromLTWH(420, 260, 80, 18)),
        const OcrLine(text: '58.300', bounds: Rect.fromLTWH(420, 300, 80, 18)),
      ];

      final text = reconstructOcrLayout(lines);

      expect(
        text,
        'KOPI SENJA\n'
        'Kopi Susu  1 x 25.000  25.000\n'
        'Subtotal  53.000\n'
        'Total Bayar  58.300',
      );
    });

    test('keeps lines in reading order when there is a single column', () {
      final lines = <OcrLine>[
        const OcrLine(
          text: 'Total 45.000',
          bounds: Rect.fromLTWH(20, 60, 200, 20),
        ),
        const OcrLine(
          text: 'KOPI SENJA',
          bounds: Rect.fromLTWH(20, 20, 160, 20),
        ),
        const OcrLine(
          text: '15/10/2026',
          bounds: Rect.fromLTWH(20, 100, 140, 20),
        ),
      ];

      expect(
        reconstructOcrLayout(lines),
        'KOPI SENJA\nTotal 45.000\n15/10/2026',
      );
    });

    test('ignores empty lines and blank input', () {
      expect(reconstructOcrLayout(const []), '');
      expect(
        reconstructOcrLayout(const [
          OcrLine(text: '   ', bounds: Rect.fromLTWH(0, 0, 10, 10)),
        ]),
        '',
      );
    });
  });
}
