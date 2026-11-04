import 'package:intl/intl.dart';

abstract final class AppDateUtils {
  static final _timeFormat = DateFormat('h:mm a');
  static final _shortDateFormat = DateFormat('d MMM');
  static final _fullDateFormat = DateFormat('d MMM yyyy');
  static final _dateTimeFormat = DateFormat('d MMM, h:mm a');

  static String formatTime(DateTime dt) => _timeFormat.format(dt);
  static String formatShortDate(DateTime dt) => _shortDateFormat.format(dt);
  static String formatFullDate(DateTime dt) => _fullDateFormat.format(dt);
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt);

  /// Checks if two dates fall on the exact same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Returns a friendly human relative label like 'Today, 2:30 PM', 'Tomorrow, 9:00 AM',
  /// 'Yesterday, 8:00 PM', or '12 Nov, 10:00 AM'.
  static String formatRelativeDateTime(DateTime dt, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final timeStr = formatTime(dt);

    if (isSameDay(dt, current)) {
      return 'Today, $timeStr';
    }

    final tomorrow = current.add(const Duration(days: 1));
    if (isSameDay(dt, tomorrow)) {
      return 'Tomorrow, $timeStr';
    }

    final yesterday = current.subtract(const Duration(days: 1));
    if (isSameDay(dt, yesterday)) {
      return 'Yesterday, $timeStr';
    }

    if (dt.year == current.year) {
      return '${formatShortDate(dt)}, $timeStr';
    }

    return '${formatFullDate(dt)}, $timeStr';
  }
}

