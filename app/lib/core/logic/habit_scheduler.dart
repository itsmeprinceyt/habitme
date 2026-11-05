import 'dart:math';

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
    await _notifications.init();
    await _notifications.syncTimezone();

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

    await sync(result, now);

    return result;
  }

  Future<void> sync(
    List<Habit> habits,
    DateTime now, {
    bool askPermissions = false,
  }) async {
    try {
      await _notifications.init();
      await _notifications.syncTimezone();

      if (askPermissions && habits.any((h) => h.notify)) {
        await _notifications.ensurePermissions();
      }

      await _notifications.replaceAll(_plan(habits, now));
    } catch (e, stackTrace) {
      debugPrint('HabitScheduler sync failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  List<ScheduledReminder> _plan(List<Habit> habits, DateTime now) {
    final recurringCount = habits
        .where((h) => h.isRecurring && h.notify)
        .length;

    final perHabit = recurringCount == 0
        ? 0
        : min(perHabitCap, max(3, globalCap ~/ recurringCount));

    // One-time reminders are single-shot and can't be regenerated, so they get
    // priority over recurring reminders when the global cap is hit.
    final oneTime = <ScheduledReminder>[];
    final recurring = <ScheduledReminder>[];

    for (final habit in habits) {
      if (!habit.notify) continue;

      final recurrence = habit.recurrence;

      if (recurrence != null) {
        for (final at in recurrence.upcoming(habit.anchorAt, now, perHabit)) {
          recurring.add(
            ScheduledReminder(
              habitId: habit.id,
              title: habit.name,
              body: 'Time to do it · ${recurrence.label}',
              at: at,
            ),
          );
        }
      } else {
        final at = habit.oneTimeAt;

        if (!habit.isDone && at != null && at.isAfter(now)) {
          final minute = DateTime(
            at.year,
            at.month,
            at.day,
            at.hour,
            at.minute,
          );
          oneTime.add(
            ScheduledReminder(
              habitId: habit.id,
              title: habit.name,
              body: 'Reminder',
              at: minute,
            ),
          );
        }
      }
    }

    int byTime(ScheduledReminder a, ScheduledReminder b) =>
        a.at.compareTo(b.at);
    oneTime.sort(byTime);
    recurring.sort(byTime);

    return [...oneTime, ...recurring].take(globalCap).toList();
  }
}
