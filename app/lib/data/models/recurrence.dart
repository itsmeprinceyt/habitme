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
  const Recurrence({required this.unit, required this.interval, this.count})
    : assert(interval > 0),
      assert(count == null || count > 0);

  final RecurUnit unit;
  final int interval;

  /// Total number of occurrences the habit repeats for. `null` means it keeps
  /// repeating forever, which is how every habit saved before the limit
  /// existed is read.
  final int? count;

  bool get isLimited => count != null;

  Recurrence withCount(int? count) =>
      count == null || count < 1
      ? Recurrence(unit: unit, interval: interval)
      : Recurrence(unit: unit, interval: interval, count: count);

  String get label {
    final base = interval == 1
        ? 'Every ${unit.singular}'
        : 'Every $interval ${unit.label.toLowerCase()}';
    final total = count;
    if (total == null) return base;
    return '$base · $total ${total == 1 ? 'time' : 'times'}';
  }

  @override
  bool operator ==(Object other) =>
      other is Recurrence &&
      other.unit == unit &&
      other.interval == interval &&
      other.count == count;

  @override
  int get hashCode => Object.hash(unit, interval, count);

  @override
  String toString() =>
      'Recurrence(${unit.name}, every $interval, count: $count)';

  /// Truncates to minute precision — schedules never carry seconds.
  static DateTime minuteOf(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);

  DateTime occurrence(DateTime anchor, int index) {
    final base = minuteOf(anchor);
    final steps = interval * index;
    switch (unit) {
      case RecurUnit.minutes:
        return base.add(Duration(minutes: steps));
      case RecurUnit.hours:
        return base.add(Duration(hours: steps));
      case RecurUnit.days:
        return DateTime(
          base.year,
          base.month,
          base.day + steps,
          base.hour,
          base.minute,
        );
      case RecurUnit.months:
        return _addMonths(base, steps);
      case RecurUnit.years:
        return _addMonths(base, steps * 12);
    }
  }

  /// The next occurrence strictly after [now], or `null` when the series has
  /// already produced all of its occurrences.
  DateTime? nextAfter(DateTime anchor, DateTime now) {
    final index = _nextIndex(anchor, now);
    final total = count;
    if (total != null && index >= total) return null;
    return occurrence(anchor, index);
  }

  /// Upcoming occurrences after [now], never more than the remaining repeat
  /// count allows.
  List<DateTime> upcoming(DateTime anchor, DateTime now, int take) {
    final start = _nextIndex(anchor, now);
    final total = count;
    final available = total == null ? take : max(0, total - start);
    if (available <= 0) return const [];
    return List.generate(
      min(take, available),
      (i) => occurrence(anchor, start + i),
    );
  }

  /// How many occurrences are still ahead of [now], or `null` when there is no
  /// limit. Counts the occurrence starting exactly at [now] as still ahead.
  int? remaining(DateTime anchor, DateTime now) {
    final total = count;
    if (total == null) return null;
    final used = _elapsedOccurrences(anchor, now);
    final left = total - used;
    return left < 0 ? 0 : left;
  }

  /// Whether the rule has produced every occurrence it ever will.
  bool isFinished(DateTime anchor, DateTime now) {
    final total = count;
    return total != null && _nextIndex(anchor, now) >= total;
  }

  /// Checks if an occurrence lands on the given calendar date (ignoring hour/min).
  bool occursOnDate(DateTime anchor, DateTime targetDate) {
    // If target date is before anchor day, cannot occur
    final targetStartOfDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    final anchorStartOfDay = DateTime(anchor.year, anchor.month, anchor.day);
    if (targetStartOfDay.isBefore(anchorStartOfDay)) {
      return false;
    }

    switch (unit) {
      case RecurUnit.minutes:
      case RecurUnit.hours:
        // Intraday recurrence: occurs every day from anchor onward. A repeat
        // count limits the schedule, but a single day can still hold several
        // occurrences, so the per-day calendar stays as it was.
        return true;

      case RecurUnit.days:
        final diffDays = targetStartOfDay.difference(anchorStartOfDay).inDays;
        if (diffDays < 0 || (diffDays % _step != 0)) return false;
        return _withinLimit(diffDays ~/ _step);

      case RecurUnit.months:
        final totalMonths =
            (targetDate.year - anchor.year) * 12 +
            (targetDate.month - anchor.month);
        if (totalMonths < 0 || totalMonths % _step != 0) return false;
        if (!_withinLimit(totalMonths ~/ _step)) return false;
        // Check day match (with clamped last-day-of-month logic)
        final lastDay = DateTime(targetDate.year, targetDate.month + 1, 0).day;
        final expectedDay = min(anchor.day, lastDay);
        return targetDate.day == expectedDay;

      case RecurUnit.years:
        final yearDiff = targetDate.year - anchor.year;
        if (yearDiff < 0 || yearDiff % _step != 0) return false;
        if (!_withinLimit(yearDiff ~/ _step)) return false;
        if (targetDate.month != anchor.month) return false;
        final lastDay = DateTime(targetDate.year, targetDate.month + 1, 0).day;
        final expectedDay = min(anchor.day, lastDay);
        return targetDate.day == expectedDay;
    }
  }

  bool _withinLimit(int index) {
    final total = count;
    return total == null || index < total;
  }

  int _nextIndex(DateTime anchor, DateTime now) {
    var index = max(0, _estimate(anchor, now) - 1);

    // The step is always at least one minute, so this walk terminates.
    while (!occurrence(anchor, index).isAfter(now)) {
      index++;
    }

    return index;
  }

  /// Number of occurrences that have already started strictly before [now].
  /// An occurrence landing exactly on [now] still counts as remaining.
  int _elapsedOccurrences(DateTime anchor, DateTime now) {
    if (!now.isAfter(anchor)) return 0;

    var index = max(0, _estimate(anchor, now));
    while (index > 0 && !occurrence(anchor, index).isBefore(now)) {
      index--;
    }
    if (!occurrence(anchor, index).isBefore(now)) return 0;
    while (occurrence(anchor, index + 1).isBefore(now)) {
      index++;
    }
    return index + 1;
  }

  int _estimate(DateTime anchor, DateTime now) {
    final diff = now.difference(anchor);
    final monthDiff =
        (now.year - anchor.year) * 12 + (now.month - anchor.month);
    switch (unit) {
      case RecurUnit.minutes:
        return diff.inMinutes ~/ _step;
      case RecurUnit.hours:
        return diff.inHours ~/ _step;
      case RecurUnit.days:
        return diff.inDays ~/ _step;
      case RecurUnit.months:
        return monthDiff ~/ _step;
      case RecurUnit.years:
        return monthDiff ~/ (_step * 12);
    }
  }

  /// Interval as actually used by the maths. A row that somehow carries 0 or a
  /// negative value would otherwise divide by zero, or - worse - make
  /// [_nextIndex] loop forever, so the step is floored at one.
  int get _step => interval < 1 ? 1 : interval;

  static DateTime _addMonths(DateTime anchor, int months) {
    final total = anchor.year * 12 + (anchor.month - 1) + months;
    final year = total ~/ 12;
    final month = total % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = min(anchor.day, lastDay);
    return DateTime(year, month, day, anchor.hour, anchor.minute);
  }
}
