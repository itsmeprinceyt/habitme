import 'package:flutter/material.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/core/theme/app_colors.dart';

class GuidePage extends StatelessWidget {
  const GuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide & How it Works')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backdropGradient),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          children: [
            // App Motive Section
            _buildSectionCard(
              icon: Icons.lightbulb_outline_rounded,
              iconColor: AppColors.orange,
              title: 'Motive Behind HabitMe',
              content: 'It gets really busy to handle repetitive tasks every day, week, or month. HabitMe was created so you can easily track, organize, and automate reminders for everything in one clean place without missing a beat.',
            ),
            const SizedBox(height: 16),

            // How to Create Habits
            _buildSectionCard(
              icon: Icons.add_task_rounded,
              iconColor: AppColors.green,
              title: 'Creating a Habit',
              content:
                  'Tap the "+ New habit" button at the bottom of the home screen.\n\n'
                  '1. Name: Enter what habit or task you want to perform.\n'
                  '2. Label (Optional): Organize your habits into custom color-coded groups.\n'
                  '3. Schedule Mode: Pick between Recurring or One-Time.\n'
                  '4. Remind me: Toggle ON to get notifications on your device.',
            ),
            const SizedBox(height: 16),

            // Modes Explained
            _buildSectionCard(
              icon: Icons.tune_rounded,
              iconColor: AppColors.accent,
              title: 'Modes: Recurring vs One-Time',
              content:
                  '• Recurring Habit: For routines you repeat regularly (every X minutes, hours, days, months, or years). When you mark it done or when the time passes, it automatically rolls over to the next occurrence.\n\n'
                  '• One-Time Habit: For tasks you only need to do once at a specific date and time. Once completed, it stays completed with no future countdown.',
            ),
            const SizedBox(height: 16),

            // Managing & Labels
            _buildSectionCard(
              icon: Icons.label_outline_rounded,
              iconColor: Colors.purpleAccent,
              title: 'Labels & Views',
              content:
                  '• Labels: Manage and assign custom labels (Work, Health, Personal, etc.) with custom colors from the sidebar.\n\n'
                  '• List & Calendar: Switch between List View and Calendar View using the toggle in the top bar to visualize your schedule over the month.',
            ),
            const SizedBox(height: 16),

            // Notifications & OS 60-Reminder Note
            _buildNoteCard(
              title: 'Important Note on Notifications',
              content:
                  'To respect OS battery life and device limits (iOS/Android), the app automatically registers up to 60 of your nearest upcoming reminders into the system alarm manager in chronological order.\n\n'
              'Simply open the app occasionally as you check off habits — opening the app automatically updates and rolls the next batch of 60 reminders forward so you never miss a notification!',
            ),
            const SizedBox(height: 24),

            // Version info at bottom
            Center(
              child: Text(
                '${AppConstants.appName} • ${AppConstants.appTagline}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard({required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
