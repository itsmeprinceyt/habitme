import 'package:flutter/material.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/ui/widgets/countdown_text.dart';
import 'package:habit_me/core/utils/date_utils.dart';
import 'package:habit_me/data/models/habit.dart';

class HabitTile extends StatefulWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile> {
  bool _isExpanded = false;

  Habit get habit => widget.habit;

  DateTime? get _relevantNextDate {
    if (habit.isRecurring) {
      return habit.nextDueAt;
    }
    return habit.oneTimeAt;
  }

  String get _summarySubtitle {
    final recurrence = habit.recurrence;
    if (recurrence == null) {
      if (habit.isDone) {
        return habit.completedAt != null
            ? 'Completed ${AppDateUtils.formatRelativeDateTime(habit.completedAt!)}'
            : 'Completed';
      }
      if (habit.oneTimeAt != null) {
        return 'Scheduled: ${AppDateUtils.formatRelativeDateTime(habit.oneTimeAt!)}';
      }
      return 'One-time habit';
    }

    if (habit.isDone && habit.nextDueAt != null) {
      return '${recurrence.label} · Next: ${AppDateUtils.formatRelativeDateTime(habit.nextDueAt!)}';
    }
    return recurrence.label;
  }

  Future<bool> _confirm(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Delete habit?'),
        content: Text(
          habit.name,
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.white),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accent = habit.isRecurring ? AppColors.orange : AppColors.green;
    final done = habit.isDone;
    final strike = done && habit.isOneTime;
    final nextTarget = _relevantNextDate;

    return Dismissible(
      key: ValueKey('dismiss_${habit.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirm(context),
      onDismissed: (_) => widget.onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.orange,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isExpanded
                    ? accent.withValues(alpha: 0.5)
                    : AppColors.border,
                width: _isExpanded ? 1.2 : 1.0,
              ),
              boxShadow: _isExpanded
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon + Name & Subtitle + Action Buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: done ? 0.08 : 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        habit.isRecurring
                            ? Icons.repeat_rounded
                            : Icons.flag_outlined,
                        size: 20,
                        color: done ? AppColors.muted : accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            style: TextStyle(
                              color: done ? AppColors.muted : AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              decoration:
                                  strike ? TextDecoration.lineThrough : null,
                              decorationColor: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _summarySubtitle,
                            style: TextStyle(
                              color: done && habit.isRecurring
                                  ? AppColors.orange
                                  : AppColors.muted,
                              fontSize: 12.5,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit habit',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                    Switch(
                      value: done,
                      onChanged: (_) => widget.onToggle(),
                    ),
                  ],
                ),

                // Expanded Section: Next Due Date & Live Countdown Timer
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (nextTarget != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  habit.isRecurring
                                      ? (done ? 'Next occurrence:' : 'Due date:')
                                      : 'Scheduled date:',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    AppDateUtils.formatDateTime(nextTarget),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 15,
                                      color: accent,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Countdown:',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                CountdownText(
                                  targetDate: nextTarget,
                                  textStyle: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (done && habit.completedAt != null) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 15,
                                  color: AppColors.green,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Completed at:',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    AppDateUtils.formatDateTime(habit.completedAt!),
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 15,
                                  color: AppColors.muted,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'No specific target time set',
                                    style: TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (habit.notify) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  size: 14,
                                  color: AppColors.green,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Notifications enabled for this habit',
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
