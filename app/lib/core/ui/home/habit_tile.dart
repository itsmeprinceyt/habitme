import 'package:flutter/material.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/ui/widgets/app_switch.dart';
import 'package:habit_me/core/ui/widgets/countdown_text.dart';
import 'package:habit_me/core/ui/widgets/gradient_border.dart';
import 'package:habit_me/core/utils/date_utils.dart';
import 'package:habit_me/core/utils/expansion_preferences.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/label.dart';

class HabitTile extends StatefulWidget {
  const HabitTile({
    super.key,
    required this.habit,
    this.label,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Habit habit;
  final HabitLabel? label;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<HabitTile> {
  late bool _isExpanded;

  Habit get habit => widget.habit;

  @override
  void initState() {
    super.initState();
    _isExpanded = ExpansionPreferences.instance.getBool(
      'tile_${habit.id}',
      defaultValue: false,
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    ExpansionPreferences.instance.setBool('tile_${habit.id}', _isExpanded);
  }

  DateTime? get _relevantNextDate {
    if (habit.isRecurring) {
      return habit.nextDueAt;
    }
    // Hide next date for completed one-time habits
    if (habit.isDone) return null;
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
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    // Theme color: If label has color use it, otherwise neutral grey (muted)
    final themeColor = label?.color != null
        ? Color(label!.color!)
        : AppColors.accentDeep;
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
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.muted,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _toggleExpanded,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: label?.color != null
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeColor.withValues(alpha: 0.12),
                        AppColors.card,
                        AppColors.card,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    )
                  : null,
              color: label?.color != null ? null : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: label?.color != null
                    ? themeColor.withValues(alpha: _isExpanded ? 0.55 : 0.30)
                    : (_isExpanded
                        ? AppColors.white.withValues(alpha: 0.25)
                        : AppColors.border),
                width: _isExpanded ? 1.2 : 1.0,
              ),
              boxShadow: _isExpanded && label?.color != null
                  ? [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.08),
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
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: done
                              ? const [AppColors.surfaceLight, AppColors.surface]
                              : [
                                  themeColor.withValues(alpha: 0.30),
                                  themeColor.withValues(alpha: 0.10),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: themeColor.withValues(
                            alpha: done ? 0.18 : 0.38,
                          ),
                        ),
                      ),
                      child: Icon(
                        habit.isRecurring
                            ? Icons.repeat_rounded
                            : Icons.flag_outlined,
                        size: 20,
                        color: done ? AppColors.muted : themeColor,
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
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12.5,
                              height: 1.25,
                            ),
                          ),
                          if (label != null) ...[
                            const SizedBox(height: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (label.color != null
                                        ? Color(label.color!)
                                        : AppColors.muted)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: (label.color != null
                                          ? Color(label.color!)
                                          : AppColors.muted)
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.label_outline_rounded,
                                    size: 11,
                                    color: label.color != null
                                        ? Color(label.color!)
                                        : AppColors.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    label.name,
                                    style: TextStyle(
                                      color: label.color != null
                                          ? Color(label.color!)
                                          : AppColors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit habit',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                    AppSwitch(
                      value: done,
                      onChanged: (_) => widget.onToggle(),
                    ),
                  ],
                ),

                // Expanded Section: Next Due Date & Live Countdown Timer & Label info
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: GradientBorder(
                        radius: 14,
                        padding: const EdgeInsets.all(1),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: label?.color != null
                              ? [
                                  themeColor.withValues(alpha: 0.5),
                                  AppColors.border,
                                  themeColor.withValues(alpha: 0.5),
                                ]
                              : const [
                                  AppColors.borderStrong,
                                  AppColors.border,
                                  AppColors.borderStrong,
                                ],
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            gradient: label?.color != null
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color.alphaBlend(
                                        themeColor.withValues(alpha: 0.14),
                                        const Color(0xFF1B2620),
                                      ),
                                      const Color(0xFF141C17),
                                    ],
                                  )
                                : AppColors.surfaceGradient,
                          ),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (label != null) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.label_rounded,
                                  size: 15,
                                  color: label.color != null
                                      ? Color(label.color!)
                                      : AppColors.muted,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Label:',
                                  style: TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    label.name,
                                    style: TextStyle(
                                      color: label.color != null
                                          ? Color(label.color!)
                                          : AppColors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (nextTarget != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: themeColor,
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
                                      color: themeColor,
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
