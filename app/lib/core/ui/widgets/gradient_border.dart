import 'package:flutter/material.dart';
import 'package:habit_me/core/theme/app_colors.dart';

/// Wraps [child] in a rounded container with a gradient border, used for
/// elevated panels that should catch a subtle sheen of light.
class GradientBorder extends StatelessWidget {
  const GradientBorder({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding = const EdgeInsets.all(1),
    this.gradient,
    this.color,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
        color: gradient == null ? (color ?? AppColors.border) : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius - padding.horizontal / 2),
          color: AppColors.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}
