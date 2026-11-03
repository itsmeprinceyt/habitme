import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Interval',
              hintText: '1',
            ),
            validator: (value) {
              final interval = int.tryParse(value?.trim() ?? '');
              if (interval == null || interval < 1) {
                return 'Enter a number greater than 0';
              }
              if (interval > 9999) return 'Maximum is 9999';
              return null;
            },
            onChanged: (_) => _emit(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<RecurUnit>(
            initialValue: _unit,
            decoration: const InputDecoration(labelText: 'Unit'),
            items: RecurUnit.values
                .map(
                  (unit) =>
                      DropdownMenuItem(value: unit, child: Text(unit.label)),
                )
                .toList(),
            onChanged: (unit) {
              if (unit == null) return;
              setState(() => _unit = unit);
              _emit();
            },
          ),
        ),
      ],
    );
  }
}
