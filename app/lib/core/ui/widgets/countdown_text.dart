import 'dart:async';
import 'package:flutter/material.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/utils/duration_format.dart';

/// A live-ticking countdown widget that updates every second and accurately
/// displays remaining time until [targetDate], or overdue time if passed.
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
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant CountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetDate != widget.targetDate) {
      _now = DateTime.now();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.targetDate.difference(_now);
    final isPast = diff.isNegative;
    final formatted = DurationFormat.formatCountdown(diff, isPast: isPast);
    final displayColor = widget.color ?? (isPast ? AppColors.orange : AppColors.green);

    return Text(
      widget.prefix.isEmpty ? formatted : '${widget.prefix} $formatted',
      style: (widget.textStyle ??
              const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ))
          .copyWith(color: displayColor),
    );
  }
}

