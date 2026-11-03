import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/data/db/app_database.dart';
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
