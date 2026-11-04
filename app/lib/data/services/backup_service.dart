import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/data/db/app_database.dart';
import 'package:habit_me/data/models/completion.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/services/sql_codec.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ImportSummary {
  const ImportSummary({required this.habits, required this.completions});

  final int habits;
  final int completions;
}

class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  Future<void> exportSql() async {
    final db = await _database.database;
    final habitRows = await db.query(
      AppConstants.tableHabits,
      orderBy: '${HabitColumns.createdAt} ASC',
    );
    final completionRows = await db.query(
      AppConstants.tableCompletions,
      orderBy: '${CompletionColumns.completedAt} ASC',
    );

    final content = SqlCodec.encode(
      habitRows.map(Habit.fromMap).toList(),
      completionRows.map(Completion.fromMap).toList(),
    );

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File(
      '${dir.path}/${AppConstants.backupFilePrefix}_$stamp.sql',
    );
    await file.writeAsString(content, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '${AppConstants.appName} backup',
      ),
    );
  }

  Future<ImportSummary?> importSql() async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    if (result.isEmpty) return null;

    final path = result.first.path;
    if (path == null) {
      throw const FormatException('Could not read the selected file');
    }
    final text = utf8.decode(
      await File(path).readAsBytes(),
      allowMalformed: true,
    );

    final parsed = SqlCodec.decode(text);
    final db = await _database.database;
    var habitCount = 0;
    var completionCount = 0;

    await db.transaction((txn) async {
      final knownIds = <String>{};

      for (final row in parsed.habits) {
        final id = row[HabitColumns.id] as String;
        final updated = await txn.update(
          AppConstants.tableHabits,
          row,
          where: '${HabitColumns.id} = ?',
          whereArgs: [id],
        );
        if (updated == 0) {
          await txn.insert(AppConstants.tableHabits, row);
        }
        knownIds.add(id);
        habitCount++;
      }

      final existing = await txn.query(
        AppConstants.tableHabits,
        columns: [HabitColumns.id],
      );
      for (final r in existing) {
        knownIds.add(r[HabitColumns.id] as String);
      }

      for (final row in parsed.completions) {
        final habitId = row[CompletionColumns.habitId] as String;
        if (!knownIds.contains(habitId)) continue;

        final duplicate = await txn.query(
          AppConstants.tableCompletions,
          columns: [CompletionColumns.id],
          where:
              '${CompletionColumns.habitId} = ? '
              'AND ${CompletionColumns.completedAt} = ?',
          whereArgs: [habitId, row[CompletionColumns.completedAt]],
          limit: 1,
        );
        if (duplicate.isNotEmpty) continue;

        await txn.insert(AppConstants.tableCompletions, row);
        completionCount++;
      }
    });

    return ImportSummary(habits: habitCount, completions: completionCount);
  }
}
