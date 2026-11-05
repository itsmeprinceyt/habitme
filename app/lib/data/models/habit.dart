import 'package:flutter/foundation.dart';
import 'package:habit_me/data/models/recurrence.dart';
import 'package:uuid/uuid.dart';

abstract final class HabitColumns {
  static const id = 'id';
  static const name = 'name';
  static const labelId = 'label_id';
  static const isRecurring = 'is_recurring';
  static const recurUnit = 'recur_unit';
  static const recurInterval = 'recur_interval';
  static const notify = 'notify';
  static const isDone = 'is_done';
  static const oneTimeAt = 'one_time_at';
  static const anchorAt = 'anchor_at';
  static const nextDueAt = 'next_due_at';
  static const completedAt = 'completed_at';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';
}

class Habit {
  const Habit({
    required this.id,
    required this.name,
    this.labelId,
    required this.recurrence,
    required this.notify,
    required this.isDone,
    required this.oneTimeAt,
    required this.anchorAt,
    required this.nextDueAt,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Habit.create({
    required String name,
    String? labelId,
    Recurrence? recurrence,
    bool notify = false,
    DateTime? oneTimeAt,
    DateTime? anchorAt,
    DateTime? now,
  }) {
    // Schedules never carry seconds: everything is anchored to a whole minute.
    final created = _minuteOf(now ?? DateTime.now());
    final anchor = _minuteOf(anchorAt ?? created);
    return Habit(
      id: const Uuid().v4(),
      name: name.trim(),
      labelId: labelId,
      recurrence: recurrence,
      notify: notify,
      isDone: false,
      oneTimeAt: recurrence != null || oneTimeAt == null
          ? null
          : _minuteOf(oneTimeAt),
      anchorAt: anchor,
      nextDueAt: recurrence?.nextAfter(anchor, created),
      completedAt: null,
      createdAt: created,
      updatedAt: created,
    );
  }

  factory Habit.fromMap(Map<String, Object?> map) {
    final unit = map[HabitColumns.recurUnit] as String?;
    final interval = map[HabitColumns.recurInterval] as int?;
    final recurring = (map[HabitColumns.isRecurring] as int) == 1;
    return Habit(
      id: map[HabitColumns.id] as String,
      name: map[HabitColumns.name] as String,
      labelId: map[HabitColumns.labelId] as String?,
      recurrence: recurring && unit != null && interval != null
          ? Recurrence(unit: RecurUnit.fromName(unit), interval: interval)
          : null,
      notify: (map[HabitColumns.notify] as int) == 1,
      isDone: (map[HabitColumns.isDone] as int) == 1,
      oneTimeAt: _toDate(map[HabitColumns.oneTimeAt]),
      anchorAt: _toDate(map[HabitColumns.anchorAt])!,
      nextDueAt: _toDate(map[HabitColumns.nextDueAt]),
      completedAt: _toDate(map[HabitColumns.completedAt]),
      createdAt: _toDate(map[HabitColumns.createdAt])!,
      updatedAt: _toDate(map[HabitColumns.updatedAt])!,
    );
  }

  final String id;
  final String name;
  final String? labelId;
  final Recurrence? recurrence;
  final bool notify;
  final bool isDone;
  final DateTime? oneTimeAt;
  final DateTime anchorAt;
  final DateTime? nextDueAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isRecurring => recurrence != null;
  bool get isOneTime => recurrence == null;
  bool get isCompleted => isDone;

  Habit copyWith({
    String? name,
    ValueGetter<String?>? labelId,
    ValueGetter<Recurrence?>? recurrence,
    bool? notify,
    bool? isDone,
    ValueGetter<DateTime?>? oneTimeAt,
    DateTime? anchorAt,
    ValueGetter<DateTime?>? nextDueAt,
    ValueGetter<DateTime?>? completedAt,
    DateTime? updatedAt,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      labelId: labelId != null ? labelId() : this.labelId,
      recurrence: recurrence != null ? recurrence() : this.recurrence,
      notify: notify ?? this.notify,
      isDone: isDone ?? this.isDone,
      oneTimeAt: oneTimeAt != null ? oneTimeAt() : this.oneTimeAt,
      anchorAt: anchorAt ?? this.anchorAt,
      nextDueAt: nextDueAt != null ? nextDueAt() : this.nextDueAt,
      completedAt: completedAt != null ? completedAt() : this.completedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      HabitColumns.id: id,
      HabitColumns.name: name,
      HabitColumns.labelId: labelId,
      HabitColumns.isRecurring: isRecurring ? 1 : 0,
      HabitColumns.recurUnit: recurrence?.unit.name,
      HabitColumns.recurInterval: recurrence?.interval,
      HabitColumns.notify: notify ? 1 : 0,
      HabitColumns.isDone: isDone ? 1 : 0,
      HabitColumns.oneTimeAt: oneTimeAt?.millisecondsSinceEpoch,
      HabitColumns.anchorAt: anchorAt.millisecondsSinceEpoch,
      HabitColumns.nextDueAt: nextDueAt?.millisecondsSinceEpoch,
      HabitColumns.completedAt: completedAt?.millisecondsSinceEpoch,
      HabitColumns.createdAt: createdAt.millisecondsSinceEpoch,
      HabitColumns.updatedAt: updatedAt.millisecondsSinceEpoch,
    };
  }

  static DateTime? _toDate(Object? value) {
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value as int);
  }

  static DateTime _minuteOf(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
}
