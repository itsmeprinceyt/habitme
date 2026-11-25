import 'package:flutter_test/flutter_test.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/recurrence.dart';

void main() {
  final anchor = DateTime(2026, 1, 1, 9, 0);
  final beforeFirst = DateTime(2026, 1, 1, 8, 0);

  group('repeat count', () {
    test('upcoming and occursOnDate stop at the limit', () {
      const recurrence = Recurrence(
        unit: RecurUnit.days,
        interval: 1,
        count: 3,
      );

      expect(recurrence.remaining(anchor, beforeFirst), 3);
      expect(recurrence.isFinished(anchor, beforeFirst), isFalse);
      expect(recurrence.upcoming(anchor, beforeFirst, 10), [
        DateTime(2026, 1, 1, 9),
        DateTime(2026, 1, 2, 9),
        DateTime(2026, 1, 3, 9),
      ]);
      expect(recurrence.nextAfter(anchor, beforeFirst), DateTime(2026, 1, 1, 9));

      expect(recurrence.occursOnDate(anchor, DateTime(2026, 1, 3)), isTrue);
      expect(recurrence.occursOnDate(anchor, DateTime(2026, 1, 4)), isFalse);

      // Once the third occurrence passes there is no next one.
      final afterLast = DateTime(2026, 1, 3, 10, 0);
      expect(recurrence.nextAfter(anchor, afterLast), isNull);
      expect(recurrence.upcoming(anchor, afterLast, 5), isEmpty);
      expect(recurrence.isFinished(anchor, afterLast), isTrue);
      expect(recurrence.remaining(anchor, afterLast), 0);
    });

    test('remaining counts down between occurrences', () {
      const recurrence = Recurrence(
        unit: RecurUnit.days,
        interval: 1,
        count: 7,
      );

      expect(recurrence.remaining(anchor, DateTime(2026, 1, 1, 10)), 6);
      expect(recurrence.remaining(anchor, DateTime(2026, 1, 3, 10)), 4);
      // An occurrence landing exactly "now" still counts as remaining.
      expect(recurrence.remaining(anchor, DateTime(2026, 1, 3, 9)), 5);
      expect(recurrence.remaining(anchor, DateTime(2026, 2, 1)), 0);
    });

    test('monthly limit clamps the last day and stops after it', () {
      final monthlyAnchor = DateTime(2026, 1, 31, 9, 0);
      const recurrence = Recurrence(
        unit: RecurUnit.months,
        interval: 1,
        count: 3,
      );

      expect(recurrence.upcoming(monthlyAnchor, beforeFirst, 5), [
        DateTime(2026, 1, 31, 9),
        DateTime(2026, 2, 28, 9),
        DateTime(2026, 3, 31, 9),
      ]);
      expect(
        recurrence.occursOnDate(monthlyAnchor, DateTime(2026, 3, 31)),
        isTrue,
      );
      expect(
        recurrence.occursOnDate(monthlyAnchor, DateTime(2026, 4, 30)),
        isFalse,
      );
      expect(recurrence.nextAfter(monthlyAnchor, DateTime(2026, 4, 1)), isNull);
    });

    test('intraday repeats honour the limit', () {
      final hourAnchor = DateTime(2026, 1, 1, 10, 0);
      const recurrence = Recurrence(unit: RecurUnit.hours, interval: 1, count: 2);

      expect(recurrence.upcoming(hourAnchor, DateTime(2026, 1, 1, 10, 30), 5), [
        DateTime(2026, 1, 1, 11),
      ]);
      expect(recurrence.remaining(hourAnchor, DateTime(2026, 1, 1, 11, 30)), 0);
      expect(recurrence.nextAfter(hourAnchor, DateTime(2026, 1, 1, 11, 30)), isNull);
    });

    test('no count keeps repeating forever, exactly as before', () {
      const recurrence = Recurrence(unit: RecurUnit.days, interval: 1);

      expect(recurrence.remaining(anchor, beforeFirst), isNull);
      expect(recurrence.isFinished(anchor, DateTime(2030, 1, 1)), isFalse);
      expect(recurrence.upcoming(anchor, beforeFirst, 5).length, 5);
      expect(recurrence.nextAfter(anchor, DateTime(2026, 1, 3, 10)), DateTime(2026, 1, 4, 9));
      expect(recurrence.occursOnDate(anchor, DateTime(2030, 1, 1)), isTrue);
    });
  });

  group('description and equality', () {
    test('label appends the repeat limit', () {
      expect(
        const Recurrence(unit: RecurUnit.days, interval: 1, count: 7).label,
        'Every day · 7 times',
      );
      expect(
        const Recurrence(unit: RecurUnit.days, interval: 2, count: 21).label,
        'Every 2 days · 21 times',
      );
      expect(
        const Recurrence(unit: RecurUnit.hours, interval: 1, count: 1).label,
        'Every hour · 1 time',
      );
      expect(
        const Recurrence(unit: RecurUnit.days, interval: 1).label,
        'Every day',
      );
    });

    test('rules compare by unit, interval and count', () {
      const unlimited = Recurrence(unit: RecurUnit.days, interval: 1);
      const limited = Recurrence(unit: RecurUnit.days, interval: 1, count: 7);

      expect(unlimited, isNot(limited));
      expect(unlimited.withCount(null), unlimited);
      expect(limited.withCount(7), limited);
      expect(limited.withCount(null), unlimited);
      expect(limited.hashCode, equals(limited.withCount(7).hashCode));
    });
  });

  group('habit persistence', () {
    test('repeat count survives a map round trip', () {
      final habit = Habit.create(
        name: 'Read',
        recurrence: const Recurrence(
          unit: RecurUnit.days,
          interval: 1,
          count: 7,
        ),
        anchorAt: DateTime(2026, 1, 1, 9),
        now: DateTime(2026, 1, 1, 8),
      );

      final restored = Habit.fromMap(habit.toMap());
      expect(restored.recurrence?.count, 7);
      expect(restored.recurrence, habit.recurrence);
    });

    test('a row without a count reads as unlimited', () {
      final habit = Habit.create(
        name: 'Legacy',
        recurrence: const Recurrence(unit: RecurUnit.days, interval: 1),
        anchorAt: DateTime(2026, 1, 1, 9),
        now: DateTime(2026, 1, 1, 8),
      );

      final map = habit.toMap();
      expect(map[HabitColumns.recurCount], isNull);
      expect(Habit.fromMap(map).recurrence?.count, isNull);
    });

    test('an unusable count is ignored, not fatal', () {
      final habit = Habit.create(
        name: 'Bad row',
        recurrence: const Recurrence(unit: RecurUnit.days, interval: 1),
        anchorAt: DateTime(2026, 1, 1, 9),
        now: DateTime(2026, 1, 1, 8),
      );

      final map = habit.toMap()..[HabitColumns.recurCount] = 0;
      expect(Habit.fromMap(map).recurrence?.count, isNull);
    });
  });
}
