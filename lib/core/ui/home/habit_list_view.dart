import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_tracker/core/constants/app_constants.dart';
import 'package:habit_tracker/core/logic/providers.dart';
import 'package:habit_tracker/core/theme/app_colors.dart';
import 'package:habit_tracker/core/ui/home/habit_tile.dart';
import 'package:habit_tracker/core/ui/widgets/section_header.dart';
import 'package:habit_tracker/data/models/habit.dart';

class HabitListView extends ConsumerWidget {
  const HabitListView({super.key});

  Widget _tile(BuildContext context, WidgetRef ref, Habit habit) {
    final controller = ref.read(habitControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HabitTile(
        key: ValueKey(habit.id),
        habit: habit,
        onToggle: () => controller.toggle(habit.id),
        onDelete: () {
          final messenger = ScaffoldMessenger.of(context);
          controller.delete(habit.id);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Deleted ${habit.name}')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(habitControllerProvider);
    final active = ref.watch(activeHabitsProvider);
    final completed = ref.watch(completedHabitsProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (error, _) => const Center(
        child: Text(
          'Could not load habits',
          style: TextStyle(color: AppColors.orange),
        ),
      ),
      data: (all) {
        if (all.isEmpty) return const _EmptyState();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.pagePadding,
            8,
            AppConstants.pagePadding,
            AppConstants.fabClearance,
          ),
          children: [
            SectionHeader(
              title: 'Active',
              count: active.length,
              accent: AppColors.green,
            ),
            if (active.isEmpty)
              const _EmptyHint(text: 'All caught up. Nothing active right now.')
            else
              for (final habit in active) _tile(context, ref, habit),
            const SizedBox(height: 14),
            SectionHeader(
              title: 'Completed',
              count: completed.length,
              accent: AppColors.orange,
            ),
            if (completed.isEmpty)
              const _EmptyHint(text: 'Finished habits show up here.')
            else
              for (final habit in completed) _tile(context, ref, habit),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_rounded, size: 56, color: AppColors.green),
            SizedBox(height: 16),
            Text(
              'No habits yet',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tap New habit to add your first one.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ),
      ),
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
