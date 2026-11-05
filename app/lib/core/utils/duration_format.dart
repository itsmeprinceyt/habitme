abstract final class DurationFormat {
  /// Full precision live countdown with the leading zero units dropped:
  /// "2h 48m 21s", "48m 21s", "9s", "2d 4h 8m 9s", "Overdue by 1m 5s".
  /// Occurrences still land on a whole minute, so the seconds simply count
  /// down inside the current minute.
  static String formatCountdown(Duration duration, {bool isPast = false}) {
    final total = duration.abs();
    if (total.inSeconds == 0) return isPast ? 'Overdue' : 'Due now';

    final days = total.inDays;
    final hours = total.inHours % 24;
    final minutes = total.inMinutes % 60;
    final seconds = total.inSeconds % 60;

    final parts = <String>[
      if (days > 0) '${days}d',
      if (days > 0 || hours > 0) '${hours}h',
      if (days > 0 || hours > 0 || minutes > 0) '${minutes}m',
      '${seconds}s',
    ];

    final text = parts.join(' ');
    return isPast ? 'Overdue by $text' : text;
  }

  /// Compact summary for tags (e.g. "in 3h", "in 2d", "due now")
  static String formatApproximate(Duration duration, {bool isPast = false}) {
    final diff = duration.abs();
    if (diff.inSeconds < 45) {
      return isPast ? 'Just passed' : 'Due now';
    }
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return isPast ? '${mins}m ago' : 'in ${mins}m';
    }
    if (diff.inHours < 24) {
      final hrs = diff.inHours;
      return isPast ? '${hrs}h ago' : 'in ${hrs}h';
    }
    final days = diff.inDays;
    return isPast ? '${days}d ago' : 'in ${days}d';
  }
}
