import 'package:dompetektif/domain/entities/category.dart';
import 'package:dompetektif/domain/entities/money.dart';
import 'package:dompetektif/domain/entities/receipt.dart';

class ParsedReceipt {
  const ParsedReceipt({
    required this.rawText,
    this.merchant,
    this.total,
    this.occurredAt,
    this.items = const [],
    this.confidence = 0,
  });

  final String rawText;
  final String? merchant;
  final Money? total;
  final DateTime? occurredAt;
  final List<ReceiptItem> items;
  final double confidence;
}

/// Heuristic parser for Indonesian and English receipt text.
///
/// The parser is intentionally deterministic and dependency free so it can be
/// unit tested with OCR samples and tuned without touching platform code.
class ReceiptParser {
  const ReceiptParser();

  static const List<String> _totalKeywords = [
    'grand total',
    'total bayar',
    'total pembayaran',
    'total amount',
    'amount due',
    'total',
    'jumlah',
    'subtotal',
  ];

  static const List<String> _ignoredMerchantWords = [
    'struk',
    'receipt',
    'invoice',
    'nota',
    'bukti',
    'tanggal',
    'date',
    'kasir',
    'cashier',
    'npwp',
    'telp',
    'phone',
    'alamat',
    'address',
    'member',
    'no.',
    'no ',
    'terima kasih',
    'thank you',
    'selamat datang',
    'welcome',
    'qty',
    'item',
  ];

  static const List<String> _ignoredItemWords = [
    'total',
    'subtotal',
    'jumlah',
    'pajak',
    'tax',
    'service',
    'diskon',
    'discount',
    'kembali',
    'change',
    'tunai',
    'cash',
    'debit',
    'kredit',
    'credit',
    'qris',
    'ovo',
    'gopay',
    'dana',
    'shopeepay',
    'voucher',
    'ppn',
  ];

  /// Lines that carry identity data rather than money. Their long digit runs
  /// (phone numbers, nota ids, NPWP numbers) must never become totals or items.
  static const List<String> _metadataWords = [
    'telp',
    'telepon',
    'phone',
    'npwp',
    'nota',
    'invoice',
    'kasir',
    'cashier',
    'tanggal',
    'date',
    'alamat',
    'address',
    'member',
    'kode',
    'ref',
    'no.',
  ];

