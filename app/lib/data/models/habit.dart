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
    final rawInterval = map[HabitColumns.recurInterval] is int
        ? map[HabitColumns.recurInterval] as int
        : null;
    // A zero or negative interval would trip the Recurrence assert, so such a
    // row is read as a plain one-time habit instead of failing the whole load.
    final interval = rawInterval != null && rawInterval > 0
        ? rawInterval
        : null;
    final recurring = _flag(map[HabitColumns.isRecurring]);
    final createdAt = _toDate(map[HabitColumns.createdAt]);
    final updatedAt = _toDate(map[HabitColumns.updatedAt]);
    return Habit(
      id: map[HabitColumns.id] as String? ?? '',
      name: (map[HabitColumns.name] as String?)?.trim() ?? 'Untitled habit',
      labelId: map[HabitColumns.labelId] as String?,
      recurrence: recurring && unit != null && interval != null
          ? Recurrence(unit: RecurUnit.fromName(unit), interval: interval)
          : null,
      notify: _flag(map[HabitColumns.notify]),
      isDone: _flag(map[HabitColumns.isDone]),
      oneTimeAt: _toDate(map[HabitColumns.oneTimeAt]),
      anchorAt:
          _toDate(map[HabitColumns.anchorAt]) ?? createdAt ?? DateTime.now(),
      nextDueAt: _toDate(map[HabitColumns.nextDueAt]),
      completedAt: _toDate(map[HabitColumns.completedAt]),
      createdAt: createdAt ?? updatedAt ?? DateTime.now(),
      updatedAt: updatedAt ?? createdAt ?? DateTime.now(),
    );
  }

  /// Tolerant boolean read: rows written by older builds or an imported file
  /// can carry 0/1, true/false or NULL.
  static bool _flag(Object? value) => value == 1 || value == true;

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
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    // Imported files can carry an epoch as text; anything unparseable reads as
    // "not set" rather than throwing the row away.
    final parsed = int.tryParse(value.toString());
    return parsed == null ? null : DateTime.fromMillisecondsSinceEpoch(parsed);
  }

  static DateTime _minuteOf(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
}
