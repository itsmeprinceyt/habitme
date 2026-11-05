import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:habit_me/core/logic/habit_scheduler.dart';
import 'package:habit_me/data/db/app_database.dart';
import 'package:habit_me/data/repositories/habit_repository.dart';
import 'package:habit_me/data/services/notification_service.dart';

/// Handles notification action taps (e.g. "Done") while the app is
/// terminated or in the background. Runs in a separate isolate, so it talks
/// to the database directly instead of going through Riverpod.
@pragma('vm:entry-point')
Future<void> habitNotificationBackgroundHandler(
  NotificationResponse response,
) async {
  try {
    if (response.actionId != NotificationService.doneActionId) return;
    final habitId = response.payload;
    if (habitId == null) return;

    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    final repo = HabitRepository(AppDatabase.instance);
    final habit = await repo.getById(habitId);
    if (habit == null || habit.isDone) return;

    await repo.toggleDone(habit, true);

    final scheduler = HabitScheduler(repo, NotificationService.instance);
    await scheduler.sync(await repo.getAll(), DateTime.now());
  } catch (e) {
    debugPrint('Notification action handler failed: $e');
  }
}
