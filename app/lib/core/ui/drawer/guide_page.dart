import 'package:flutter/material.dart';
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
              title: 'Why HabitMe Exists',
              content:
                  'We repeat the same things day after day — and that is exactly how they become our habits.\n\n'
                  'But the moment you take a break, that habit starts to distort. One skipped day turns into a skipped week, and things quietly slip out of your hands.\n\n'
                  'HabitMe was built so you can create habits for yourself, stay consistent even after a pause, and remain obedient to your goals and your own betterment — without missing a beat.',
            ),
            const SizedBox(height: 16),

            // How to Create Habits
            _buildSectionCard(
              icon: Icons.add_task_rounded,
              iconColor: AppColors.green,
              title: 'Creating a Habit',
              content:
                  'Tap the "+ New habit" button at the bottom of the home screen.\n\n'
                  '1. Name: Enter the habit or task you want to stay committed to.\n'
                  '2. Description / Notes (Optional): Add why it matters or any detail you want to remember. It appears when you expand the habit.\n'
                  '3. Label (Optional): Organize your habits into custom color-coded groups.\n'
                  '4. Schedule Mode: Pick between Recurring or One-Time.\n'
                  '5. Remind me: Toggle ON so the habit is brought back to you when it is due.',
            ),
            const SizedBox(height: 16),

            // Modes Explained
            _buildSectionCard(
              icon: Icons.tune_rounded,
              iconColor: AppColors.accent,
              title: 'Modes: Recurring vs One-Time',
              content:
                  '• Recurring Habit: For routines you repeat regularly (every X minutes, hours, days, months, or years). When you mark it done or when the time passes, it automatically rolls over to the next occurrence.\n\n'
                  '• Repeat Count: Set how many times a recurring habit should occur. Leave it empty for forever — after the last occurrence the habit stops rolling over and finishes on its own.\n\n'
                  '• One-Time Habit: For tasks you only need to do once at a specific date and time. Once completed, it stays completed with no future countdown.',
            ),
            const SizedBox(height: 16),

            // Managing & Labels
            _buildSectionCard(
              icon: Icons.label_outline_rounded,
              iconColor: Colors.purpleAccent,
              title: 'Labels & Views',
              content:
                  '• Labels: Manage and assign custom labels (Work, Health, Personal, etc.) with custom colors from the sidebar. The Manage Labels screen also shows how many habits are assigned to each label.\n\n'
                  '• Descriptions: Any note you add to a habit stays attached to it and can be read from the expanded habit card.\n\n'
                  '• List & Calendar: Switch between List View and Calendar View using the toggle in the top bar to visualize your schedule over the month.',
            ),
            const SizedBox(height: 16),

            // Calendar Heatmap
            _buildSectionCard(
              icon: Icons.calendar_month_rounded,
              iconColor: AppColors.accentDeep,
              title: 'Reading the Calendar Heatmap',
              content:
                  'Each day is shaded by how much of that day you actually completed, not by how many habits were planned.\n\n'
                  '• The shade is completed ÷ scheduled. Complete 1 of 2 habits and the day is 50% green; complete 2 of 2 and it is fully green — 1 of 5 is only 20%.\n'
                  '• A day with habits but nothing completed stays blank, so an empty square never pretends the day went well.\n'
                  '• Future days show a light outline as “planned”, with no green until the day arrives.\n'
                  '• Each habit counts once per day, so toggling the same habit repeatedly cannot inflate the shade.\n'
                  '• The One-Time / Recurring filters change the list below, not the heatmap, so the month always tells the same story.\n\n'
                  'Tap any day to see its exact progress (for example “2 of 5 done · 40%”) and which habits were completed on that day.',
            ),
            const SizedBox(height: 16),

            // Notifications
            _buildNoteCard(
              title: 'Reminders & Notifications',
              content:
                  'Reminders are handed directly to your phone’s alarm system, so they still arrive when HabitMe is closed or not running in the background.\n\n'
                  'When a reminder appears, tap “Done” to mark the habit complete without opening the app.\n\n'
                  'Reminders you have already seen are cleared from the notification shade the next time you open HabitMe, so only fresh reminders stay visible.',
            ),
            const SizedBox(height: 24),
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
        boxShadow: AppColors.raisedShadow,
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
        boxShadow: [
          ...AppColors.raisedShadow,
          BoxShadow(
            color: AppColors.orange.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
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
