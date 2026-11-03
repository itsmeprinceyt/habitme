import 'package:habit_tracker/core/constants/app_constants.dart';
import 'package:habit_tracker/data/db/app_database.dart';
import 'package:habit_tracker/data/models/completion.dart';
import 'package:habit_tracker/data/models/habit.dart';

class HabitRepository {
  HabitRepository(this._database);

  final AppDatabase _database;

  Future<List<Habit>> getAll() async {
    final db = await _database.database;
    final rows = await db.query(
      AppConstants.tableHabits,
      orderBy: '${HabitColumns.createdAt} DESC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<Habit?> getById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      AppConstants.tableHabits,
      where: '${HabitColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Habit.fromMap(rows.first);
  }

  Future<void> insert(Habit habit) async {
    final db = await _database.database;
    await db.insert(AppConstants.tableHabits, habit.toMap());
  }

  Future<void> update(Habit habit) async {
    final db = await _database.database;
    await db.update(
      AppConstants.tableHabits,
      habit.toMap(),
      where: '${HabitColumns.id} = ?',
      whereArgs: [habit.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.delete(
      AppConstants.tableHabits,
      where: '${HabitColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<Habit> toggleDone(Habit habit, bool done, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final updated = habit.copyWith(
      isDone: done,
      completedAt: () => done ? at : null,
      nextDueAt: () => habit.recurrence?.nextAfter(habit.anchorAt, at),
      updatedAt: at,
    );
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        AppConstants.tableHabits,
        updated.toMap(),
        where: '${HabitColumns.id} = ?',
        whereArgs: [habit.id],
      );
      if (done) {
        await txn.insert(
          AppConstants.tableCompletions,
          Completion(habitId: habit.id, completedAt: at).toMap(),
        );
      } else {
        await txn.delete(
          AppConstants.tableCompletions,
          where:
              '${CompletionColumns.id} = ('
              'SELECT ${CompletionColumns.id} '
              'FROM ${AppConstants.tableCompletions} '
              'WHERE ${CompletionColumns.habitId} = ? '
              'ORDER BY ${CompletionColumns.completedAt} DESC LIMIT 1)',
          whereArgs: [habit.id],
        );
      }
    });
    return updated;
  }

  Future<List<Completion>> completionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      AppConstants.tableCompletions,
      where:
          '${CompletionColumns.completedAt} >= ? '
          'AND ${CompletionColumns.completedAt} < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: '${CompletionColumns.completedAt} ASC',
    );
    return rows.map(Completion.fromMap).toList();
  }
}
