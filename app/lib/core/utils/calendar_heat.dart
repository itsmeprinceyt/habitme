/// Completion progress for one calendar day.
///
/// The heatmap is completion-based: a day's shade is
/// [completed] / [scheduled], not how many habits were merely planned.
class DayProgress {
  const DayProgress({required this.scheduled, required this.completed});

  /// Habits occurring on the day, ignoring the One-Time/Recurring filters.
  final int scheduled;

  /// Unique habits completed on the day, capped at [scheduled].
  final int completed;

  bool get hasTasks => scheduled > 0;

  double get ratio =>
      scheduled <= 0 ? 0 : (completed / scheduled).clamp(0.0, 1.0);

  int get percent => (ratio * 100).round();
}

/// Stable local-date key (`yyyy-m-d`) used to group completion rows by day.
String dayKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';
