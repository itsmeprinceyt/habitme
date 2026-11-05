import 'package:flutter_test/flutter_test.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/data/models/completion.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/label.dart';
import 'package:habit_me/data/models/recurrence.dart';
import 'package:habit_me/data/services/sql_codec.dart';

/// The awkward data a real library produces: quotes, brackets, commas, emoji,
/// semicolons, nulls and colours that look like huge numbers.
void main() {
  final createdAt = DateTime(2026, 11, 1, 9, 30);
  final anchor = DateTime(2026, 11, 5, 22, 48);

  final label = HabitLabel(
    id: 'label-1',
    name: "Health & Fitness's 'core'",
    color: 0xFF4CAF50,
    createdAt: createdAt,
  );

  final recurring = Habit(
    id: 'habit-1',
    name: 'Drink (2L) water, 💧',
    labelId: 'label-1',
    recurrence: const Recurrence(unit: RecurUnit.minutes, interval: 30),
    notify: true,
    isDone: false,
    oneTimeAt: null,
    anchorAt: anchor,
    nextDueAt: anchor.add(const Duration(minutes: 30)),
    completedAt: null,
    createdAt: createdAt,
    updatedAt: anchor,
  );

  final oneTime = Habit(
    id: 'habit-2',
    name: 'Call mum; semicolons too',
    recurrence: null,
    notify: false,
    isDone: true,
    oneTimeAt: DateTime(2026, 11, 6, 9, 15),
    anchorAt: DateTime(2026, 11, 6, 9, 15),
    nextDueAt: null,
    completedAt: DateTime(2026, 11, 6, 9, 20),
    createdAt: createdAt,
    updatedAt: DateTime(2026, 11, 6, 9, 20),
  );

  final completion = Completion(
    id: 7,
    habitId: 'habit-2',
    completedAt: DateTime(2026, 11, 6, 9, 20),
  );

  final labelRows = [label.toMap()];
  final habitRows = [recurring.toMap(), oneTime.toMap()];
  final completionRows = [completion.toMap()];

  String dump() => SqlCodec.encode(
    labels: labelRows,
    habits: habitRows,
    completions: completionRows,
  );

  group('backup round trip', () {
    test('every column of every table survives encode + decode', () {
      final parsed = SqlCodec.decode(dump());

      expect(parsed.labels, labelRows);
      expect(parsed.habits, habitRows);
      // The autoincrement id belongs to the database, not to the backup.
      expect(parsed.completions, [
        {
          CompletionColumns.habitId: completion.habitId,
          CompletionColumns.completedAt:
              completion.completedAt.millisecondsSinceEpoch,
        },
      ]);
      expect(parsed.rowCount, 4);
    });

    test('the dump is labelled, ordered and covers all habit columns', () {
      final sql = dump();
      final lines = sql.trimRight().split('\n');

      expect(lines.first, AppConstants.backupMarker);
      expect(sql, contains('BEGIN TRANSACTION;'));
      expect(sql.trimRight().endsWith('COMMIT;'), isTrue);

      final habitLine = lines.firstWhere(
        (line) => line.startsWith('INSERT INTO habits'),
      );
      for (final column in [
        HabitColumns.id,
        HabitColumns.name,
        HabitColumns.labelId,
        HabitColumns.isRecurring,
        HabitColumns.recurUnit,
        HabitColumns.recurInterval,
        HabitColumns.notify,
        HabitColumns.isDone,
        HabitColumns.oneTimeAt,
        HabitColumns.anchorAt,
        HabitColumns.nextDueAt,
        HabitColumns.completedAt,
        HabitColumns.createdAt,
        HabitColumns.updatedAt,
      ]) {
        expect(habitLine, contains(column), reason: '$column must be exported');
      }

      // Labels are written before the habits that point at them, habits before
      // the completions that reference them.
      int offsetOf(String prefix) =>
          lines.indexWhere((line) => line.startsWith(prefix));
      expect(
        offsetOf('INSERT INTO labels'),
        lessThan(offsetOf('INSERT INTO habits')),
      );
      expect(
        offsetOf('INSERT INTO habits'),
        lessThan(offsetOf('INSERT INTO completions')),
      );
    });

    test('re-importing a file twice is stable', () {
      final first = SqlCodec.decode(dump());
      final second = SqlCodec.decode(
        SqlCodec.encode(
          labels: first.labels,
          habits: first.habits,
          completions: first.completions,
        ),
      );

      expect(second.labels, first.labels);
      expect(second.habits, first.habits);
      expect(second.completions, first.completions);
    });

    test('CRLF line endings and INSERT OR REPLACE still parse', () {
      expect(SqlCodec.decode(dump().replaceAll('\n', '\r\n')).habits.length, 2);

      final replaced = dump().replaceAll(
        'INSERT INTO',
        'INSERT OR REPLACE INTO',
      );
      expect(SqlCodec.decode(replaced).labels.length, 1);
    });

    test('multi-row VALUES lists and stray pragmas are tolerated', () {
      final text =
          '${AppConstants.backupMarker}\n'
          'PRAGMA foreign_keys=OFF;\n'
          'BEGIN TRANSACTION;\n'
          "INSERT INTO labels (id, name, color, created_at) VALUES "
          "('a', 'Work', 1, 10), ('b', 'Home', NULL, 20);\n"
          'COMMIT;\n';

      final parsed = SqlCodec.decode(text);
      expect(parsed.labels.length, 2);
      expect(parsed.labels[1][LabelColumns.color], isNull);
    });
  });

  group('backup validation', () {
    test('a file that is not a backup is rejected with a clear message', () {
      expect(
        () => SqlCodec.decode('CREATE TABLE habits (id TEXT);'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('not a HabitMe backup'),
          ),
        ),
      );
    });

    test('an unknown table is rejected instead of executed', () {
      final text =
          '${AppConstants.backupMarker}\n'
          "INSERT INTO secrets (id) VALUES ('x');\n";
      expect(
        () => SqlCodec.decode(text),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('not part of a HabitMe backup'),
          ),
        ),
      );
    });

    test('an unknown column is rejected with its line number', () {
      final text =
          '${AppConstants.backupMarker}\n'
          "INSERT INTO labels (id, name, colour) VALUES ('1', 'a', 0);\n";
      expect(
        () => SqlCodec.decode(text),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('unknown column'), contains('Line 2')),
          ),
        ),
      );
    });

    test('a NULL in a required column is reported, not silently imported', () {
      final text =
          '${AppConstants.backupMarker}\n'
          'INSERT INTO labels (id, name, color, created_at) '
          "VALUES ('1', NULL, 0, 100);\n";
      expect(
        () => SqlCodec.decode(text),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('required column'),
          ),
        ),
      );
    });

    test(
      'an empty backup is refused so nothing looks like a false success',
      () {
        expect(
          () => SqlCodec.decode('${AppConstants.backupMarker}\n'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('no labels, habits or completions'),
            ),
          ),
        );
      },
    );

    test('numbers written as text are coerced to their column type', () {
      final text =
          '${AppConstants.backupMarker}\n'
          'INSERT INTO labels (id, name, color, created_at) '
          "VALUES ('1', 'a', '4293716816', '100');\n";
      final parsed = SqlCodec.decode(text);
      expect(parsed.labels.single[LabelColumns.color], 4293716816);
    });
  });
}
