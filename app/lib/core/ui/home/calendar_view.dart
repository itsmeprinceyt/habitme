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
import 'package:habit_me/data/models/label.dart';

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

  /// Heat tint for a day tile: light green for a single habit, deeper green
  /// as more unique habits fall on that day.
  Color _heatColor(int count) {
    if (count <= 0) return Colors.transparent;
    // Wider ten-step ramp (1..10+ habits) so busy days stay distinguishable
    // instead of flattening out after only a handful of tasks.
    final level = (count / 10).clamp(0.0, 1.0);
    final alpha = 0.14 + 0.64 * level;
    return AppColors.accent.withValues(alpha: alpha);
  }

  /// A half-rounded square day cell whose fill is the day's habit heatmap.
  Widget _heatDayCell({
    required DateTime day,
    required int count,
    required bool isOutside,
  }) {
    final isSelected = isSameDay(day, _selectedDay);
    final isToday = isSameDay(day, DateTime.now());

    final heat = _heatColor(count);
    final fill = isSelected
        ? AppColors.accent.withValues(
            alpha: count > 0 ? (heat.a + 0.14).clamp(0.3, 0.9) : 0.18,
          )
        : heat;
    final tint = isOutside ? fill.withValues(alpha: fill.a * 0.5) : fill;

    // Pick the number colour from the tile's effective (blended) brightness so
    // the date never disappears, whether the square is empty or deep green.
    final onTile =
        ThemeData.estimateBrightnessForColor(
              Color.alphaBlend(tint, AppColors.card),
            ) ==
            Brightness.dark
        ? AppColors.white
        : AppColors.black;
    final textColor = isOutside ? AppColors.faint : onTile;

    // Slight green glow on every filled tile, growing with the heat level.
    final glow = count > 0
        ? (0.14 + 0.045 * count).clamp(0.14, 0.5) * (isOutside ? 0.5 : 1.0)
        : 0.0;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: tint,
          boxShadow: [
            if (glow > 0)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: glow),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            if (isToday)
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.55),
                blurRadius: 14,
                spreadRadius: 1.5,
              ),
            if (isSelected)
              BoxShadow(
                color: AppColors.white.withValues(alpha: 0.55),
                spreadRadius: 2,
              ),
          ],
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: isToday || isSelected
                ? FontWeight.w700
                : FontWeight.w500,
            shadows: isOutside
                ? null
                : const [Shadow(color: Color(0x73000000), blurRadius: 3)],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitControllerProvider);
    final allHabits = habitsAsync.value ?? const <Habit>[];
    final labelsAsync = ref.watch(labelControllerProvider);
    final labels = labelsAsync.value ?? const <HabitLabel>[];
    final labelMap = {for (final l in labels) l.id: l};

    final selectedHabits = _habitsForDay(allHabits, _selectedDay);
    final selectedOneTime = selectedHabits.where((h) => h.isOneTime).toList();
    final selectedRecurring = selectedHabits
        .where((h) => h.isRecurring)
        .toList();

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
            boxShadow: AppColors.raisedShadow,
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
              markersMaxCount: 0,
              defaultTextStyle: const TextStyle(color: AppColors.white),
              weekendTextStyle: const TextStyle(color: AppColors.white),
              outsideTextStyle: const TextStyle(color: AppColors.border),
            ),
            // Date-wise heatmap: the more unique habits on a day, the
            // deeper green its half-rounded square becomes.
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) => _heatDayCell(
                day: day,
                count: _habitsForDay(allHabits, day).length,
                isOutside: false,
              ),
              todayBuilder: (context, day, focusedDay) => _heatDayCell(
                day: day,
                count: _habitsForDay(allHabits, day).length,
                isOutside: false,
              ),
              selectedBuilder: (context, day, focusedDay) => _heatDayCell(
                day: day,
                count: _habitsForDay(allHabits, day).length,
                isOutside: false,
              ),
              outsideBuilder: (context, day, focusedDay) => _heatDayCell(
                day: day,
                count: _habitsForDay(allHabits, day).length,
                isOutside: true,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Filter Toggles Row (Neutral stone/grey dark buttons)
        Row(
          children: [
            Expanded(
              child: _FilterChipButton(
                label: 'One-Time',
                icon: Icons.flag_outlined,
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
            boxShadow: AppColors.raisedShadow,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
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
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                if (selectedRecurring.isNotEmpty) ...[
                  _CategoryHeader(
                    title: 'Recurring Habits',
                    count: selectedRecurring.length,
                  ),
                  const SizedBox(height: 8),
                  for (final habit in selectedRecurring)
                    _DayHabitItem(
                      habit: habit,
                      label: habit.labelId != null
                          ? labelMap[habit.labelId]
                          : null,
                    ),
                  const SizedBox(height: 10),
                ],
                if (selectedOneTime.isNotEmpty) ...[
                  _CategoryHeader(
                    title: 'One-Time Habits',
                    count: selectedOneTime.length,
                  ),
                  const SizedBox(height: 8),
                  for (final habit in selectedOneTime)
                    _DayHabitItem(
                      habit: habit,
                      label: habit.labelId != null
                          ? labelMap[habit.labelId]
                          : null,
                    ),
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
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
          gradient: isSelected ? AppColors.accentGradient : null,
          color: isSelected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppColors.raisedShadowSmall,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.black : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.black : AppColors.muted,
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
              color: isSelected ? AppColors.black : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
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
  const _DayHabitItem({required this.habit, this.label});

  final Habit habit;
  final HabitLabel? label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = label?.color != null
        ? Color(label!.color!)
        : AppColors.accentDeep;
    final done = habit.isDone;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.raisedShadowSmall,
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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeColor.withValues(alpha: 0.32),
                        themeColor.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    habit.isRecurring
                        ? Icons.repeat_rounded
                        : Icons.flag_outlined,
                    size: 17,
                    color: themeColor,
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
                          color: AppColors.white,
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
