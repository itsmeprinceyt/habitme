import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/core/theme/app_colors.dart';
import 'package:habit_me/core/ui/home/habit_tile.dart';
import 'package:habit_me/core/ui/habit_form/habit_form_sheet.dart';
import 'package:habit_me/core/ui/widgets/label_subheader.dart';
import 'package:habit_me/core/ui/widgets/section_header.dart';
import 'package:habit_me/core/utils/expansion_preferences.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/label.dart';

class HabitListView extends ConsumerStatefulWidget {
  const HabitListView({super.key});

  @override
  ConsumerState<HabitListView> createState() => _HabitListViewState();
}

class _HabitListViewState extends ConsumerState<HabitListView> {
  late bool _isActiveExpanded;
  late bool _isCompletedExpanded;

  @override
  void initState() {
    super.initState();
    _isActiveExpanded = ExpansionPreferences.instance.getBool(
      'section_active',
      defaultValue: true,
    );
    _isCompletedExpanded = ExpansionPreferences.instance.getBool(
      'section_completed',
      defaultValue: true,
    );
  }

  void _toggleActive() {
    setState(() {
      _isActiveExpanded = !_isActiveExpanded;
    });
    ExpansionPreferences.instance.setBool('section_active', _isActiveExpanded);
  }

  void _toggleCompleted() {
    setState(() {
      _isCompletedExpanded = !_isCompletedExpanded;
    });
    ExpansionPreferences.instance.setBool(
      'section_completed',
      _isCompletedExpanded,
    );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
    Map<String, HabitLabel> labelMap,
  ) {
    final controller = ref.read(habitControllerProvider.notifier);
    final label = habit.labelId != null ? labelMap[habit.labelId] : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HabitTile(
        key: ValueKey(habit.id),
        habit: habit,
        label: label,
        onToggle: () => controller.toggle(habit.id),
        onEdit: () => HabitFormSheet.show(context, habit: habit),
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

  Widget _buildGroupedSection({
    required BuildContext context,
    required WidgetRef ref,
    required String sectionKey,
    required List<Habit> habits,
    required Map<String, HabitLabel> labelMap,
    required List<HabitLabel> allLabels,
  }) {
    if (habits.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group habits by labelId
    final Map<String?, List<Habit>> grouped = {};
    for (final habit in habits) {
      grouped.putIfAbsent(habit.labelId, () => []).add(habit);
    }

    // Create sorted label groups (A-Z)
    final List<HabitLabel> presentLabels = [];
    for (final l in allLabels) {
      if (grouped.containsKey(l.id)) {
        presentLabels.add(l);
      }
    }
    presentLabels.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final unlabelled = grouped[null] ?? const <Habit>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final label in presentLabels) ...[
          _LabelGroupView(
            key: ValueKey('${sectionKey}_label_${label.id}'),
            prefKey: '${sectionKey}_label_${label.id}',
            label: label,
            habits: grouped[label.id]!,
            tileBuilder: (h) => _tile(context, ref, h, labelMap),
          ),
          const SizedBox(height: 6),
        ],
        if (unlabelled.isNotEmpty) ...[
          _LabelGroupView(
            key: ValueKey('${sectionKey}_label_unassigned'),
            prefKey: '${sectionKey}_label_unassigned',
            label: null,
            habits: unlabelled,
            tileBuilder: (h) => _tile(context, ref, h, labelMap),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(habitControllerProvider);
    final active = ref.watch(activeHabitsProvider);
    final completed = ref.watch(completedHabitsProvider);
    final labelsAsync = ref.watch(labelControllerProvider);
    final labels = labelsAsync.value ?? const <HabitLabel>[];
    final labelMap = {for (final l in labels) l.id: l};

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
            // Active Section
            SectionHeader(
              title: 'Active',
              count: active.length,
              accent: AppColors.green,
              isExpanded: _isActiveExpanded,
              onToggleExpand: _toggleActive,
            ),
            AnimatedCrossFade(
              firstChild: active.isEmpty
                  ? const _EmptyHint(
                      text: 'All caught up. Nothing active right now.',
                    )
                  : _buildGroupedSection(
                      context: context,
                      ref: ref,
                      sectionKey: 'active',
                      habits: active,
                      labelMap: labelMap,
                      allLabels: labels,
                    ),
              secondChild: const SizedBox(width: double.infinity),
              crossFadeState: _isActiveExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 240),
            ),
            const SizedBox(height: 14),

            // Completed Section
            SectionHeader(
              title: 'Completed',
              count: completed.length,
              accent: AppColors.orange,
              isExpanded: _isCompletedExpanded,
              onToggleExpand: _toggleCompleted,
            ),
            AnimatedCrossFade(
              firstChild: completed.isEmpty
                  ? const _EmptyHint(text: 'Finished habits show up here.')
                  : _buildGroupedSection(
                      context: context,
                      ref: ref,
                      sectionKey: 'completed',
                      habits: completed,
                      labelMap: labelMap,
                      allLabels: labels,
                    ),
              secondChild: const SizedBox(width: double.infinity),
              crossFadeState: _isCompletedExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 240),
            ),
          ],
        );
      },
    );
  }
}

class _LabelGroupView extends StatefulWidget {
  const _LabelGroupView({
    super.key,
    required this.prefKey,
    required this.label,
    required this.habits,
    required this.tileBuilder,
  });

  final String prefKey;
  final HabitLabel? label;
  final List<Habit> habits;
  final Widget Function(Habit) tileBuilder;

  @override
  State<_LabelGroupView> createState() => _LabelGroupViewState();
}

class _LabelGroupViewState extends State<_LabelGroupView> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = ExpansionPreferences.instance.getBool(
      widget.prefKey,
      defaultValue: true,
    );
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    ExpansionPreferences.instance.setBool(widget.prefKey, _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabelSubheader(
          label: widget.label,
          count: widget.habits.length,
          isExpanded: _isExpanded,
          onToggleExpand: _toggle,
        ),
        const SizedBox(height: 4),
        AnimatedCrossFade(
          firstChild: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.habits.map(widget.tileBuilder).toList(),
          ),
          secondChild: const SizedBox(width: double.infinity),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
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
