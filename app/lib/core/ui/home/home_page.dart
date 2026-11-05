import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/ui/drawer/app_drawer.dart';
import 'package:habit_me/core/ui/home/calendar_view.dart';
import 'package:habit_me/core/ui/home/habit_list_view.dart';
import 'package:habit_me/core/ui/habit_form/habit_form_sheet.dart';

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
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backdropGradient),
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.02, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: isCalendar
                ? const CalendarView(key: ValueKey('calendar'))
                : const HabitListView(key: ValueKey('list')),
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: AppColors.accentGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => HabitFormSheet.show(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New habit'),
        ),
      ),
    );
  }
}
