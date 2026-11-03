import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/data/models/completion.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, AppConstants.databaseName);
    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableHabits} (
        ${HabitColumns.id} TEXT PRIMARY KEY,
        ${HabitColumns.name} TEXT NOT NULL,
        ${HabitColumns.isRecurring} INTEGER NOT NULL DEFAULT 0,
        ${HabitColumns.recurUnit} TEXT,
        ${HabitColumns.recurInterval} INTEGER,
        ${HabitColumns.notify} INTEGER NOT NULL DEFAULT 0,
        ${HabitColumns.isDone} INTEGER NOT NULL DEFAULT 0,
        ${HabitColumns.oneTimeAt} INTEGER,
        ${HabitColumns.anchorAt} INTEGER NOT NULL,
        ${HabitColumns.nextDueAt} INTEGER,
        ${HabitColumns.completedAt} INTEGER,
        ${HabitColumns.createdAt} INTEGER NOT NULL,
        ${HabitColumns.updatedAt} INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCompletions} (
        ${CompletionColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${CompletionColumns.habitId} TEXT NOT NULL,
        ${CompletionColumns.completedAt} INTEGER NOT NULL,
        FOREIGN KEY (${CompletionColumns.habitId})
          REFERENCES ${AppConstants.tableHabits}(${HabitColumns.id})
          ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_completions_habit
      ON ${AppConstants.tableCompletions}(${CompletionColumns.habitId})
    ''');
    await db.execute('''
      CREATE INDEX idx_completions_at
      ON ${AppConstants.tableCompletions}(${CompletionColumns.completedAt})
    ''');
  }
}
