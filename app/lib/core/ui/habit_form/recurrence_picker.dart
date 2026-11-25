import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  /// The number field and the unit dropdown share this exact height, so the
  /// row reads as one control.
  static const double _controlHeight = 48;

  late final TextEditingController _intervalController;
  late final TextEditingController _countController;
  late RecurUnit _unit;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialValue?.unit ?? RecurUnit.days;
    _intervalController = TextEditingController(
      text: (widget.initialValue?.interval ?? 1).toString(),
    );
    final count = widget.initialValue?.count;
    _countController = TextEditingController(
      text: count == null ? '' : count.toString(),
    );
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  int? get _count {
    final raw = _countController.text.trim();
    if (raw.isEmpty) return null;
    final parsed = int.tryParse(raw);
    return parsed != null && parsed > 0 ? parsed : null;
  }

  void _emit() {
    final interval = int.tryParse(_intervalController.text.trim());
    widget.onChanged(
      interval != null && interval > 0
          ? Recurrence(unit: _unit, interval: interval, count: _count)
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final chipWidth = (constraints.maxWidth - gap) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Two presets per row.
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                _presetChip('Daily', 1, RecurUnit.days, chipWidth),
                _presetChip('Weekly', 7, RecurUnit.days, chipWidth),
                _presetChip('Monthly', 1, RecurUnit.months, chipWidth),
                _presetChip('Every 2 days', 2, RecurUnit.days, chipWidth),
                _presetChip('Hourly', 1, RecurUnit.hours, chipWidth),
              ],
            ),
            const SizedBox(height: 12),

            // "Every [1] [Days]" — both controls share one height.
            _controlRow(
              label: 'Every',
              children: [
                _fieldBox(
                  width: 58,
                  child: TextField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _fieldBox(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<RecurUnit>(
                        value: _unit,
                        isExpanded: true,
                        isDense: true,
                        itemHeight: _controlHeight,
                        dropdownColor: AppColors.card,
                        borderRadius: BorderRadius.circular(10),
                        padding: EdgeInsets.zero,
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
            const SizedBox(height: 10),

            // Optional cap: "Repeat [7] times" — empty means forever.
            _controlRow(
              label: 'Repeat',
              children: [
                _fieldBox(
                  width: 58,
                  child: TextField(
                    controller: _countController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '∞',
                      hintStyle: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onChanged: (_) {
                      // Rebuild so the hint after "times" follows the value.
                      setState(() {});
                      _emit();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    _count == null ? 'times' : 'times, then it stops',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Leave empty to repeat forever.',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        );
      },
    );
  }

  /// Shared frame for the "Every" and "Repeat" rows so they line up visually.
  Widget _controlRow({
    required String label,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ...children,
        ],
      ),
    );
  }

  /// Borderless child inside a fixed-height box. Text, dropdown and borders
  /// are all drawn by this box, so both controls end up pixel-identical.
  Widget _fieldBox({required Widget child, double? width}) {
    return Container(
      width: width,
      height: _controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _presetChip(String label, int number, RecurUnit unit, double width) {
    final isSelected =
        _unit == unit && _intervalController.text.trim() == number.toString();
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => _applyQuickPreset(number, unit),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.14)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.55)
                  : AppColors.border,
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
      ),
    );
  }
}
