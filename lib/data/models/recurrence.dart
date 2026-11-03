import 'dart:math';

enum RecurUnit {
  minutes('Minutes', 'minute'),
  hours('Hours', 'hour'),
  days('Days', 'day'),
  months('Months', 'month'),
  years('Years', 'year');

  const RecurUnit(this.label, this.singular);

  final String label;
  final String singular;

  static RecurUnit fromName(String name) {
    return RecurUnit.values.firstWhere(
      (unit) => unit.name == name,
      orElse: () => RecurUnit.days,
    );
  }
}

class Recurrence {
  const Recurrence({required this.unit, required this.interval})
    : assert(interval > 0);

  final RecurUnit unit;
  final int interval;

  String get label {
    if (interval == 1) return 'Every ${unit.singular}';
    return 'Every $interval ${unit.label.toLowerCase()}';
  }

  DateTime occurrence(DateTime anchor, int index) {
    final steps = interval * index;
    switch (unit) {
      case RecurUnit.minutes:
        return anchor.add(Duration(minutes: steps));
      case RecurUnit.hours:
        return anchor.add(Duration(hours: steps));
      case RecurUnit.days:
        return DateTime(
          anchor.year,
          anchor.month,
          anchor.day + steps,
          anchor.hour,
          anchor.minute,
          anchor.second,
        );
      case RecurUnit.months:
        return _addMonths(anchor, steps);
      case RecurUnit.years:
        return _addMonths(anchor, steps * 12);
    }
  }

  DateTime nextAfter(DateTime anchor, DateTime now) {
    return occurrence(anchor, _nextIndex(anchor, now));
  }

  List<DateTime> upcoming(DateTime anchor, DateTime now, int count) {
    final start = _nextIndex(anchor, now);
    return List.generate(count, (i) => occurrence(anchor, start + i));
  }

  int _nextIndex(DateTime anchor, DateTime now) {
    var index = max(1, _estimate(anchor, now) - 1);
    while (!occurrence(anchor, index).isAfter(now)) {
      index++;
    }
    return index;
  }

  int _estimate(DateTime anchor, DateTime now) {
    final diff = now.difference(anchor);
    final monthDiff =
        (now.year - anchor.year) * 12 + (now.month - anchor.month);
    switch (unit) {
      case RecurUnit.minutes:
        return diff.inMinutes ~/ interval;
      case RecurUnit.hours:
        return diff.inHours ~/ interval;
      case RecurUnit.days:
        return diff.inDays ~/ interval;
      case RecurUnit.months:
        return monthDiff ~/ interval;
      case RecurUnit.years:
        return monthDiff ~/ (interval * 12);
    }
  }

  static DateTime _addMonths(DateTime anchor, int months) {
    final total = anchor.year * 12 + (anchor.month - 1) + months;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = min(anchor.day, lastDay);
    return DateTime(
      year,
      month,
      day,
      anchor.hour,
      anchor.minute,
      anchor.second,
    );
  }
}
