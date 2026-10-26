import 'package:intl/intl.dart';

abstract final class CaseDates {
  static DateTime monthStart(DateTime date) => DateTime(date.year, date.month);

  static DateTime monthEnd(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  static DateTime nextMonth(DateTime date) =>
      DateTime(date.year, date.month + 1);

  static DateTime previousMonth(DateTime date) =>
      DateTime(date.year, date.month - 1);

  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static String localeCode(String locale) => locale == 'en' ? 'en_US' : 'id_ID';

  static String monthYear(DateTime date, String locale) =>
      DateFormat.yMMMM(localeCode(locale)).format(date);

  static String monthShort(DateTime date, String locale) =>
      DateFormat.MMM(localeCode(locale)).format(date);

  static String dayMonth(DateTime date, String locale) =>
      DateFormat('d MMM', localeCode(locale)).format(date);

  static String fullDate(DateTime date, String locale) =>
      DateFormat.yMMMMd(localeCode(locale)).format(date);

  static String dateTime(DateTime date, String locale) =>
      DateFormat.yMMMd(localeCode(locale)).add_Hm().format(date);

  static String time(DateTime date, String locale) =>
      DateFormat.Hm(localeCode(locale)).format(date);

  static String relativeDay(DateTime date, String locale) {
    if (isToday(date)) return locale == 'en' ? 'Today' : 'Hari ini';
    if (isYesterday(date)) return locale == 'en' ? 'Yesterday' : 'Kemarin';
    return fullDate(date, locale);
  }

  static String greetingKey(DateTime now) {
    if (now.hour < 11) return 'morning';
    if (now.hour < 15) return 'noon';
    if (now.hour < 19) return 'afternoon';
    return 'evening';
  }

  /// First day of each month, oldest first, ending with [end].
  static List<DateTime> lastMonths(int count, {DateTime? end}) {
    final anchor = monthStart(end ?? DateTime.now());
    return List.generate(
      count,
      (index) => DateTime(anchor.year, anchor.month - (count - 1 - index)),
    );
  }

  static String iso(DateTime date) => date.toUtc().toIso8601String();

  static DateTime? tryParse(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
