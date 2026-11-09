import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_me/core/logic/habit_scheduler.dart';
import 'package:habit_me/data/models/completion.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/recurrence.dart';
import 'package:habit_me/data/repositories/habit_repository.dart';
import 'package:habit_me/data/services/notification_service.dart';

class FakeHabitRepository implements HabitRepository {
  final Map<String, Habit> habits = {};

  @override
  Future<List<Habit>> getAll() async => habits.values.toList();

  @override
  Future<Habit?> getById(String id) async => habits[id];

  @override
  Future<void> insert(Habit habit) async {
    habits[habit.id] = habit;
  }

  @override
  Future<void> update(Habit habit) async {
    habits[habit.id] = habit;
  }

  @override
  Future<void> delete(String id) async {
    habits.remove(id);
  }

  @override
  Future<Habit> toggleDone(Habit habit, bool done, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final updated = habit.copyWith(
      isDone: done,
      completedAt: () => done ? at : null,
      nextDueAt: () => habit.recurrence?.nextAfter(habit.anchorAt, at),
      updatedAt: at,
    );
    habits[habit.id] = updated;
    return updated;
  }

  @override
  Future<List<Completion>> completionsInRange(
    DateTime start,
    DateTime end,
  ) async =>
      [];
}

class FakeNotificationService implements NotificationService {
  List<ScheduledReminder> lastReplaced = [];
  List<ScheduledReminder> scheduledSingles = [];
  List<String> cancelledKeys = [];

  @override
  void Function(String habitId)? onDoneAction;

  @override
  void Function(String habitId, DateTime at)? onFired;

  @override
  bool get exactAlarmsBlocked => false;

  @override
  Future<void> init() async {}

  @override
  Future<void> ensurePermissions() async {}

  @override
  Future<void> checkPermissionsOnLaunch() async {}

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> replaceAll(List<ScheduledReminder> reminders) async {
    lastReplaced = List.from(reminders);
  }

  @override
  Future<void> scheduleOne(ScheduledReminder reminder) async {
    scheduledSingles.add(reminder);
  }

  @override
  Future<void> cancelByKey(String key) async {
    cancelledKeys.add(key);
  }
}

