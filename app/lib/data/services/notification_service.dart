import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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

  /// Bare resource names: Android resolves notification icons through
  /// `getIdentifier(name, "drawable", package)`, so the `@drawable/...` form
  /// would not be found and the whole notification would be rejected.
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

  Future<void> _tail = Future.value();
  bool _ready = false;
  bool _asked = false;
  bool _initialSyncDone = false;
  bool _timezoneSynced = false;
  bool _timezonesLoaded = false;
  Future<void>? _initializing;
  String _signature = '';
  String _timezoneName = 'unknown';

  /// True when the OS refused exact alarms, i.e. reminders may arrive late.
  bool get exactAlarmsBlocked => _exactAlarmsBlocked;
  bool _exactAlarmsBlocked = false;

  /// The IANA timezone the reminder times are interpreted in.
  String get timezoneName => _timezoneName;

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
    if (!_timezonesLoaded) {
      _timezonesLoaded = true;
      tzdata.initializeTimeZones();
    }
    await syncTimezone();

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
    if (response.actionId == doneActionId && response.payload != null) {
      onDoneAction?.call(response.payload!);
    }
  }

  Future<void> syncTimezone() async {
    if (_timezoneSynced) return;
    String identifier;
    try {
      identifier = (await FlutterTimezone.getLocalTimezone()).identifier;
    } catch (error) {
      // Leave the lookup for the next sync to retry; the device offset is used
      // meanwhile, so reminders are not left to drift.
      debugPrint('Notification timezone lookup failed: $error');
      identifier = '';
    }
    tz.setLocalLocation(resolveZone(identifier));
    _timezoneSynced = identifier.isNotEmpty;
    _timezoneName = tz.local.name;
  }

  /// Legacy zone ids Android still reports, mapped to the spelling modern tzdb
  /// data uses. The compact `data/latest.dart` table only carries canonical
  /// names, and pulling in the full `latest_all` table proved far too heavy to
  /// parse on start-up, so the handful of old names devices actually report are
  /// aliased here instead.
  static const _legacyZoneAliases = <String, String>{
    'Asia/Calcutta': 'Asia/Kolkata',
    'Asia/Saigon': 'Asia/Ho_Chi_Minh',
    'Asia/Dacca': 'Asia/Dhaka',
    'Asia/Katmandu': 'Asia/Kathmandu',
    'Asia/Thimbu': 'Asia/Thimphu',
    'Asia/Rangoon': 'Asia/Yangon',
    'Asia/Istanbul': 'Europe/Istanbul',
    'Asia/Chungking': 'Asia/Shanghai',
    'Asia/Harbin': 'Asia/Shanghai',
    'Asia/Ujung_Pandang': 'Asia/Makassar',
    'Asia/Ashkhabad': 'Asia/Ashgabat',
    'Australia/Canberra': 'Australia/Sydney',
    'Australia/LHI': 'Australia/Lord_Howe',
    'Europe/Kiev': 'Europe/Kyiv',
    'Europe/Uzhgorod': 'Europe/Kyiv',
    'Europe/Zaporozhye': 'Europe/Kyiv',
    'Atlantic/Faeroe': 'Atlantic/Faroe',
    'America/Porto_Acre': 'America/Rio_Branco',
    'America/Godthab': 'America/Nuuk',
    'Pacific/Samoa': 'Pacific/Pago_Pago',
  };

  /// Turns the id reported by the platform into a zone the Dart timezone
  /// database can schedule against, while keeping the **device's own spelling**
  /// as the zone name, because that string is what the OS has to parse.
  ///
  /// The fallback matters more than the name: [tz.local] must never stay at the
  /// package default (UTC), because a scheduled time is handed to the OS as
  /// wall-clock fields plus the zone name. Scheduling in UTC would push every
  /// reminder off by the device's distance from Greenwich.
  static tz.Location resolveZone(String identifier) {
    final resolved = _lookupLocation(identifier);
    if (resolved != null) {
      if (identifier.isEmpty || resolved.name == identifier) return resolved;
      // Same transition rules, labelled with the id this device understands.
      return tz.Location(
        identifier,
        resolved.transitionAt,
        resolved.transitionZone,
        resolved.zones,
      );
    }
    // An id that came from the device is one the device can resolve, so it is
    // kept as the zone name even when the offset has to be taken from the clock.
    final offset = DateTime.now().timeZoneOffset;
    final abbreviation = DateTime.now().timeZoneName;
    // The OS receives this string as a zone id, so it has to be something Java
    // can parse: the device id qualifies, and an offset such as "+05:30" (or
    // "Z") always does.
    final name = identifier.isEmpty ? _formatOffset(offset) : identifier;
    debugPrint(
      'Scheduling reminders against a fixed offset zone ($name, $abbreviation).',
    );
    return tz.Location(name, const [], const [], [
      tz.TimeZone(offset, isDst: false, abbreviation: abbreviation),
    ]);
  }

  /// Direct database lookup, then the legacy alias table. `null` when neither
  /// knows the id.
  static tz.Location? _lookupLocation(String identifier) {
    if (identifier.isEmpty) return null;
    try {
      return tz.getLocation(identifier);
    } catch (error) {
      debugPrint(
        'Timezone "$identifier" is not in the bundled database: $error',
      );
    }
    final canonical = _legacyZoneAliases[identifier];
    if (canonical != null) {
      try {
        return tz.getLocation(canonical);
      } catch (error) {
        debugPrint(
          'Alias "$canonical" for "$identifier" is missing too: $error',
        );
      }
    }
    return null;
  }

  /// Formats an offset the way `ZoneId.of` expects: "+05:30", "-08:00", "Z".
  static String _formatOffset(Duration offset) {
    if (offset == Duration.zero) return 'Z';
    final absolute = offset.abs();
    final sign = offset.isNegative ? '-' : '+';
    final hours = absolute.inHours.toString().padLeft(2, '0');
    final minutes = (absolute.inMinutes % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  Future<void> ensurePermissions() async {
    final android = _android;
    if (android != null) {
      await android.requestNotificationsPermission();
      _exactAlarmsBlocked =
          !(await android.canScheduleExactNotifications() ?? true);
      if (_exactAlarmsBlocked && !_asked) {
        await android.requestExactAlarmsPermission();
      }
    }
    await _ios?.requestPermissions(alert: true, badge: true, sound: true);
    _asked = true;
  }

  /// Opens the system page where the user can allow exact alarms.
  Future<void> openExactAlarmSettings() async {
    await _android?.requestExactAlarmsPermission();
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
    await syncTimezone();

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
      '${wanted.length - scheduled} kept (mode: ${mode.name}, '
      'tz: $_timezoneName)',
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
