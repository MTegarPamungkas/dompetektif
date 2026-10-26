import 'dart:math' as math;
import 'dart:ui';

/// One OCR line together with its position in the captured image.
class OcrLine {
  const OcrLine({required this.text, required this.bounds});

  final String text;
  final Rect bounds;
}

/// Restores a left-to-right, top-to-bottom reading order from ML Kit blocks.
///
/// ML Kit groups recognized lines into blocks by proximity. Receipts are
/// printed in columns, so a two-column receipt often comes back as one block of
/// labels ("Subtotal", "Total Bayar", ...) followed by another block holding
/// the amount column. Concatenating the blocks in order destroys the
/// label/value pairs and the parser then reads a nota or date number as the
/// total.
///
/// Grouping every line by its vertical position and sorting each row by its
/// horizontal position restores lines such as `Total Bayar   58.300`, which is
/// what the deterministic parser expects.
String reconstructOcrLayout(Iterable<OcrLine> lines) {
  final fragments = lines
      .map((line) => OcrLine(text: line.text.trim(), bounds: line.bounds))
      .where((line) => line.text.isNotEmpty)
      .toList(growable: false);
  if (fragments.isEmpty) return '';

  final sorted = [...fragments]
    ..sort((a, b) {
      final byTop = a.bounds.top.compareTo(b.bounds.top);
      return byTop != 0 ? byTop : a.bounds.left.compareTo(b.bounds.left);
    });

  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    List<OcrLine>? row;
    for (final candidate in rows) {
      if (candidate.any((other) => _sameRow(other.bounds, line.bounds))) {
        row = candidate;
        break;
      }
    }
    if (row == null) {
      rows.add([line]);
    } else {
      row.add(line);
    }
  }

  rows.sort((a, b) => _rowTop(a).compareTo(_rowTop(b)));

  final buffer = StringBuffer();
  for (final row in rows) {
    row.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
    final text = row.map((line) => line.text).join('  ');
    buffer.writeln(text);
  }
  return buffer.toString().trim();
}

double _rowTop(List<OcrLine> row) =>
    row.map((line) => line.bounds.top).reduce(math.min);

/// Whether two lines belong to the same visual row.
///
/// Real receipt lines overlap vertically even when their font sizes differ, so
/// a proportional overlap check handles most cases. Very short fragments (the
/// amount column) are additionally matched by centre proximity.
bool _sameRow(Rect a, Rect b) {
  final overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
  final shortest = math.min(a.height, b.height);
  if (overlap > 0 && shortest > 0 && overlap >= shortest * 0.45) return true;

  final tallest = math.max(a.height, b.height);
  if (tallest <= 0) return false;
  return (a.center.dy - b.center.dy).abs() <= tallest * 0.35;
}
