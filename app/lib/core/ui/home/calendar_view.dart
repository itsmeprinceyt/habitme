import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/ui/habit_form/habit_form_sheet.dart';
import 'package:habit_me/core/utils/date_utils.dart';
import 'package:habit_me/data/models/habit.dart';

class CalendarView extends ConsumerStatefulWidget {
  const CalendarView({super.key});

  @override
  ConsumerState<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends ConsumerState<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _showOneTime = true;
  bool _showRecurring = true;

  bool _habitMatchesDate(Habit habit, DateTime day) {
    if (habit.isRecurring) {
      if (!_showRecurring) return false;
      return habit.recurrence!.occursOnDate(habit.anchorAt, day);
    } else {
      if (!_showOneTime) return false;
      final target = habit.oneTimeAt ?? habit.createdAt;
      return AppDateUtils.isSameDay(target, day);
    }
  }

  List<Habit> _habitsForDay(List<Habit> allHabits, DateTime day) {
    return allHabits.where((h) => _habitMatchesDate(h, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitControllerProvider);
    final allHabits = habitsAsync.value ?? const <Habit>[];

    final selectedHabits = _habitsForDay(allHabits, _selectedDay);
    final selectedOneTime = selectedHabits.where((h) => h.isOneTime).toList();
    final selectedRecurring =
        selectedHabits.where((h) => h.isRecurring).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding,
        8,
        AppConstants.pagePadding,
        AppConstants.fabClearance,
      ),
      children: [
        // 1. Calendar Card
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: TableCalendar<Habit>(
            firstDay: DateTime.utc(AppConstants.calendarFirstYear, 1, 1),
            lastDay: DateTime.utc(AppConstants.calendarLastYear, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
            eventLoader: (day) => _habitsForDay(allHabits, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.white),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: AppColors.white,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              weekendStyle: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: true,
              defaultTextStyle: const TextStyle(color: AppColors.white),
              weekendTextStyle: const TextStyle(color: AppColors.white),
              outsideTextStyle: const TextStyle(color: AppColors.border),
              todayTextStyle: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
              todayDecoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceLight,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              selectedTextStyle: const TextStyle(
                color: AppColors.black,
                fontWeight: FontWeight.w700,
              ),
              selectedDecoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();

                final hasOneTime = events.any((h) => h.isOneTime);
                final hasRecurring = events.any((h) => h.isRecurring);

                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasOneTime && hasRecurring) ...[
                        Container(
                          height: 5,
                          width: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: const LinearGradient(
                              colors: [AppColors.green, AppColors.orange],
                            ),
                          ),
                        ),
                      ] else if (hasOneTime) ...[
                        Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: const BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: 5.5,
                          height: 5.5,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Filter Toggles Row
        Row(
          children: [
            Expanded(
              child: _FilterChipButton(
                label: 'One-Time',
                icon: Icons.flag_outlined,
                accentColor: AppColors.green,
                isSelected: _showOneTime,
                onTap: () {
                  setState(() {
                    _showOneTime = !_showOneTime;
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FilterChipButton(
                label: 'Recurring',
                icon: Icons.repeat_rounded,
                accentColor: AppColors.orange,
                isSelected: _showRecurring,
                onTap: () {
                  setState(() {
                    _showRecurring = !_showRecurring;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // 3. Selected Day Habits Summary & Cards
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('EEEE, d MMMM y').format(_selectedDay),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '${selectedHabits.length} habits',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (selectedHabits.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      (!_showOneTime && !_showRecurring)
                          ? 'Both filters are off. Turn on One-Time or Recurring above.'
                          : 'No scheduled habits on this day.',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: AppColors.muted, fontSize: 13.5),
                    ),
                  ),
                ),
              ] else ...[
                if (selectedRecurring.isNotEmpty) ...[
                  _CategoryHeader(
                    title: 'Recurring Habits',
                    count: selectedRecurring.length,
                    accent: AppColors.orange,
                  ),
                  const SizedBox(height: 8),
                  for (final habit in selectedRecurring)
                    _DayHabitItem(habit: habit),
                  const SizedBox(height: 10),
                ],
                if (selectedOneTime.isNotEmpty) ...[
                  _CategoryHeader(
                    title: 'One-Time Habits',
                    count: selectedOneTime.length,
                    accent: AppColors.green,
                  ),
                  const SizedBox(height: 8),
                  for (final habit in selectedOneTime)
                    _DayHabitItem(habit: habit),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.14)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentColor : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.muted,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: isSelected ? accentColor : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.title,
    required this.count,
    required this.accent,
  });

  final String title;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '($count)',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DayHabitItem extends ConsumerWidget {
  const _DayHabitItem({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = habit.isRecurring ? AppColors.orange : AppColors.green;
    final done = habit.isDone;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => HabitFormSheet.show(context, habit: habit),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    habit.isRecurring
                        ? Icons.repeat_rounded
                        : Icons.flag_outlined,
                    size: 17,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: TextStyle(
                          color: done ? AppColors.muted : AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          decoration: (done && habit.isOneTime)
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        habit.isRecurring
                            ? habit.recurrence!.label
                            : (habit.oneTimeAt != null
                                ? AppDateUtils.formatTime(habit.oneTimeAt!)
                                : 'One-time habit'),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Toggle status',
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    ref.read(habitControllerProvider.notifier).toggle(habit.id);
                  },
                  icon: Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: done ? AppColors.green : AppColors.muted,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
