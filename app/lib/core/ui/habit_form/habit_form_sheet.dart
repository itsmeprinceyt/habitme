import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/ui/habit_form/recurrence_picker.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/recurrence.dart';

class HabitFormSheet extends ConsumerStatefulWidget {
  const HabitFormSheet({super.key, this.habit});

  final Habit? habit;

  /// Shows the habit creation / editing modal as a responsive center popup dialog.
  static Future<void> show(BuildContext context, {Habit? habit}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => HabitFormSheet(habit: habit),
    );
  }

  @override
  ConsumerState<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<HabitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late bool _isRecurring;
  late bool _notify;
  late DateTime _oneTimeAt;
  late DateTime _recurringAt;
  Recurrence? _recurrence;
  bool _saving = false;

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _nameController = TextEditingController(text: habit?.name ?? '');
    _isRecurring = habit?.isRecurring ?? true;
    _notify = habit?.notify ?? false;
    _recurrence =
        habit?.recurrence ??
        const Recurrence(unit: RecurUnit.days, interval: 1);
    _oneTimeAt =
        habit?.oneTimeAt ?? DateTime.now().add(const Duration(hours: 1));
    _recurringAt = habit?.anchorAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _oneTimeAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: _pickerTheme,
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_oneTimeAt),
      builder: _pickerTheme,
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _oneTimeAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });

    if (_oneTimeAt.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note: This target time is set in the past.')),
      );
    }
  }

  Future<void> _pickRecurringDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _recurringAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: _pickerTheme,
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recurringAt),
      builder: _pickerTheme,
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _recurringAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.green,
              surface: AppColors.card,
            ),
      ),
      child: child!,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final now = DateTime.now();
    final recurrence = _isRecurring ? _recurrence : null;

    if (_isRecurring && recurrence == null) return;
    if (!_isRecurring && _notify && !_oneTimeAt.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a reminder time in the future.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final existing = widget.habit;
      if (existing == null) {
        final habit = Habit.create(
          name: name,
          recurrence: recurrence,
          notify: _notify,
          oneTimeAt: _isRecurring ? null : _oneTimeAt,
          anchorAt: _isRecurring ? _recurringAt : now,
          now: now,
        );
        await ref.read(habitControllerProvider.notifier).add(habit);
      } else {
        final recurrenceChanged =
            existing.recurrence?.unit != recurrence?.unit ||
            existing.recurrence?.interval != recurrence?.interval;

        final typeChanged = existing.isRecurring != _isRecurring;
        final anchorChanged =
            _isRecurring && !existing.anchorAt.isAtSameMomentAs(_recurringAt);

        final resetSchedule = typeChanged || recurrenceChanged || anchorChanged;

        final anchor = _isRecurring ? _recurringAt : existing.anchorAt;
        final nextDue = recurrence == null
            ? null
            : (resetSchedule || existing.nextDueAt == null
                ? recurrence.nextAfter(anchor, now)
                : existing.nextDueAt);

        final updated = existing.copyWith(
          name: name,
          recurrence: () => recurrence,
          notify: _notify,
          oneTimeAt: () => _isRecurring ? null : _oneTimeAt,
          anchorAt: anchor,
          nextDueAt: () => nextDue,
          isDone: typeChanged ? false : existing.isDone,
          completedAt: () => typeChanged ? null : existing.completedAt,
          updatedAt: now,
        );
        await ref.read(habitControllerProvider.notifier).updateHabit(updated);
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Habit updated' : 'Habit created')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save habit: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final existing = widget.habit;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Delete habit?'),
        content: Text(
          '"${existing.name}" will be permanently removed.',
          style: const TextStyle(color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.orange),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    try {
      await ref.read(habitControllerProvider.notifier).delete(existing.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Habit deleted')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete habit: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 420;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border, width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
                        color: AppColors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Habit' : 'Create New Habit',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                    ),
                  ],
                ),
              ),

              // Scrollable Form Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Habit Name
                        const Text(
                          'HABIT TITLE',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          autofocus: !_isEditing,
                          maxLength: 100,
                          textCapitalization: TextCapitalization.sentences,
                          style: const TextStyle(color: AppColors.white, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'e.g. Drink 2L water, Morning run, Read book',
                            hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13.5),
                            filled: true,
                            fillColor: AppColors.card,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please name your habit';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // How often does this happen? (Habit Type)
                        const Text(
                          'FREQUENCY',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _TypeSelectionCard(
                                title: 'Recurring',
                                subtitle: 'Repeats periodically',
                                icon: Icons.repeat_rounded,
                                accentColor: AppColors.orange,
                                isSelected: _isRecurring,
                                onTap: () => setState(() => _isRecurring = true),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TypeSelectionCard(
                                title: 'One-Time',
                                subtitle: 'Single target event',
                                icon: Icons.flag_outlined,
                                accentColor: AppColors.green,
                                isSelected: !_isRecurring,
                                onTap: () => setState(() => _isRecurring = false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Time & Schedule Section
                        if (_isRecurring) ...[
                          const Text(
                            'HOW OFTEN DOES IT REPEAT?',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RecurrencePicker(
                            key: ValueKey(_recurrence),
                            initialValue: _recurrence,
                            onChanged: (value) => _recurrence = value,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'FIRST OCCURRENCE / START TIME',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DateTimeButton(
                            dateTime: _recurringAt,
                            accentColor: AppColors.orange,
                            onTap: _pickRecurringDateTime,
                          ),
                        ] else ...[
                          const Text(
                            'SCHEDULED TIME',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DateTimeButton(
                            dateTime: _oneTimeAt,
                            accentColor: AppColors.green,
                            onTap: _pickDateTime,
                          ),
                        ],

                        const SizedBox(height: 18),

                        // Notification Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (_notify ? AppColors.green : AppColors.muted).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _notify ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                                  color: _notify ? AppColors.green : AppColors.muted,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Remind Me',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _notify ? 'Notification will be sent' : 'No notifications',
                                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _notify,
                                onChanged: (value) => setState(() => _notify = value),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    if (_isEditing) ...[
                      IconButton(
                        tooltip: 'Delete Habit',
                        onPressed: _saving ? null : _delete,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.orange.withValues(alpha: 0.12),
                          foregroundColor: AppColors.orange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
                              )
                            : Text(
                                _isEditing ? 'Save Changes' : 'Create Habit',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSelectionCard extends StatelessWidget {
  const _TypeSelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.border,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: isSelected ? accentColor : AppColors.muted),
                const Spacer(),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? accentColor : AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeButton extends StatelessWidget {
  const _DateTimeButton({
    required this.dateTime,
    required this.accentColor,
    required this.onTap,
  });

  final DateTime dateTime;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_outlined, color: accentColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                DateFormat('EEE, d MMM yyyy · hh:mm a').format(dateTime),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.edit_calendar_outlined, size: 18, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
