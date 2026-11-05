import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/ui/habit_form/recurrence_picker.dart';
import 'package:habit_me/core/ui/widgets/app_switch.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/label.dart';
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
  String? _selectedLabelId;
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
    _selectedLabelId = habit?.labelId;
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
              primary: AppColors.accent,
              surface: AppColors.card,
            ),
      ),
      child: child!,
    );
  }

  Future<void> _quickCreateLabel() async {
    final nameController = TextEditingController();
    final createdName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Create New Label'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Health, Work, Morning',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(nameController.text.trim()),
            child: const Text('Create', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (createdName != null && createdName.isNotEmpty) {
      final label = await ref
          .read(labelControllerProvider.notifier)
          .addLabel(createdName);
      if (mounted) {
        setState(() {
          _selectedLabelId = label.id;
        });
      }
    }
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
          labelId: _selectedLabelId,
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
          labelId: () => _selectedLabelId,
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
            style: TextButton.styleFrom(foregroundColor: AppColors.white),
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
    final labelsAsync = ref.watch(labelControllerProvider);
    final labels = labelsAsync.value ?? const <HabitLabel>[];

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
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
                        color: AppColors.black,
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
                              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
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

                        // Label selection row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'LABEL / GROUP',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            InkWell(
                              onTap: _quickCreateLabel,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.add_rounded, size: 14, color: AppColors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'New Label',
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _labelChip(
                                labelId: null,
                                name: 'None',
                                color: null,
                                isSelected: _selectedLabelId == null,
                                onSelect: () => setState(() => _selectedLabelId = null),
                              ),
                              for (final l in labels) ...[
                                const SizedBox(width: 8),
                                _labelChip(
                                  labelId: l.id,
                                  name: l.name,
                                  color: l.color != null ? Color(l.color!) : AppColors.muted,
                                  isSelected: _selectedLabelId == l.id,
                                  onSelect: () => setState(() => _selectedLabelId = l.id),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Frequency (Habit Type - Neutral stone black design)
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
                                  color: (_notify ? AppColors.white : AppColors.muted).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _notify ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                                  color: _notify ? AppColors.white : AppColors.muted,
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
                              AppSwitch(
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
                          backgroundColor: AppColors.surfaceLight,
                          foregroundColor: AppColors.muted,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: _saving ? null : AppColors.accentGradient,
                          color: _saving ? AppColors.surfaceLight : null,
                          boxShadow: _saving
                              ? null
                              : [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.25,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.black,
                            disabledForegroundColor: AppColors.faint,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.muted,
                                  ),
                                )
                              : Text(
                                  _isEditing ? 'Save Changes' : 'Create Habit',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
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

  Widget _labelChip({
    required String? labelId,
    required String name,
    required Color? color,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    final chipColor = color ?? AppColors.muted;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.accent).withValues(alpha: 0.14)
              : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.accent)
                : AppColors.border,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: chipColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.muted,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
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
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
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
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.55)
                : AppColors.border,
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.accent : AppColors.muted,
                ),
                const Spacer(),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: isSelected ? AppColors.accent : AppColors.muted,
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
    required this.onTap,
  });

  final DateTime dateTime;
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
            const Icon(Icons.calendar_month_outlined, color: AppColors.accent, size: 20),
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
