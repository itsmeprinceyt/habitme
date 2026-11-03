import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/logic/providers.dart';
import 'package:habit_tracker/data/models/habit.dart';
import 'package:habit_tracker/data/repositories/habit_repository.dart';

class HabitController extends AsyncNotifier<List<Habit>> {
  HabitRepository get _repo => ref.read(habitRepositoryProvider);

  @override
  Future<List<Habit>> build() => _repo.getAll();

  Future<void> toggle(String id) async {
    final habit = _find(id);
    if (habit == null || habit.isDone) return;
    final updated = await _repo.toggleDone(habit, true);
    _replace(updated);
  }

  Future<void> add(Habit habit) async {
    await _repo.insert(habit);
    state = AsyncData([habit, ...?state.value]);
  }

  Future<void> updateHabit(Habit habit) async {
    await _repo.update(habit);
    _replace(habit);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = AsyncData([
      for (final h in state.value ?? const <Habit>[])
        if (h.id != id) h,
    ]);
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
