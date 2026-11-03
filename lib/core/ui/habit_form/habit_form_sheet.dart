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

  static Future<void> show(BuildContext context, {Habit? habit}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
        const SnackBar(content: Text('This reminder time is in the past.')),
      );
    }
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme
            .copyWith(primary: AppColors.green, surface: AppColors.card),
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
        const SnackBar(content: Text('Choose a reminder time in the future.')),
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
          anchorAt: now,
          now: now,
        );
        await ref.read(habitControllerProvider.notifier).add(habit);
      } else {
        final recurrenceChanged =
            existing.recurrence?.unit != recurrence?.unit ||
            existing.recurrence?.interval != recurrence?.interval;
        final typeChanged = existing.isRecurring != _isRecurring;
        final resetSchedule = typeChanged || recurrenceChanged;
        final anchor = _isRecurring
            ? (resetSchedule ? now : existing.anchorAt)
            : existing.anchorAt;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save habit: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit habit' : 'New habit',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Habit name',
                  hintText: 'e.g. Read 10 pages',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'HABIT TYPE',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Recurring'),
                    icon: Icon(Icons.repeat_rounded),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('One-time'),
                    icon: Icon(Icons.flag_outlined),
                  ),
                ],
                selected: {_isRecurring},
                onSelectionChanged: (selection) {
                  setState(() => _isRecurring = selection.first);
                },
              ),
              const SizedBox(height: 20),
              if (_isRecurring) ...[
                Text(
                  'REPEAT EVERY',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                RecurrencePicker(
                  key: ValueKey(_recurrence),
                  initialValue: _recurrence,
                  onChanged: (value) => _recurrence = value,
                ),
                const SizedBox(height: 8),
                Text(
                  'The next occurrence is calculated from the habit start time.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ] else ...[
                Text(
                  'REMINDER DATE & TIME',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.green,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            DateFormat('EEE, d MMM yyyy · hh:mm a')
                                .format(_oneTimeAt),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _notify,
                activeColor: AppColors.green,
                title: const Text('Notifications'),
                subtitle: Text(
                  _notify
                      ? 'Receive reminders for this habit'
                      : 'No notifications will be scheduled',
                  style: const TextStyle(color: AppColors.muted),
                ),
                secondary: const Icon(Icons.notifications_active_outlined),
                onChanged: (value) => setState(() => _notify = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving
                        ? 'Saving...'
                        : (_isEditing ? 'Save changes' : 'Create habit'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
