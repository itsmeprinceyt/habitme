import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/data/db/app_database.dart';
import 'package:habit_me/data/models/label.dart';
import 'package:habit_me/data/models/habit.dart';

class LabelRepository {
  LabelRepository(this._database);

  final AppDatabase _database;

  Future<List<HabitLabel>> getAll() async {
    final db = await _database.database;
    final rows = await db.query(
      AppConstants.tableLabels,
      orderBy: '${LabelColumns.name} COLLATE NOCASE ASC',
    );
    return rows.map(HabitLabel.fromMap).toList();
  }

  Future<HabitLabel?> getById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      AppConstants.tableLabels,
      where: '${LabelColumns.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return HabitLabel.fromMap(rows.first);
  }

  Future<void> insert(HabitLabel label) async {
    final db = await _database.database;
    await db.insert(AppConstants.tableLabels, label.toMap());
  }

  Future<void> update(HabitLabel label) async {
    final db = await _database.database;
    await db.update(
      AppConstants.tableLabels,
      label.toMap(),
      where: '${LabelColumns.id} = ?',
      whereArgs: [label.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      // Unlink habits using this label
      await txn.update(
        AppConstants.tableHabits,
        {HabitColumns.labelId: null},
        where: '${HabitColumns.labelId} = ?',
        whereArgs: [id],
      );
      await txn.delete(
        AppConstants.tableLabels,
        where: '${LabelColumns.id} = ?',
        whereArgs: [id],
      );
    });
  }
}
