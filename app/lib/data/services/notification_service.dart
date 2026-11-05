import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ScheduledReminder {
  const ScheduledReminder({
    required this.title,
    required this.body,
    required this.at,
  });

  final String title;
  final String body;
  final DateTime at;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'habit_reminders';
  static const _channelName = 'Habit reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    _ready = true;
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
      ),
      iOS: DarwinNotificationDetails(),
    );

    Future<void> schedule(int id, ScheduledReminder r, AndroidScheduleMode m) {
      return _plugin.zonedSchedule(
        id: id,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: details,
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
