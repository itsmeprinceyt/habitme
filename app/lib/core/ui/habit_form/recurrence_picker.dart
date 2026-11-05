import 'package:flutter/material.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/data/models/recurrence.dart';

class RecurrencePicker extends StatefulWidget {
  const RecurrencePicker({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  final Recurrence? initialValue;
  final ValueChanged<Recurrence?> onChanged;

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  late final TextEditingController _intervalController;
  late RecurUnit _unit;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialValue?.unit ?? RecurUnit.days;
    _intervalController = TextEditingController(
      text: (widget.initialValue?.interval ?? 1).toString(),
    );
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  void _emit() {
    final interval = int.tryParse(_intervalController.text.trim());
    widget.onChanged(
      interval != null && interval > 0
          ? Recurrence(unit: _unit, interval: interval)
          : null,
    );
  }

  void _applyQuickPreset(int number, RecurUnit unit) {
    setState(() {
      _unit = unit;
      _intervalController.text = number.toString();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Presets Row for natural one-tap selection
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _presetChip('Daily', 1, RecurUnit.days),
              const SizedBox(width: 6),
              _presetChip('Weekly', 7, RecurUnit.days),
              const SizedBox(width: 6),
              _presetChip('Monthly', 1, RecurUnit.months),
              const SizedBox(width: 6),
              _presetChip('Every 2 days', 2, RecurUnit.days),
              const SizedBox(width: 6),
              _presetChip('Hourly', 1, RecurUnit.hours),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Custom Repeat builder with clear conversational phrasing
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Every',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 65,
                child: TextFormField(
                  controller: _intervalController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.accentDeep),
                    ),
                  ),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<RecurUnit>(
                      value: _unit,
                      isExpanded: true,
                      dropdownColor: AppColors.card,
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppColors.muted,
                      ),
                      items: RecurUnit.values
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(
                                unit.label,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (unit) {
                        if (unit == null) return;
                        setState(() => _unit = unit);
                        _emit();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetChip(String label, int number, RecurUnit unit) {
    final isSelected =
        _unit == unit && _intervalController.text.trim() == number.toString();
    return InkWell(
      onTap: () => _applyQuickPreset(number, unit),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.muted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
