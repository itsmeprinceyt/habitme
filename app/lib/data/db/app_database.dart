import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/data/models/completion.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/label.dart';
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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableLabels} (
        ${LabelColumns.id} TEXT PRIMARY KEY,
        ${LabelColumns.name} TEXT NOT NULL,
        ${LabelColumns.color} INTEGER,
        ${LabelColumns.createdAt} INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE ${AppConstants.tableHabits} (
        ${HabitColumns.id} TEXT PRIMARY KEY,
        ${HabitColumns.name} TEXT NOT NULL,
        ${HabitColumns.labelId} TEXT,
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
        ${HabitColumns.updatedAt} INTEGER NOT NULL,
        FOREIGN KEY (${HabitColumns.labelId})
          REFERENCES ${AppConstants.tableLabels}(${LabelColumns.id})
          ON DELETE SET NULL
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
    await db.execute('''
      CREATE INDEX idx_habits_label
      ON ${AppConstants.tableHabits}(${HabitColumns.labelId})
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppConstants.tableLabels} (
          ${LabelColumns.id} TEXT PRIMARY KEY,
          ${LabelColumns.name} TEXT NOT NULL,
          ${LabelColumns.color} INTEGER,
          ${LabelColumns.createdAt} INTEGER NOT NULL
        )
      ''');
      // Add label_id column to habits if upgrading
      try {
        await db.execute('''
          ALTER TABLE ${AppConstants.tableHabits}
          ADD COLUMN ${HabitColumns.labelId} TEXT
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_habits_label
          ON ${AppConstants.tableHabits}(${HabitColumns.labelId})
        ''');
      } catch (_) {}
    }
  }
}
