abstract final class CompletionColumns {
  static const id = 'id';
  static const habitId = 'habit_id';
  static const completedAt = 'completed_at';
}

class Completion {
  const Completion({this.id, required this.habitId, required this.completedAt});

  factory Completion.fromMap(Map<String, Object?> map) {
    return Completion(
      id: map[CompletionColumns.id] as int?,
      habitId: map[CompletionColumns.habitId] as String,
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        map[CompletionColumns.completedAt] as int,
      ),
    );
  }

  final int? id;
  final String habitId;
  final DateTime completedAt;

  Map<String, Object?> toMap() {
    return {
      if (id != null) CompletionColumns.id: id,
      CompletionColumns.habitId: habitId,
      CompletionColumns.completedAt: completedAt.millisecondsSinceEpoch,
    };
  }
}
