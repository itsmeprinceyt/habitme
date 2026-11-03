import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/logic/habit_controller.dart';
import 'package:habit_tracker/data/db/app_database.dart';
import 'package:habit_tracker/data/models/habit.dart';
import 'package:habit_tracker/data/repositories/habit_repository.dart';

enum HomeViewMode { list, calendar }

class HomeViewModeNotifier extends Notifier<HomeViewMode> {
  @override
  HomeViewMode build() => HomeViewMode.list;

  void toggle() {
    state = state == HomeViewMode.list
        ? HomeViewMode.calendar
        : HomeViewMode.list;
  }
}

final homeViewModeProvider =
    NotifierProvider<HomeViewModeNotifier, HomeViewMode>(
      HomeViewModeNotifier.new,
    );

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => HabitRepository(AppDatabase.instance),
);

final habitControllerProvider =
    AsyncNotifierProvider<HabitController, List<Habit>>(HabitController.new);

final activeHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitControllerProvider).value ?? const <Habit>[];
  return habits.where((h) => !h.isDone).toList();
});

final completedHabitsProvider = Provider<List<Habit>>((ref) {
  final habits = ref.watch(habitControllerProvider).value ?? const <Habit>[];
  final done = habits.where((h) => h.isDone).toList();
  done.sort(
    (a, b) =>
        (b.completedAt ?? b.updatedAt).compareTo(a.completedAt ?? a.updatedAt),
  );
  return done;
});
