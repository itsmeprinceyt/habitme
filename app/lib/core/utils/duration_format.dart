abstract final class DurationFormat {
  /// Formats a remaining duration into human friendly strings like:
  /// - "02h 14m 32s" (when compact = false)
  /// - "2d 4h left" or "Overdue by 15m" (when descriptive = true)
  static String formatCountdown(Duration duration, {bool isPast = false}) {
    final totalSeconds = duration.inSeconds.abs();
    final days = totalSeconds ~/ 86400;
    final hours = (totalSeconds % 86400) ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final String timeStr;
    if (days > 0) {
      timeStr = '${days}d ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
    } else if (hours > 0) {
      timeStr = '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else {
      timeStr = '${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }

    if (isPast) {
      return 'Overdue by $timeStr';
    }
    return timeStr;
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

