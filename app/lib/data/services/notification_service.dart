import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_action_handler.dart';

class ScheduledReminder {
  const ScheduledReminder({
    required this.habitId,
    required this.title,
    required this.body,
    required this.at,
  });

  final String habitId;
  final String title;
  final String body;
  final DateTime at;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit reminders';
  static const _categoryId = 'habit_reminder';
  static const doneActionId = 'done';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Called when the user taps the "Done" action while the app is alive.
  /// Receives the habit id stored in the notification payload.
  void Function(String habitId)? onDoneAction;

  Future<void> _tail = Future.value();
  bool _ready = false;
  bool _asked = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await syncTimezone();
    final iosCategory = DarwinNotificationCategory(
      _categoryId,
      actions: [
        DarwinNotificationAction.plain(
          doneActionId,
          'Done',
          options: {DarwinNotificationActionOption.foreground},
        ),
      ],
    );
    final settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
    _ready = true;
  }

  void _handleResponse(NotificationResponse response) {
    if (response.actionId == doneActionId && response.payload != null) {
      onDoneAction?.call(response.payload!);
    }
  }

  Future<void> syncTimezone() async {
    try {
      final dynamic info = await FlutterTimezone.getLocalTimezone();
      final name = info is String ? info : info.identifier as String;
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}
  }

  Future<void> ensurePermissions() async {
    if (_asked) return;
    _asked = true;
    final android = _android;
    if (android != null) {
      await android.requestNotificationsPermission();
      final exact = await android.canScheduleExactNotifications() ?? true;
      if (!exact) await android.requestExactAlarmsPermission();
    }
    await _ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> replaceAll(List<ScheduledReminder> reminders) {
    final next = _tail.then((_) => _replace(reminders));
    _tail = next.catchError((_) {});
    return next;
  }

  Future<void> _replace(List<ScheduledReminder> reminders) async {
    await _plugin.cancelAll();
    if (reminders.isEmpty) return;

    final exact = await _android?.canScheduleExactNotifications() ?? true;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        actions: [
          AndroidNotificationAction(
            doneActionId,
            'Done',
            showsUserInterface: false,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(categoryIdentifier: _categoryId),
    );

    Future<void> schedule(int id, ScheduledReminder r, AndroidScheduleMode m) {
      return _plugin.zonedSchedule(
        id: id,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
        payload: r.habitId,
        androidScheduleMode: m,
      );
    }

    var id = 1;
    for (final reminder in reminders) {
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      try {
        await schedule(id, reminder, mode);
      } on PlatformException {
        await schedule(id, reminder, AndroidScheduleMode.inexactAllowWhileIdle);
      }
      id++;
    }
  }
}
