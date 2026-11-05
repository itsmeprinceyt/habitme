import 'dart:async';

import 'package:flutter/material.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/utils/duration_format.dart';

/// A live-ticking countdown widget that updates every second and shows the
/// remaining time until [targetDate] as "2h 48m 21s", or the overdue time once
/// it has passed. Leading zero units are omitted, so it reads "48m 21s" / "9s".
class CountdownText extends StatefulWidget {
  const CountdownText({
    super.key,
    required this.targetDate,
    this.prefix = '',
    this.textStyle,
    this.color,
  });

  final DateTime targetDate;
  final String prefix;
  final TextStyle? textStyle;
  final Color? color;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    // The timer only drives rebuilds: the remaining time is always read from a
    // fresh DateTime.now() in build, so a delayed frame can never show a
    // stale value or skip a second.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.targetDate.difference(DateTime.now());
    final isPast = diff.isNegative;
    final formatted = DurationFormat.formatCountdown(diff, isPast: isPast);
    final displayColor =
        widget.color ?? (isPast ? AppColors.orange : AppColors.accent);

    return Text(
      widget.prefix.isEmpty ? formatted : '${widget.prefix} $formatted',
      style:
          (widget.textStyle ??
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
              .copyWith(
                color: displayColor,
                // Fixed width digits stop the ticking seconds from shifting.
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
    );
  }
}
