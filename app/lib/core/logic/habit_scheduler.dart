import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/repositories/habit_repository.dart';
import 'package:habit_me/data/services/notification_service.dart';

class HabitScheduler {
  HabitScheduler(this._repo, this._notifications);

  static const perHabitCap = 40;
  static const globalCap = 60;

  final HabitRepository _repo;
  final NotificationService _notifications;

  Future<List<Habit>> reconcile(DateTime now) async {
    final habits = await _repo.getAll();
    final result = <Habit>[];

    for (final habit in habits) {
      final recurrence = habit.recurrence;
      final due = habit.nextDueAt;

      if (recurrence != null && due != null && !due.isAfter(now)) {
        final updated = habit.copyWith(
          isDone: false,
          completedAt: () => null,
          nextDueAt: () => recurrence.nextAfter(habit.anchorAt, now),
          updatedAt: now,
        );

        await _repo.update(updated);
        result.add(updated);
      } else {
        result.add(habit);
      }
    }

    // Reminders are re-armed in the background. `sync` logs every failure
    // itself, and the list must never sit in a loading state - or show an
    // error - because a platform channel was slow or refused the schedule.
    unawaited(sync(result, now, askPermissions: result.any((h) => h.notify)));

    return result;
  }

  Future<void> sync(
    List<Habit> habits,
    DateTime now, {
    bool askPermissions = false,
  }) async {
    try {
      await _notifications.init();

      if (askPermissions && habits.any((h) => h.notify)) {
        try {
          await _notifications.ensurePermissions();
        } catch (e, stackTrace) {
          debugPrint('Notification permission request failed: $e');
          debugPrintStack(stackTrace: stackTrace);
        }
      }

      await _notifications.replaceAll(_plan(habits, now));
    } catch (e, stackTrace) {
      debugPrint('HabitScheduler sync failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<ScheduledReminder> _plan(List<Habit> habits, DateTime now) {
    final allReminders = <ScheduledReminder>[];

    for (final habit in habits) {
      if (!habit.notify) continue;

      final recurrence = habit.recurrence;

      if (recurrence != null) {
        // Generate up to perHabitCap upcoming occurrences for each recurring habit
        for (final at in recurrence.upcoming(
          habit.anchorAt,
          now,
          perHabitCap,
        )) {
          allReminders.add(
            ScheduledReminder(
              key: _key(habit, at),
              habitId: habit.id,
              title: habit.name,
              body: 'Time to do it · ${recurrence.label}',
              at: at,
            ),
          );
        }
      } else {
        final scheduled = habit.oneTimeAt == null
            ? null
            : _toMinute(habit.oneTimeAt!);

        if (!habit.isDone && scheduled != null && scheduled.isAfter(now)) {
          allReminders.add(
            ScheduledReminder(
              key: _key(habit, scheduled),
              habitId: habit.id,
              title: habit.name,
              body: 'Reminder',
              at: scheduled,
            ),
          );
        }
      }
    }

    // Sort all upcoming reminders chronologically so the earliest ones are scheduled first!
    // E.g., if Habit A is every 12h and Habit B is every 24h:
    // A (morning), B (morning), A (night), B (next day)...
    allReminders.sort((a, b) => a.at.compareTo(b.at));

    return allReminders.take(globalCap).toList();
  }

  /// A reminder's identity only changes when the habit or the exact minute it
  /// targets changes, so an already armed reminder keeps its notification id
  /// (and therefore its alarm) across re-syncs.
  static String _key(Habit habit, DateTime at) =>
      '${habit.id}@${at.millisecondsSinceEpoch}';

  /// Drops seconds/milliseconds: schedules always land on a whole minute.
  static DateTime _toMinute(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
}
