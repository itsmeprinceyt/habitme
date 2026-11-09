import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/repositories/habit_repository.dart';
import 'package:habit_me/core/logic/habit_scheduler.dart';

class HabitController extends AsyncNotifier<List<Habit>> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  HabitScheduler get _scheduler => ref.read(habitSchedulerProvider);

  @override
  Future<List<Habit>> build() async {
    // Reconcile habits on app startup. Notification re-arming runs in the
    // background, so only a database failure can leave the list unloaded.
    try {
      return await _scheduler.reconcile(DateTime.now());
    } catch (error, stackTrace) {
      debugPrint('Habit load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  // Called when the app returns to foreground.
  Future<void> reconcile() async {
    final updated = await _scheduler.reconcile(DateTime.now());
    state = AsyncData(updated);
  }

  /// Reconciles habits and ensures notifications are fully synchronized with the OS.
  Future<void> reconcileAndSync() async {
    await _scheduler.reconcileAndSync(DateTime.now());
    final habits = await _repo.getAll();
    state = AsyncData(habits);
  }

  /// Rolls occurrences that have just become due forward so the countdown in
  /// the UI restarts on the next occurrence instead of sitting at zero.
  /// Cheap: it does nothing (no DB write, no rebuild) while nothing is due.
  Future<void> refreshDue() async {
    final habits = state.value;
    if (habits == null) return;

    final now = DateTime.now();
    final isDue = habits.any(
      (h) =>
          h.recurrence != null &&
          h.nextDueAt != null &&
          !h.nextDueAt!.isAfter(now),
    );
    if (!isDue) return;

    await reconcile();
  }

  Future<void> toggle(String id) async {
    final habit = _find(id);
    if (habit == null) return;

    final targetDoneState = !habit.isDone;
    final updated = await _repo.toggleDone(habit, targetDoneState);
    _replace(updated);

    await _syncNotifications();
  }

  /// Marks a habit done from a notification action. Unlike [toggle], this is
  /// idempotent: an already-done habit is left untouched.
  Future<void> markDoneFromNotification(String id) async {
    final habit = _find(id);
    if (habit == null || habit.isDone) return;

    final updated = await _repo.toggleDone(habit, true);
    _replace(updated);

    await _syncNotifications();
  }

  Future<void> add(Habit habit) async {
    await _repo.insert(habit);

    state = AsyncData([habit, ...?state.value]);

    await _syncNotifications(askPermissions: habit.notify);
  }

  Future<void> updateHabit(Habit habit) async {
    await _repo.update(habit);

    _replace(habit);

    await _syncNotifications(askPermissions: habit.notify);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);

    state = AsyncData([
      for (final h in state.value ?? const <Habit>[])
        if (h.id != id) h,
    ]);

    await _syncNotifications();
  }

  Future<void> _syncNotifications({bool askPermissions = false}) async {
    final habits = state.value;

    if (habits == null) return;

    // Kept off the UI path: a slow or refused platform call must never leave a
    // tile spinning after the habit itself is already saved. `sync` catches and
    // logs everything it hits.
    unawaited(
      _scheduler.sync(habits, DateTime.now(), askPermissions: askPermissions),
    );
  }

  Habit? _find(String id) {
    for (final h in state.value ?? const <Habit>[]) {
      if (h.id == id) return h;
    }
    return null;
  }

  void _replace(Habit habit) {
    state = AsyncData([
      for (final h in state.value ?? const <Habit>[])
        if (h.id == habit.id) habit else h,
    ]);
  }
}
