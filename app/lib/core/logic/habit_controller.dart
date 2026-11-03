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
    // Reconcile habits and schedule notifications on app startup.
    return _scheduler.reconcile(DateTime.now());
  }

  // Called when the app returns to foreground.
  Future<void> reconcile() async {
    final updated = await _scheduler.reconcile(DateTime.now());
    state = AsyncData(updated);
  }

  Future<void> toggle(String id) async {
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

    await _scheduler.sync(
      habits,
      DateTime.now(),
      askPermissions: askPermissions,
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
