import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_action_handler.dart';

/// FNV-1a hash kept inside the positive 31-bit range. The same [key] always
/// maps to the same notification id, even after a restart, which lets the
/// scheduler tell "already scheduled" reminders apart from new ones.
int stableNotificationId(String key) {
  var hash = 0x811c9dc5;
  for (final unit in key.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

/// A single reminder that should be delivered by the operating system.
class ScheduledReminder {
  const ScheduledReminder({
    required this.key,
    required this.habitId,
    required this.title,
    required this.body,
    required this.at,
  });

  /// Stable identity of the reminder: habit + the exact minute it targets.
  final String key;
  final String habitId;
  final String title;
  final String body;
  final DateTime at;

  int get notificationId => stableNotificationId(key);
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit reminders';
  static const _channelDescription = 'Reminders to keep your habits on track';
  static const _categoryId = 'habit_reminder';

  /// Resource-reference form — resolves through the resource table, so it
  /// can't fail the way a bare drawable name can when the lookup misses.
  static const _smallIcon = 'ic_notification';
  static const _largeIcon = 'notification_logo';

  static const doneActionId = 'done';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: _smallIcon,
      largeIcon: DrawableResourceAndroidBitmap(_largeIcon),
      actions: [
        AndroidNotificationAction(
          doneActionId,
          'Done',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(categoryIdentifier: _categoryId),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Called when the user taps the "Done" action while the app is alive.
  /// Receives the habit id stored in the notification payload.
  void Function(String habitId)? onDoneAction;

  /// Called when a reminder fires or is interacted with.
  void Function(String habitId, DateTime at)? onFired;

  Future<void> _tail = Future.value();
  bool _ready = false;
  bool _asked = false;
  bool _initialSyncDone = false;
  Future<void>? _initializing;
  String _signature = '';

  /// True when the OS refused exact alarms, i.e. reminders may arrive late.
  bool get exactAlarmsBlocked => _exactAlarmsBlocked;
  bool _exactAlarmsBlocked = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  /// Single-flight initialisation: concurrent callers share one attempt, and a
  /// failed attempt is left un-cached so the next caller can retry it.
  Future<void> init() {
    if (_ready) return Future.value();
    return _initializing ??= _initOnce().catchError((error) {
      _initializing = null;
      throw error;
    });
  }

  Future<void> _initOnce() async {
    tzdata.initializeTimeZones();

    final iosCategory = DarwinNotificationCategory(
      _categoryId,
      actions: [
        DarwinNotificationAction.plain(
          doneActionId,
          'Done',
          options: const {DarwinNotificationActionOption.foreground},
        ),
      ],
    );
    final settings = InitializationSettings(
      android: const AndroidInitializationSettings(_smallIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [iosCategory],
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse:
          habitNotificationBackgroundHandler,
    );

    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    _ready = true;
  }

  void _handleResponse(NotificationResponse response) {
    if (response.payload != null) {
      final habitId = response.payload!;
      if (response.actionId == doneActionId) {
        onDoneAction?.call(habitId);
      }
      onFired?.call(habitId, DateTime.now());
    }
  }

  bool _notificationsDenied = false;

  Future<void> ensurePermissions() async {
    if (_asked) return;
    _asked = true;
    await init();
    final android = _android;
    if (android != null) {
      await android.requestNotificationsPermission();
      _exactAlarmsBlocked =
          !(await android.canScheduleExactNotifications() ?? true);
      if (_exactAlarmsBlocked) {
        await android.requestExactAlarmsPermission();
      }
    }
    await _ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Re-arms the whole schedule after notifications go from denied to granted:
  /// alarms scheduled while permission was missing never posted, and the
  /// diff-based sync would otherwise consider them already armed.
  void _rearmIfGranted(bool enabled) {
    if (_notificationsDenied && enabled) {
      _initialSyncDone = false;
      _signature = '';
    }
    _notificationsDenied = !enabled;
  }

  Future<void> checkPermissionsOnLaunch() async {
    await init();
    final android = _android;
    if (android != null) {
      bool enabled = true;
      try {
        enabled = await android.areNotificationsEnabled() ?? false;
      } catch (_) {}
      _rearmIfGranted(enabled);
      if (!enabled) {
        try {
          await android.requestNotificationsPermission();
        } catch (_) {}
        try {
          enabled = await android.areNotificationsEnabled() ?? enabled;
        } catch (_) {}
        _rearmIfGranted(enabled);
      }
      try {
        final exact = await android.canScheduleExactNotifications() ?? true;
        _exactAlarmsBlocked = !exact;
        if (!exact) {
          await android.requestExactAlarmsPermission();
        }
      } catch (_) {}
    }
    try {
      await _ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  /// Opens the system page where the user can allow exact alarms.
  Future<void> openExactAlarmSettings() async {
    await _android?.requestExactAlarmsPermission();
  }

  /// Schedules a single reminder without wiping or re-syncing the full queue.
  Future<void> scheduleOne(ScheduledReminder reminder) {
    final next = _tail.then((_) => _scheduleSingle(reminder));
    _tail = next.catchError((_) {});
    return next;
  }

  Future<void> _scheduleSingle(ScheduledReminder reminder) async {
    await init();
    final now = DateTime.now();
    if (!reminder.at.isAfter(now)) return;

    final mode = await _scheduleMode();
    await _schedule(reminder, reminder.notificationId, mode);
  }

  /// Cancels a reminder by its stable key.
  Future<void> cancelByKey(String key) {
    final next = _tail.then((_) => _cancelSingle(key));
    _tail = next.catchError((_) {});
    return next;
  }

  Future<void> _cancelSingle(String key) async {
    await init();
    final id = stableNotificationId(key);
    try {
      await _guard(_plugin.cancel(id: id));
    } catch (error) {
      debugPrint('Cancelling notification $id failed: $error');
    }
  }

  /// Replaces the reminders the OS should hold on to.
  ///
  /// Reminders that are unchanged keep their existing alarm, so re-syncing
  /// (every app resume, for example) can never drop a reminder that is about
  /// to fire. Only additions and removals are sent to the platform.
  Future<void> replaceAll(List<ScheduledReminder> reminders) {
    final next = _tail.then((_) => _replace(reminders));
    _tail = next.catchError((_) {});
    return next;
  }

  Future<void> _replace(List<ScheduledReminder> reminders) async {
    await init();

    // The first sync of a session re-arms everything, which repairs alarms the
    // system may have dropped (force-stop, aggressive battery optimisation).
    // Later syncs only touch what actually changed.
    final rearmAll = !_initialSyncDone;
    _initialSyncDone = true;

    final now = DateTime.now();
    final wanted = <int, ScheduledReminder>{};
    for (final reminder in reminders) {
      // Anything already in the past can no longer be scheduled.
      if (!reminder.at.isAfter(now)) continue;
      wanted[reminder.notificationId] = reminder;
    }

    final signature = _signatureOf(wanted);
    if (!rearmAll && signature == _signature && wanted.isNotEmpty) return;

    var pending = <int>{};
    try {
      final requests = await _guard(_plugin.pendingNotificationRequests());
      pending = {for (final request in requests) request.id};
    } catch (error) {
      // Without the pending list we cannot tell which alarms are stale, so
      // clear everything and re-arm the whole plan.
      debugPrint('Could not read pending notifications ($error) - resetting.');
      try {
        await _guard(_plugin.cancelAll());
      } catch (_) {}
      pending = {};
    }

    // Drop the reminders that are no longer part of the plan.
    final stale = pending.difference(wanted.keys.toSet());
    for (final id in stale) {
      try {
        await _guard(_plugin.cancel(id: id));
      } catch (error) {
        debugPrint('Cancelling notification $id failed: $error');
      }
    }

    final mode = await _scheduleMode();
    var scheduled = 0;
    for (final entry in wanted.entries) {
      if (!rearmAll && pending.contains(entry.key)) continue; // already armed
      await _schedule(entry.value, entry.key, mode);
      scheduled++;
    }

    _signature = signature;
    debugPrint(
      'Notifications: $scheduled scheduled, ${stale.length} cancelled, '
      '${wanted.length - scheduled} kept (mode: ${mode.name})',
    );
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final android = _android;
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    final exact = await _guard(android.canScheduleExactNotifications()) ?? true;
    _exactAlarmsBlocked = !exact;
    // Inexact alarms get batched by Doze, which is what makes reminders show
    // up minutes late and all at once, so they are only used as a last resort.
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> _schedule(
    ScheduledReminder reminder,
    int id,
    AndroidScheduleMode mode,
  ) async {
    Future<void> run(AndroidScheduleMode scheduleMode) => _guard(
      _plugin.zonedSchedule(
        id: id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.at, tz.local),
        notificationDetails: _details,
        payload: reminder.habitId,
        androidScheduleMode: scheduleMode,
      ),
    );

    try {
      await run(mode);
    } on PlatformException catch (error) {
      debugPrint(
        'Scheduling "${reminder.title}" for ${reminder.at} failed '
        '(${error.code}: ${error.message})',
      );
      if (mode != AndroidScheduleMode.inexactAllowWhileIdle) {
        try {
          await run(AndroidScheduleMode.inexactAllowWhileIdle);
        } catch (fallbackError) {
          debugPrint('Inexact fallback failed too: $fallbackError');
        }
      }
    } catch (error) {
      debugPrint('Scheduling "${reminder.title}" failed: $error');
    }
  }

  String _signatureOf(Map<int, ScheduledReminder> wanted) {
    final parts = [
      for (final entry in wanted.entries)
        '${entry.key}=${entry.value.at.microsecondsSinceEpoch}',
    ]..sort();
    return parts.join(',');
  }

  /// Keeps the serial queue from sticking if a platform call never returns.
  Future<T> _guard<T>(Future<T> future) =>
      future.timeout(const Duration(seconds: 15));
}
