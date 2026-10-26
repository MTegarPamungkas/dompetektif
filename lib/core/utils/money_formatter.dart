import 'package:intl/intl.dart';

/// Formatting and parsing for money values.
///
/// Domain entities store integer minor units. IDR uses zero decimals, most
/// other currencies use two. Keeping this in one place avoids floating point
/// drift in balances and budgets.
abstract final class MoneyFormatter {
  static int decimalsFor(String currency) =>
      currency.toUpperCase() == 'IDR' ? 0 : 2;

  static double majorUnits(int minorUnits, {String currency = 'IDR'}) {
    final decimals = decimalsFor(currency);
    if (decimals == 0) return minorUnits.toDouble();
    return minorUnits / 100;
  }

  static int toMinor(num major, {String currency = 'IDR'}) {
    final decimals = decimalsFor(currency);
    return decimals == 0 ? major.round() : (major * 100).round();
  }

  static String format(
    int minorUnits, {
    String currency = 'IDR',
    String localeCode = 'id',
    bool signed = false,
    bool compact = false,
    bool hidden = false,
  }) {
    if (hidden) return '••••••';

    final locale = localeCode == 'en' ? 'en_US' : 'id_ID';
    final decimals = decimalsFor(currency);
    final value = majorUnits(minorUnits, currency: currency);
    final symbol = currency == 'IDR' ? 'Rp' : currency;

    if (compact) {
      return _compact(
        value,
        symbol: symbol,
        localeCode: localeCode,
        signed: signed,
        minor: minorUnits,
      );
    }

    final formatter = NumberFormat.currency(
      locale: locale,
      symbol: '$symbol ',
      decimalDigits: decimals,
    );
    final text = formatter.format(value.abs());
    final prefix = signed && minorUnits > 0 ? '+' : (minorUnits < 0 ? '−' : '');
    return '$prefix$text';
  }

  static String _compact(
    double value, {
    required String symbol,
    required String localeCode,
    required bool signed,
    required int minor,
  }) {
    final abs = value.abs();
    final (divisor, suffixId, suffixEn) = switch (abs) {
      >= 1000000000 => (1000000000.0, ' M', 'B'),
      >= 1000000 => (1000000.0, ' jt', 'M'),
      >= 1000 => (1000.0, ' rb', 'K'),
      _ => (1.0, '', ''),
    };
    final scaled = abs / divisor;
    final digits = scaled >= 100 || divisor == 1 ? 0 : (scaled >= 10 ? 1 : 1);
    final number = NumberFormat.decimalPatternDigits(
      locale: localeCode == 'en' ? 'en_US' : 'id_ID',
      decimalDigits: digits,
    ).format(scaled);
    final suffix = localeCode == 'en' ? suffixEn : suffixId;
    final prefix = signed && minor > 0 ? '+' : (minor < 0 ? '−' : '');
    return '$prefix$symbol $number$suffix';
  }

  /// Accepts input such as `1.500.000`, `1500000`, `1,5jt`, `250rb`.
  static int? parse(String raw, {String currency = 'IDR'}) {
    var text = raw.trim().toLowerCase();
    if (text.isEmpty) return null;

    text = text.replaceAll('rp', '').replaceAll(RegExp(r'[^0-9.,a-z]'), '');

    final multiplier = switch (text) {
      _ when text.endsWith('jt') || text.endsWith('juta') => 1000000,
      _ when text.endsWith('rb') || text.endsWith('ribu') => 1000,
      _ when text.endsWith('m') || text.endsWith('miliar') => 1000000000,
      _ => 1,
    };
    text = text.replaceAll(RegExp(r'(juta|jt|ribu|rb|miliar|m)$'), '');

    if (multiplier > 1) {
      final normalized = text.replaceAll(',', '.');
      final value = double.tryParse(normalized);
      if (value == null) return null;
      return toMinor(value * multiplier, currency: currency);
    }

    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    final value = int.tryParse(digits);
    return value;
  }

  /// Formats an amount for a text field without the currency symbol.
  static String input(int minorUnits, {String currency = 'IDR'}) {
    final decimals = decimalsFor(currency);
    if (decimals == 0) {
      return NumberFormat.decimalPattern('id_ID').format(minorUnits);
    }
    return NumberFormat.decimalPatternDigits(
      locale: 'id_ID',
      decimalDigits: decimals,
    ).format(majorUnits(minorUnits, currency: currency));
  }

  static String percent(double ratio, {String localeCode = 'id'}) {
    final formatter = NumberFormat.decimalPercentPattern(
      locale: localeCode == 'en' ? 'en_US' : 'id_ID',
      decimalDigits: 0,
    );
    return formatter.format(ratio.clamp(0, 9.99));
  }
}
