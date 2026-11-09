import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/core/theme/app_theme.dart';
import 'package:habit_me/core/ui/home/home_page.dart';
import 'package:habit_me/data/services/notification_service.dart';

class HabitApp extends ConsumerStatefulWidget {
  const HabitApp({super.key});

  @override
  ConsumerState<HabitApp> createState() => _HabitAppState();
}

class _HabitAppState extends ConsumerState<HabitApp>
    with WidgetsBindingObserver {
  /// Occurrences land on whole minutes, so a roll is noticed just after the
  /// boundary rather than exactly on it.
  static const _rollPad = Duration(milliseconds: 300);

  /// Floor for the wait so a reconcile that keeps failing can't spin.
  static const _minWait = Duration(seconds: 2);

  /// Safety net for when no habit has a next occurrence at all.
  static const _maxWait = Duration(minutes: 5);

  Timer? _dueTicker;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.onDoneAction = (habitId) {
      ref
          .read(habitControllerProvider.notifier)
          .markDoneFromNotification(habitId);
    };
    NotificationService.instance.onFired = (habitId, at) {
      ref.read(habitSchedulerProvider).onReminderFired(habitId, at);
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.checkPermissionsOnLaunch().catchError(
        (_) {},
      );
    });

    _armDueTicker();
  }

  @override
  void dispose() {
    _dueTicker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      // TODO(background): refill via workmanager/flutter_background_fetch every N minutes
      ref
          .read(habitControllerProvider.notifier)
          .reconcileAndSync()
          .catchError((_) {});
    }
  }

  /// Wakes up when the soonest occurrence falls due, so a habit rolls over to
  /// its next occurrence while the app is open instead of staying stuck on
  /// "due now" until the app is restarted. Any change to the habit list (toggling
  /// done, editing, adding) re-arms this through the listener in [build].
  void _armDueTicker() {
    if (!mounted) return;
    _dueTicker?.cancel();

    final now = DateTime.now();
    DateTime? nextDue;
    for (final habit in ref.read(habitControllerProvider).value ?? const []) {
      if (habit.recurrence == null || habit.nextDueAt == null) continue;
      if (nextDue == null || habit.nextDueAt!.isBefore(nextDue)) {
        nextDue = habit.nextDueAt;
      }
    }

    var wait = nextDue == null
        ? _maxWait
        : nextDue.add(_rollPad).difference(now);
    if (wait < _minWait) wait = _minWait;
    if (wait > _maxWait) wait = _maxWait;

    _dueTicker = Timer(wait, _onDueTick);
  }

  void _onDueTick() {
    // Backgrounded: Flutter freezes timers anyway, and resume reconciles.
    if (_lifecycle != AppLifecycleState.resumed) {
      _armDueTicker();
      return;
    }
    ref
        .read(habitControllerProvider.notifier)
        .refreshDue()
        .catchError((_) {})
        .whenComplete(_armDueTicker);
  }

  @override
  Widget build(BuildContext context) {
    // Keep the wake-up aligned with the current schedule.
    ref.listen(habitControllerProvider, (_, _) => _armDueTicker());

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
