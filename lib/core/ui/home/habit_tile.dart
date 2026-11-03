import 'package:flutter/material.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/data/models/habit.dart';
import 'package:intl/intl.dart';

class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onDelete,
  });

  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  static final _format = DateFormat('d MMM, HH:mm');

  String _fmt(DateTime? date) => date == null ? '' : _format.format(date);

  String get _subtitle {
    final recurrence = habit.recurrence;
    if (recurrence == null) {
      return habit.isDone ? 'Done ${_fmt(habit.completedAt)}' : 'One-time';
    }
    if (habit.isDone && habit.nextDueAt != null) {
      return '${recurrence.label} · resets ${_fmt(habit.nextDueAt)}';
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

    return Dismissible(
      key: ValueKey('dismiss_${habit.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirm(context),
      onDismissed: (_) => onDelete(),
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: done ? AppColors.muted : AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: strike ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: done && habit.isRecurring
                            ? AppColors.orange
                            : AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: done, onChanged: done ? null : (_) => onToggle()),
            ],
          ),
        ),
      ),
    );
  }
}
