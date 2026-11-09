import 'dart:async';
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

  /// The minimum recommended interval between occurrences.
  static Duration get minRecurrenceInterval => const Duration(minutes: 15);

  /// Helper to warn in the habit creation flow if an interval is too frequent,
  /// as rapid occurrences consume the notification budget quickly.
  static bool isRecurrenceTooFrequent(Duration interval) =>
      interval < minRecurrenceInterval;

  /// Helper to check whether a new notifying habit can be added safely under the global cap.
  /// The creation UI should refuse a new notifying habit (or warn) when this returns false.
  static bool canAddNotifyingHabit(int currentNotifyingCount) =>
      currentNotifyingCount < globalCap;

  /// Reconciles habits on app startup/resume, rolling forward due habits in the database,
  /// and kicks off a background sync of OS notifications.
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

  /// Convenience wrapper that calls [reconcile] and awaits notification [sync]
  /// until it completes. Useful for lifecycle callbacks (e.g. app resume) and tests.
  Future<void> reconcileAndSync(
    DateTime now, {
    bool askPermissions = false,
  }) async {
    final habits = await reconcile(now);
    await sync(habits, now, askPermissions: askPermissions);
  }

  /// Called when a notification is delivered/fired or handled.
  /// Re-arms the next occurrence without replacing the whole queue.
  // TODO(background): refill via workmanager/flutter_background_fetch every N minutes
  Future<void> onReminderFired(String habitId, DateTime firedAt) async {
    try {
      final habit = await _repo.getById(habitId);
      if (habit == null || !habit.notify) return;

      final recurrence = habit.recurrence;
      if (recurrence != null) {
        final nextAt = _toMinute(recurrence.nextAfter(habit.anchorAt, firedAt));
        if (nextAt.isAfter(firedAt)) {
          final reminder = _makeReminder(habit, nextAt);
          await _notifications.scheduleOne(reminder);
        }
      }
    } catch (e, stackTrace) {
      debugPrint('HabitScheduler onReminderFired failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Synchronizes scheduled notifications with the operating system.
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

  /// Computes the list of scheduled reminders for the given habits and time.
  List<ScheduledReminder> computePlan(List<Habit> habits, DateTime now) =>
      _plan(habits, now);

  /// Test-visible wrapper for the internal [_plan] algorithm.
  @visibleForTesting
  List<ScheduledReminder> planForTest(List<Habit> habits, DateTime now) =>
      _plan(habits, now);

  /// Generates normalized upcoming occurrences for a habit in ascending order.
  Iterable<DateTime> _occurrences(Habit habit, DateTime now) {
    final recurrence = habit.recurrence;
    if (recurrence != null) {
      final upcoming = recurrence.upcoming(habit.anchorAt, now, perHabitCap);
      return upcoming.map(_toMinute);
    } else {
      final scheduled = habit.oneTimeAt == null
          ? null
          : _toMinute(habit.oneTimeAt!);
      if (!habit.isDone && scheduled != null && scheduled.isAfter(now)) {
        return [scheduled];
      }
      return const [];
    }
  }

  ScheduledReminder _makeReminder(Habit habit, DateTime at) {
    final normalized = _toMinute(at);
    final isRecurring = habit.recurrence != null;
    return ScheduledReminder(
      key: _key(habit, normalized),
      habitId: habit.id,
      title: habit.name,
      body: isRecurring
          ? 'Time to do it · ${habit.recurrence!.label}'
          : 'Reminder',
      at: normalized,
    );
  }

  void _reportOversubscription(List<Habit> reservable, int count) {
    debugPrint(
      'HabitScheduler oversubscribed: $count notifying habits > globalCap $globalCap',
    );
  }

  /// Prioritizes reservations when more notifying habits exist than globalCap.
  /// Order:
  /// 1. Not-yet completed habits before already completed ones (isDone == false first).
  /// 2. Earliest next occurrence.
  /// 3. Tiebreak by habitId.
  List<ScheduledReminder> _prioritize(
    List<ScheduledReminder> reserved,
    Map<String, Habit> habitMap,
  ) {
    final copy = List<ScheduledReminder>.from(reserved);
    copy.sort((a, b) {
      final habitA = habitMap[a.habitId];
      final habitB = habitMap[b.habitId];
      final doneA = habitA?.isDone ?? false;
      final doneB = habitB?.isDone ?? false;
      if (doneA != doneB) {
        return doneA ? 1 : -1; // false (not done) comes first
      }
      final cmpTime = a.at.compareTo(b.at);
      if (cmpTime != 0) return cmpTime;
      return a.habitId.compareTo(b.habitId);
    });
    return copy;
  }

  List<ScheduledReminder> _plan(List<Habit> habits, DateTime now) {
    final reservable = habits.where((h) => h.notify).toList();
    final habitMap = {for (final h in reservable) h.id: h};

    // 1) Reservation pass: exactly one "next occurrence" per notifying habit.
    final reserved = <ScheduledReminder>[];
    final overflow = <ScheduledReminder>[];

    for (final habit in reservable) {
      final occ = _occurrences(habit, now);
      final it = occ.iterator;
      if (!it.moveNext()) continue; // no upcoming occurrence at all
      reserved.add(_makeReminder(habit, it.current));
      while (it.moveNext()) {
        overflow.add(_makeReminder(habit, it.current));
      }
    }

    // 2) If reservations alone exceed the global cap, apply oversubscription policy.
    if (reserved.length > globalCap) {
      _reportOversubscription(reservable, reserved.length);
      return _prioritize(reserved, habitMap).take(globalCap).toList();
    }

    // 3) Fair fill: leftover budget shared with a per-habit quota so one
    //    fast habit cannot monopolize it. Earlier timestamps still win
    //    among candidates within quota.
    final remaining = globalCap - reserved.length;
    final notifyingCount = reservable.length;
    final extraPerHabit = notifyingCount == 0
        ? remaining
        : max(1, remaining ~/ notifyingCount);

    overflow.sort((a, b) => a.at.compareTo(b.at));

    final usedExtra = <String, int>{};
    final picked = <ScheduledReminder>[];

    for (final r in overflow) {
      if (picked.length >= remaining) break;
      final used = usedExtra[r.habitId] ?? 0;
      if (used >= extraPerHabit) continue;
      usedExtra[r.habitId] = used + 1;
      picked.add(r);
    }

    return [...reserved, ...picked]..sort((a, b) => a.at.compareTo(b.at));
  }

  /// A reminder's identity only changes when the habit or the exact minute it
  /// targets changes, so an already armed reminder keeps its notification id
  /// (and therefore its alarm) across re-syncs.
  static String _key(Habit habit, DateTime at) {
    final m = _toMinute(at);
    return '${habit.id}@${m.millisecondsSinceEpoch}';
  }

  /// Drops seconds/milliseconds: schedules always land on a whole minute.
  static DateTime _toMinute(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
}
