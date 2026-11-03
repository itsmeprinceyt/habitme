import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/constants/app_constants.dart';
import 'package:habit_tracker/core/logic/providers.dart';
import 'package:habit_tracker/core/ui/drawer/app_drawer.dart';
import 'package:habit_tracker/core/ui/home/calendar_view.dart';
import 'package:habit_tracker/core/ui/home/habit_list_view.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(homeViewModeProvider);
    final isCalendar = mode == HomeViewMode.calendar;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: isCalendar ? 'Show list' : 'Show calendar',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isCalendar
                    ? Icons.view_list_rounded
                    : Icons.calendar_month_rounded,
                key: ValueKey(isCalendar),
              ),
            ),
            onPressed: () => ref.read(homeViewModeProvider.notifier).toggle(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: const AppDrawer(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: isCalendar
            ? const CalendarView(key: ValueKey('calendar'))
            : const HabitListView(key: ValueKey('list')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit form arrives in step 4')),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New habit'),
      ),
    );
  }
}