  static const Map<String, int> _monthNumbers = {
    'jan': 1,
    'januari': 1,
    'january': 1,
    'feb': 2,
    'februari': 2,
    'february': 2,
    'mar': 3,
    'maret': 3,
    'march': 3,
    'apr': 4,
    'april': 4,
    'mei': 5,
    'may': 5,
    'jun': 6,
    'juni': 6,
    'june': 6,
    'jul': 7,
    'juli': 7,
    'july': 7,
    'agu': 8,
    'agt': 8,
    'agustus': 8,
    'august': 8,
    'aug': 8,
    'sep': 9,
    'september': 9,
    'okt': 10,
    'oktober': 10,
    'october': 10,
    'oct': 10,
    'nov': 11,
    'november': 11,
    'des': 12,
    'desember': 12,
    'december': 12,
    'dec': 12,
  };

  ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) return const ParsedReceipt(rawText: '');

    final merchant = _extractMerchant(lines);
    final totalMatch = _extractTotal(lines);
    final occurredAt = _extractDate(rawText);
    final items = _extractItems(lines);

    var confidence = 0.0;
    if (merchant != null) confidence += 0.3;
    if (totalMatch != null) confidence += 0.4;
    if (occurredAt != null) confidence += 0.2;
    if (items.isNotEmpty) confidence += 0.1;

    return ParsedReceipt(
      rawText: rawText,
      merchant: merchant,
      total: totalMatch == null ? null : Money(totalMatch),
      occurredAt: occurredAt,
      items: items,
      confidence: confidence.clamp(0, 1),
    );
  }

  String? _extractMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      final lower = line.toLowerCase();
      if (_ignoredMerchantWords.any(lower.contains)) continue;
      final letters = RegExp(r'[a-zA-Z]').allMatches(line).length;
      if (letters < 3) continue;
      if (_parseAmount(line) != null && letters < 6) continue;
      final cleaned = line
          .replaceAll(RegExp(r'^[^a-zA-Z0-9]+'), '')
          .replaceAll(RegExp(r'[^a-zA-Z0-9\)\.\&]+$'), '')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();
      if (cleaned.length < 2) continue;
      return _titleCase(cleaned);
    }
    return null;
  }

  int? _extractTotal(List<String> lines) {
    var bestScore = -1;
    int? bestAmount;

    for (final line in lines) {
      final lower = line.toLowerCase();
      var score = -1;
      for (var index = 0; index < _totalKeywords.length; index++) {
        if (lower.contains(_totalKeywords[index])) {
          score = _totalKeywords.length - index;
          break;
        }
      }
      if (score < 0) continue;
      if (lower.contains('qty') || lower.contains('item')) continue;

      final amounts = RegExp(r'\d[\d.,]*')
          .allMatches(line)
          .map((match) => match.group(0)!)
          .where(_looksLikeAmount)
          .map(_parseAmount)
          .whereType<int>()
          .where((value) => value >= 100)
          .toList();
      if (amounts.isEmpty) continue;
      final amount = amounts.reduce((a, b) => a > b ? a : b);
      if (score > bestScore ||
          (score == bestScore && (bestAmount ?? 0) < amount)) {
        bestScore = score;
        bestAmount = amount;
      }
    }

    if (bestAmount != null) return bestAmount;

    final allAmounts = <int>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_ignoredItemWords.any(lower.contains)) continue;
      if (_isMetadataLine(lower)) continue;
      // Amount-only lines are usually the right-hand column of a two-column
      // receipt. Pairing them needs layout data, so the plain-text fallback
      // only trusts lines that also carry a label.
      if (!RegExp(r'[a-zA-Z]').hasMatch(line)) continue;
      final amounts = RegExp(r'\d[\d.,]*')
          .allMatches(line)
          .map((match) => match.group(0)!)
          .where(_looksLikeAmount)
          .map(_parseAmount)
          .whereType<int>()
          .where((value) => value >= 1000 && value <= 100000000)
          .toList();
      allAmounts.addAll(amounts);
    }
    if (allAmounts.isEmpty) return null;
    allAmounts.sort();
    return allAmounts.last;
  }

  DateTime? _extractDate(String rawText) {
    final numeric = RegExp(r'(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{2,4})')
        .allMatches(rawText);
    for (final match in numeric) {
      final first = int.parse(match.group(1)!);
      final second = int.parse(match.group(2)!);
      var year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
      if (year < 2000 || year > 2100) continue;

      var day = first;
      var month = second;
      if (first <= 12 && second > 12) {
        month = first;
        day = second;
      }
      final date = DateTime(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return date;
      }
    }

    final named = RegExp(r'(\d{1,2})\s+([a-zA-Z]{3,9})\s+(\d{2,4})')
        .allMatches(rawText);
    for (final match in named) {
      final day = int.parse(match.group(1)!);
      final month = _monthNumbers[match.group(2)!.toLowerCase()];
      var year = int.parse(match.group(3)!);
      if (year < 100) year += 2000;
      if (month == null) continue;
      final date = DateTime(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return date;
      }
    }
    return null;
  }

  List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (_ignoredItemWords.any(lower.contains)) continue;
      if (lower.contains('total')) continue;
      if (_isMetadataLine(lower)) continue;

      final matches = RegExp(r'\d[\d.,]*').allMatches(line).toList();
      if (matches.isEmpty) continue;

      final amount = _lastAmount(matches);
      if (amount == null) continue;

      final quantityMatch = RegExp(r'(\d+)\s*[xX×]\s*[\d.,]+').firstMatch(line);
      final cutoff = quantityMatch?.start ?? matches.first.start;

      var name = line.substring(0, cutoff).trim();
      name = name.replaceAll(RegExp(r'[^a-zA-Z0-9\s\-\&]+$'), '').trim();
      if (name.length < 2 || !RegExp(r'[a-zA-Z]').hasMatch(name)) continue;

      var quantity = 1;
      if (quantityMatch != null) {
        quantity = int.tryParse(quantityMatch.group(1)!) ?? 1;
      }

      items.add(
        ReceiptItem(
          name: _titleCase(name),
          quantity: quantity,
          total: Money(amount),
        ),
      );
      if (items.length >= 30) break;
    }
    return items;
  }

  /// The last money-looking number on a line, ignoring identifiers.
  int? _lastAmount(List<RegExpMatch> matches) {
    for (final match in matches.reversed) {
      final token = match.group(0)!;
      if (!_looksLikeAmount(token)) continue;
      final amount = _parseAmount(token);
      if (amount == null || amount < 500) continue;
      return amount;
    }
    return null;
  }

  static bool _isMetadataLine(String lower) =>
      _metadataWords.any(lower.contains);

  /// Rejects long digit runs without thousands grouping: dates, nota ids, and
  /// phone numbers. "20261015-0042" is a nota id, not Rp 20.261.015.
  static bool _looksLikeAmount(String token) {
    final digits = token.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return false;
    if (digits.length <= 7) return true;
    return RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(token);
  }

  static int? _parseAmount(String token) {
    var text = token.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (text.isEmpty) return null;

    if (text.contains('.') && text.contains(',')) {
      final lastDot = text.lastIndexOf('.');
      final lastComma = text.lastIndexOf(',');
      if (lastDot > lastComma) {
        text = text.replaceAll(',', '');
      } else {
        text = text.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (text.contains(',')) {
      final parts = text.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        text = text.replaceAll(',', '.');
      } else {
        text = text.replaceAll(',', '');
      }
    } else if (text.contains('.')) {
      final parts = text.split('.');
      if (parts.length > 1 && parts.skip(1).every((part) => part.length == 3)) {
        text = text.replaceAll('.', '');
      }
    }

    final value = double.tryParse(text);
    if (value == null) return null;
    return value.round();
  }

  static String _titleCase(String value) {
    final lower = value.toLowerCase();
    return lower
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class CategoryTemplate {
  const CategoryTemplate({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorHex,
    required this.keywords,
    this.kind = CategoryKind.expense,
  });

  final String id;
  final String name;
  final String iconKey;
  final String colorHex;
  final List<String> keywords;
  final CategoryKind kind;
}

abstract final class DefaultCategories {
  static const String foodId = '10000000-0000-4000-8000-000000000001';
  static const String transportId = '10000000-0000-4000-8000-000000000002';
  static const String shoppingId = '10000000-0000-4000-8000-000000000003';
  static const String billsId = '10000000-0000-4000-8000-000000000004';
  static const String healthId = '10000000-0000-4000-8000-000000000005';
  static const String entertainmentId = '10000000-0000-4000-8000-000000000006';
  static const String salaryId = '10000000-0000-4000-8000-000000000007';
  static const String freelanceId = '10000000-0000-4000-8000-000000000008';
  static const String otherExpenseId = '10000000-0000-4000-8000-000000000009';
  static const String otherIncomeId = '10000000-0000-4000-8000-000000000010';

  static const List<CategoryTemplate> all = [
    CategoryTemplate(
      id: foodId,
      name: 'Food & Drinks',
      iconKey: 'restaurant',
      colorHex: '#E8B84B',
      keywords: [
        'makan',
        'minum',
        'kopi',
        'cafe',
        'resto',
        'restoran',
        'warung',
        'bakery',
        'indomaret',
        'alfamart',
        'supermarket',
        'grocery',
        'food',
        'drink',
        'coffee',
        'kfc',
        'mcd',
        'starbucks',
        'gofood',
        'grabfood',
      ],
    ),
    CategoryTemplate(
      id: transportId,
      name: 'Transport',
      iconKey: 'transport',
      colorHex: '#7FB6A4',
      keywords: [
        'gojek',
        'grab',
        'ojek',
        'taksi',
        'taxi',
        'bensin',
        'pertamina',
        'spbu',
        'parkir',
        'tol',
        'transport',
        'mrt',
        'lrt',
        'transjakarta',
        'krl',
        'tiket',
      ],
    ),
    CategoryTemplate(
      id: shoppingId,
      name: 'Shopping',
      iconKey: 'shopping',
      colorHex: '#D98C6A',
      keywords: [
        'shopee',
        'tokopedia',
        'lazada',
        'blibli',
        'uniqlo',
        'h&m',
        'mall',
        'store',
        'belanja',
        'shopping',
        'fashion',
        'elektronik',
        'electronics',
      ],
    ),
    CategoryTemplate(
      id: billsId,
      name: 'Bills',
      iconKey: 'receipt',
      colorHex: '#8CA8C9',
      keywords: [
        'pln',
        'listrik',
        'token',
        'air',
        'pdam',
        'internet',
        'wifi',
        'indihome',
        'telkomsel',
        'xl',
        'tri',
        'pulsa',
        'tagihan',
        'bill',
        'utilities',
        'bpjs',
        'asuransi',
        'insurance',
        'sewa',
        'rent',
      ],
    ),
    CategoryTemplate(
      id: healthId,
      name: 'Health',
      iconKey: 'health',
      colorHex: '#D96C75',
      keywords: [
        'apotek',
        'apotik',
        'klinik',
        'rumah sakit',
        'hospital',
        'dokter',
        'doctor',
        'obat',
        'medicine',
        'gym',
        'fitness',
        'kesehatan',
        'health',
      ],
    ),
    CategoryTemplate(
      id: entertainmentId,
      name: 'Entertainment',
      iconKey: 'entertainment',
      colorHex: '#B48CD9',
      keywords: [
        'netflix',
        'spotify',
        'disney',
        'youtube',
        'viu',
        'bioskop',
        'cinema',
        'konser',
        'concert',
        'game',
        'steam',
        'playstation',
        'hiburan',
        'entertainment',
        'liburan',
        'travel',
        'hotel',
      ],
    ),
    CategoryTemplate(
      id: otherExpenseId,
      name: 'Other',
      iconKey: 'dots',
      colorHex: '#9C9A8B',
      keywords: ['lainnya', 'other', 'misc', 'uncategorized'],
    ),
    CategoryTemplate(
      id: salaryId,
      name: 'Salary',
      iconKey: 'salary',
      colorHex: '#6FBF8F',
      keywords: ['gaji', 'salary', 'payroll', 'upah', 'bonus'],
      kind: CategoryKind.income,
    ),
    CategoryTemplate(
      id: freelanceId,
      name: 'Freelance',
      iconKey: 'briefcase',
      colorHex: '#6FA7BF',
      keywords: ['freelance', 'proyek', 'project', 'klien', 'client', 'honor'],
      kind: CategoryKind.income,
    ),
    CategoryTemplate(
      id: otherIncomeId,
      name: 'Other Income',
      iconKey: 'income',
      colorHex: '#9C9A8B',
      keywords: ['pemasukan', 'income', 'lainnya', 'other'],
      kind: CategoryKind.income,
    ),
  ];

  static List<CategoryTemplate> forKind(CategoryKind kind) =>
      all.where((template) => template.kind == kind).toList(growable: false);

  static CategoryTemplate? byId(String id) {
    for (final template in all) {
      if (template.id == id) return template;
    }
    return null;
  }
}

class CategoryClassifier {
  const CategoryClassifier();

  Category? classify({
    required String text,
    required List<Category> categories,
  }) {
    final normalized = text.toLowerCase();
    Category? best;
    var bestScore = 0;

    for (final category in categories) {
      if (category.kind != CategoryKind.expense || category.isDeleted) continue;
      var score = 0;
      if (normalized.contains(category.name.toLowerCase())) score += 3;

      final template = DefaultCategories.byId(category.id);
      final keywords = <String>{...category.keywords, ...?template?.keywords};
      for (final keyword in keywords) {
        if (keyword.trim().isEmpty) continue;
        // Count every mention: a receipt titled "Kopi Senja" with "Kopi Susu"
        // on it is stronger evidence for food & drinks than the single word
        // "air" in "Air Mineral" is for the water bill category.
        final occurrences = _occurrences(
          normalized,
          keyword.toLowerCase().trim(),
        );
        score += 2 * (occurrences > 3 ? 3 : occurrences);
      }

      if (score > bestScore) {
        bestScore = score;
        best = category;
      }
    }

    if (best != null) return best;

    for (final category in categories) {
      if (category.id == DefaultCategories.otherExpenseId) return category;
    }
    for (final category in categories) {
      if (category.kind == CategoryKind.expense) return category;
    }
    return null;
  }

  static int _occurrences(String text, String keyword) {
    if (keyword.isEmpty) return 0;
    var count = 0;
    var index = text.indexOf(keyword);
    while (index >= 0) {
      count++;
      index = text.indexOf(keyword, index + keyword.length);
    }
    return count;
  }
}
