import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The device reports the zone it reads from its own database, and Android's
/// table still carries pre-2018 names. If the lookup misses, the scheduler
/// would fall back to UTC and every reminder would fire offset by the device's
/// distance from Greenwich, so the bundled database has to know these ids.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  group('timezone lookup', () {
    test('legacy Android ids resolve and keep their modern offset', () {
      // Zones without daylight saving, so the offset is the same all year.
      const legacyToOffset = <String, Duration>{
        'Asia/Calcutta': Duration(hours: 5, minutes: 30),
        'Asia/Saigon': Duration(hours: 7),
        'Asia/Dacca': Duration(hours: 6),
      };

      legacyToOffset.forEach((id, expectedOffset) {
        final location = tz.getLocation(id);
        final midday = tz.TZDateTime(location, 2026, 7, 1, 12);
        expect(midday.timeZoneOffset, expectedOffset, reason: id);
      });
    });

    test('a reminder is placed at the device wall clock, not at UTC', () {
      final kolkata = tz.getLocation('Asia/Calcutta');
      // 8:00 pm on the device clock must stay 8:00 pm in the zone handed to the
      // OS, and must land on the 14:30 UTC instant.
      final at = tz.TZDateTime(kolkata, 2026, 7, 1, 20);

      expect(at.hour, 20);
      expect(at.location.name, 'Asia/Calcutta');
      expect(at.toUtc(), DateTime.utc(2026, 7, 1, 14, 30));
    });
  });
}
