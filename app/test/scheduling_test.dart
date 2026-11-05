import 'package:flutter_test/flutter_test.dart';
import 'package:habit_me/core/utils/duration_format.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/recurrence.dart';
import 'package:habit_me/data/services/notification_service.dart';

void main() {
  group('minute precision', () {
    test('Habit.create drops seconds from the schedule', () {
      final now = DateTime(2026, 11, 5, 22, 48, 32);

      final recurring = Habit.create(
        name: 'Water',
        recurrence: const Recurrence(unit: RecurUnit.minutes, interval: 1),
        anchorAt: now,
        now: now,
      );

      // 22:48:32 becomes 22:48:00, and the next minute-based occurrence is
      // simply 22:49:00 - never "22:49:32".
      expect(recurring.anchorAt, DateTime(2026, 11, 5, 22, 48));
      expect(recurring.nextDueAt, DateTime(2026, 11, 5, 22, 49));

      final oneTime = Habit.create(
        name: 'Call mum',
        notify: true,
        oneTimeAt: DateTime(2026, 11, 6, 9, 15, 47),
        now: now,
      );

      expect(oneTime.oneTimeAt, DateTime(2026, 11, 6, 9, 15));
    });

    test('recurring occurrences never carry seconds', () {
      const recurrence = Recurrence(unit: RecurUnit.minutes, interval: 5);
      final anchor = DateTime(2026, 11, 5, 10, 30, 12);

      final upcoming = recurrence.upcoming(
        anchor,
        DateTime(2026, 11, 5, 10, 31),
        3,
      );

      expect(upcoming, [
        DateTime(2026, 11, 5, 10, 35),
        DateTime(2026, 11, 5, 10, 40),
        DateTime(2026, 11, 5, 10, 45),
      ]);
    });

    test('nextAfter always returns an occurrence in the future', () {
      // Toggling a habit done re-anchors its countdown on this value, so it
      // must never hand back a time that has already passed.
      const recurrence = Recurrence(unit: RecurUnit.minutes, interval: 10);
      final anchor = DateTime(2026, 11, 5, 9, 0);
      final now = DateTime(2026, 11, 5, 10, 42, 30);

      expect(recurrence.nextAfter(anchor, now), DateTime(2026, 11, 5, 10, 50));
      // Exactly on a boundary moves to the following one.
      expect(
        recurrence.nextAfter(anchor, DateTime(2026, 11, 5, 10, 40)),
        DateTime(2026, 11, 5, 10, 50),
      );
    });
  });

  group('stableNotificationId', () {
    test('maps the same reminder key to the same positive id', () {
      expect(
        stableNotificationId('habit-a@1762000000000'),
        stableNotificationId('habit-a@1762000000000'),
      );
      expect(
        stableNotificationId('habit-a@1762000000000'),
        isNot(stableNotificationId('habit-a@1762000060000')),
      );
      expect(stableNotificationId('habit-a@1762000000000'), greaterThan(0));
    });
  });

  group('countdown display', () {
    test('shows full precision and drops the leading zero units', () {
      expect(
        DurationFormat.formatCountdown(
          const Duration(hours: 2, minutes: 48, seconds: 21),
        ),
        '2h 48m 21s',
      );
      expect(
        DurationFormat.formatCountdown(
          const Duration(minutes: 48, seconds: 21),
        ),
        '48m 21s',
      );
      expect(
        DurationFormat.formatCountdown(const Duration(minutes: 2, seconds: 40)),
        '2m 40s',
      );
      expect(
        DurationFormat.formatCountdown(const Duration(seconds: 42)),
        '42s',
      );
      expect(
        DurationFormat.formatCountdown(const Duration(days: 2, hours: 4)),
        '2d 4h 0m 0s',
      );
      // Zero units are only dropped from the left, never in the middle.
      expect(
        DurationFormat.formatCountdown(const Duration(hours: 2, seconds: 5)),
        '2h 0m 5s',
      );
      expect(
        DurationFormat.formatCountdown(
          const Duration(minutes: 15),
          isPast: true,
        ),
        'Overdue by 15m 0s',
      );
      expect(
        DurationFormat.formatCountdown(
          const Duration(seconds: -42),
          isPast: true,
        ),
        'Overdue by 42s',
      );
      expect(DurationFormat.formatCountdown(Duration.zero), 'Due now');
    });
  });
}