void main() {
  late FakeHabitRepository repo;
  late FakeNotificationService notifications;
  late HabitScheduler scheduler;

  setUp(() {
    repo = FakeHabitRepository();
    notifications = FakeNotificationService();
    scheduler = HabitScheduler(repo, notifications);
  });

  final now = DateTime(2026, 11, 9, 10, 0);

  test('No starvation under load: 2-min habit + daily habit', () {
    final fastHabit = Habit(
      id: 'fast',
      name: 'Fast Habit',
      recurrence: const Recurrence(unit: RecurUnit.minutes, interval: 2),
      notify: true,
      isDone: false,
      oneTimeAt: null,
      anchorAt: now,
      nextDueAt: now.add(const Duration(minutes: 2)),
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final dailyHabit = Habit(
      id: 'daily',
      name: 'Daily Habit',
      recurrence: const Recurrence(unit: RecurUnit.days, interval: 1),
      notify: true,
      isDone: false,
      oneTimeAt: null,
      anchorAt: DateTime(2026, 11, 9, 9, 0), // 9am anchor
      nextDueAt: DateTime(2026, 11, 10, 9, 0), // next morning 9am
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final plan = scheduler.planForTest([fastHabit, dailyHabit], now);

    // Assert daily habit's next occurrence is present
    final dailyReminders = plan.where((r) => r.habitId == 'daily').toList();
    expect(dailyReminders, isNotEmpty);
    expect(dailyReminders.first.at, equals(DateTime(2026, 11, 10, 9, 0)));
  });

  test('Cap respected: result length <= globalCap', () {
    final habits = List.generate(
      10,
      (i) => Habit(
        id: 'habit_$i',
        name: 'Habit $i',
        recurrence: const Recurrence(unit: RecurUnit.minutes, interval: 1),
        notify: true,
        isDone: false,
        oneTimeAt: null,
        anchorAt: now,
        nextDueAt: now.add(const Duration(minutes: 1)),
        completedAt: null,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final plan = scheduler.planForTest(habits, now);
    expect(plan.length, lessThanOrEqualTo(HabitScheduler.globalCap));
  });

  test('Per-habit quota: fast habit does not exceed 1 + extraPerHabit slots', () {
    final habit1 = Habit(
      id: 'fast',
      name: 'Fast',
      recurrence: const Recurrence(unit: RecurUnit.minutes, interval: 1),
      notify: true,
      isDone: false,
      oneTimeAt: null,
      anchorAt: now,
      nextDueAt: now.add(const Duration(minutes: 1)),
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    final habit2 = Habit(
      id: 'slow1',
      name: 'Slow 1',
      recurrence: const Recurrence(unit: RecurUnit.days, interval: 1),
      notify: true,
      isDone: false,
      oneTimeAt: null,
      anchorAt: now,
      nextDueAt: now.add(const Duration(days: 1)),
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );
    final habit3 = Habit(
      id: 'slow2',
      name: 'Slow 2',
      recurrence: const Recurrence(unit: RecurUnit.days, interval: 2),
      notify: true,
      isDone: false,
      oneTimeAt: null,
      anchorAt: now,
      nextDueAt: now.add(const Duration(days: 2)),
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final plan = scheduler.planForTest([habit1, habit2, habit3], now);

    const reservedCount = 3;
    final remaining = HabitScheduler.globalCap - reservedCount;
    final extraPerHabit = remaining ~/ 3; // 57 ~/ 3 = 19
    final maxAllowedForFast = 1 + extraPerHabit; // 20

    final fastCount = plan.where((r) => r.habitId == 'fast').length;
    expect(fastCount, lessThanOrEqualTo(maxAllowedForFast));
  });

  test('Stable keys: identical across calls and sub-minute now shifts', () {
    final habit = Habit(
      id: 'h1',
      name: 'Habit 1',
      recurrence: const Recurrence(unit: RecurUnit.hours, interval: 1),
      notify: true,
      isDone: false,
      oneTimeAt: null,
      anchorAt: now,
      nextDueAt: now.add(const Duration(hours: 1)),
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final plan1 = scheduler.planForTest([habit], now);
    final plan2 = scheduler.planForTest([habit], now);

    expect(plan1.map((r) => r.key), equals(plan2.map((r) => r.key)));

    // Shift now by 30 seconds (still within same minute interval)
    final nowShifted = now.add(const Duration(seconds: 30));
    final plan3 = scheduler.planForTest([habit], nowShifted);

    expect(plan1.map((r) => r.key), equals(plan3.map((r) => r.key)));
  });

  test('One-time reminder behavior', () {
    final futureTime = now.add(const Duration(hours: 2));
    final activeOneTime = Habit(
      id: 'ot_active',
      name: 'One Time Active',
      recurrence: null,
      notify: true,
      isDone: false,
      oneTimeAt: futureTime,
      anchorAt: now,
      nextDueAt: null,
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final doneOneTime = Habit(
      id: 'ot_done',
      name: 'One Time Done',
      recurrence: null,
      notify: true,
      isDone: true,
      oneTimeAt: futureTime,
      anchorAt: now,
      nextDueAt: null,
      completedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    final pastOneTime = Habit(
      id: 'ot_past',
      name: 'One Time Past',
      recurrence: null,
      notify: true,
      isDone: false,
      oneTimeAt: now.subtract(const Duration(minutes: 10)),
      anchorAt: now,
      nextDueAt: null,
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final plan = scheduler.planForTest(
      [activeOneTime, doneOneTime, pastOneTime],
      now,
    );

    expect(plan.length, equals(1));
    expect(plan.first.habitId, equals('ot_active'));
    expect(plan.first.at, equals(futureTime));
  });

  test('Oversubscription: globalCap + 5 notifying habits', () {
    final printedLogs = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) printedLogs.add(message);
    };

    try {
      final totalHabits = HabitScheduler.globalCap + 5;
      final habits = List.generate(
        totalHabits,
        (i) => Habit(
          id: 'habit_${i.toString().padLeft(3, '0')}',
          name: 'Habit $i',
          recurrence: const Recurrence(unit: RecurUnit.days, interval: 1),
          notify: true,
          isDone: i < 5, // First 5 are done, remaining 60 are not done
          oneTimeAt: null,
          anchorAt: now,
          nextDueAt: now.add(Duration(hours: i + 1)),
          completedAt: i < 5 ? now : null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final plan = scheduler.planForTest(habits, now);

      // Must be capped at globalCap
      expect(plan.length, equals(HabitScheduler.globalCap));

      // Over-subscription logged
      expect(
        printedLogs.any((log) => log.contains('HabitScheduler oversubscribed')),
        isTrue,
      );

      // Priority order: not-done habits before done habits
      // Total 65 habits: 5 done, 60 not-done.
      // globalCap is 60, so all 60 selected should be the not-done ones!
      for (final r in plan) {
        final habit = habits.firstWhere((h) => h.id == r.habitId);
        expect(habit.isDone, isFalse);
      }
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  test('onReminderFired: recurring schedules next, one-time does not', () async {
    final recurringHabit = Habit(
      id: 'rec_1',
      name: 'Recurring Habit',
      recurrence: const Recurrence(unit: RecurUnit.hours, interval: 1),
      notify: true,
      isDone: false,
      oneTimeAt: null,
      anchorAt: now,
      nextDueAt: now.add(const Duration(hours: 1)),
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    final oneTimeHabit = Habit(
      id: 'ot_1',
      name: 'One Time Habit',
      recurrence: null,
      notify: true,
      isDone: false,
      oneTimeAt: now.add(const Duration(hours: 2)),
      anchorAt: now,
      nextDueAt: null,
      completedAt: null,
      createdAt: now,
      updatedAt: now,
    );

    await repo.insert(recurringHabit);
    await repo.insert(oneTimeHabit);

    final firedTime = now.add(const Duration(hours: 1));
    await scheduler.onReminderFired('rec_1', firedTime);

    expect(notifications.scheduledSingles.length, equals(1));
    expect(notifications.scheduledSingles.first.habitId, equals('rec_1'));
    expect(
      notifications.scheduledSingles.first.at,
      equals(now.add(const Duration(hours: 2))),
    );

    // Now test one-time fired
    notifications.scheduledSingles.clear();
    await scheduler.onReminderFired('ot_1', now.add(const Duration(hours: 2)));
    expect(notifications.scheduledSingles, isEmpty);
  });
}
