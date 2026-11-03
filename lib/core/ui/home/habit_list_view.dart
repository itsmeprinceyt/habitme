import 'package:flutter/material.dart';
import 'package:habit_tracker/core/constants/app_constants.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/ui/widgets/section_header.dart';

class HabitListView extends StatelessWidget {
  const HabitListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.pagePadding,
        8,
        AppConstants.pagePadding,
        AppConstants.fabClearance,
      ),
      children: const [
        SectionHeader(title: 'Active', count: 0, accent: AppColors.green),
        _EmptyHint(text: 'Nothing here yet. Tap New habit to add one.'),
        SizedBox(height: 24),
        SectionHeader(title: 'Completed', count: 0, accent: AppColors.orange),
        _EmptyHint(text: 'Finished habits show up here.'),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.muted, fontSize: 14),
      ),
    );
  }
}
