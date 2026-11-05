import 'package:flutter_test/flutter_test.dart';
import 'package:habit_me/data/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The device reports the zone it reads from its own (sometimes decades old)
/// table, so ids like `Asia/Calcutta` arrive here. The compact tzdb only knows
/// the modern spelling, and if resolution ever failed the scheduler would fall
/// back to UTC and push every reminder off by the device's offset from
/// Greenwich - so resolution must always produce a real, correctly named zone.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('device zone resolution', () {
    test('legacy Android ids are aliased but keep the device spelling', () {
      // Zones without daylight saving, so the offset is the same all year.
      const legacyToOffset = <String, Duration>{
        'Asia/Calcutta': Duration(hours: 5, minutes: 30),
        'Asia/Saigon': Duration(hours: 7),
        'Asia/Dacca': Duration(hours: 6),
      };

      legacyToOffset.forEach((id, expectedOffset) {
        final zone = NotificationService.resolveZone(id);
        // The name is what the OS is handed, so it must stay parseable there.
        expect(zone.name, id, reason: id);
        final midday = tz.TZDateTime(zone, 2026, 7, 1, 12);
        expect(midday.timeZoneOffset, expectedOffset, reason: id);
      });
    });

    test('canonical ids pass straight through', () {
      expect(
        NotificationService.resolveZone('Asia/Kolkata').name,
        'Asia/Kolkata',
      );
    });

    test(
      'an unknown id still yields a fixed-offset zone, never UTC by default',
      () {
        final zone = NotificationService.resolveZone('Made/Up');
        expect(zone.name, 'Made/Up');
        expect(zone.zones, hasLength(1));
      },
    );

    test('a missing id is named with a Java-parsable offset', () {
      expect(
        NotificationService.resolveZone('').name,
        matches(RegExp(r'^(Z|[+-]\d{2}:\d{2})$')),
      );
    });

    test('a reminder is placed at the device wall clock, not at UTC', () {
      final kolkata = NotificationService.resolveZone('Asia/Calcutta');
      // 8:00 pm on the device clock must stay 8:00 pm in the zone handed to the
      // OS, and must land on the 14:30 UTC instant.
      final at = tz.TZDateTime(kolkata, 2026, 7, 1, 20);

      expect(at.hour, 20);
      expect(at.toUtc(), DateTime.utc(2026, 7, 1, 14, 30));
    });
  });
}
