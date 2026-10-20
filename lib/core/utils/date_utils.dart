import 'package:intl/intl.dart';

class EzzeDateUtils {
  static final DateFormat _keyFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _prettyFormat = DateFormat('EEEE, MMM d');
  static final DateFormat _timeFormat = DateFormat('h:mm a');
  static final DateFormat _shortDate = DateFormat('MMM d');
  static final DateFormat _weekdayFormat = DateFormat('E');

  /// Returns 'yyyy-MM-dd' for the current local calendar day
  static String todayKey() {
    return _keyFormat.format(DateTime.now());
  }

  /// Returns 'yyyy-MM-dd' for a given DateTime
  static String dateKey(DateTime date) {
    return _keyFormat.format(date);
  }

  /// Parses 'yyyy-MM-dd' to DateTime (local midnight)
  static DateTime parseDateKey(String key) {
    return _keyFormat.parse(key);
  }

  /// Pretty date: "Tuesday, Oct 20"
  static String formatPretty(DateTime date) {
    return _prettyFormat.format(date);
  }

  /// Time formatted: "2:30 PM"
  static String formatTime(DateTime time) {
    return _timeFormat.format(time);
  }

  /// Short date: "Oct 20"
  static String formatShort(DateTime date) {
    return _shortDate.format(date);
  }

  /// Weekday abbreviation: "Mon", "Tue", etc.
  static String formatWeekday(DateTime date) {
    return _weekdayFormat.format(date);
  }

  /// Start of local day (midnight)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// End of local day (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Returns list of date keys for the last N days including today
  static List<String> lastNDaysKeys(int n) {
    final now = DateTime.now();
    final list = <String>[];
    for (int i = n - 1; i >= 0; i--) {
      list.add(dateKey(now.subtract(Duration(days: i))));
    }
    return list;
  }
}
