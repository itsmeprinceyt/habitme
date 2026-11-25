import 'package:flutter_test/flutter_test.dart';
import 'package:habit_me/core/utils/calendar_heat.dart';

void main() {
  group('DayProgress', () {
    test('no scheduled habits stays empty even with stray completions', () {
      const progress = DayProgress(scheduled: 0, completed: 2);
      expect(progress.hasTasks, isFalse);
      expect(progress.ratio, 0);
      expect(progress.percent, 0);
    });

    test('1 of 2 completed is 50%', () {
      const progress = DayProgress(scheduled: 2, completed: 1);
      expect(progress.hasTasks, isTrue);
      expect(progress.ratio, 0.5);
      expect(progress.percent, 50);
    });

    test('2 of 2 completed is 100%', () {
      const progress = DayProgress(scheduled: 2, completed: 2);
      expect(progress.ratio, 1.0);
      expect(progress.percent, 100);
    });

    test('1 of 5 completed is 20%', () {
      const progress = DayProgress(scheduled: 5, completed: 1);
      expect(progress.ratio, 0.2);
      expect(progress.percent, 20);
    });

    test('completed above scheduled is capped at 100%', () {
      const progress = DayProgress(scheduled: 2, completed: 5);
      expect(progress.ratio, 1.0);
      expect(progress.percent, 100);
    });

    test('percent rounds to the nearest whole number', () {
      const progress = DayProgress(scheduled: 3, completed: 1);
      expect(progress.percent, 33);
    });
  });

  group('dayKey', () {
    test('is stable within the same local day', () {
      expect(
        dayKey(DateTime(2026, 11, 25, 6, 30)),
        dayKey(DateTime(2026, 11, 25, 23, 59)),
      );
    });

    test('changes across midnight', () {
      expect(
        dayKey(DateTime(2026, 11, 25, 23, 59)),
        isNot(dayKey(DateTime(2026, 11, 26))),
      );
    });
  });
}
