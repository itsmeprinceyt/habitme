import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/data/db/app_database.dart';
import 'package:habit_me/data/models/completion.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/label.dart';
import 'package:habit_me/data/services/sql_codec.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

/// What an import actually did, so the UI can report it honestly.
class ImportSummary {
  const ImportSummary({
    required this.habits,
    required this.completions,
    this.labels = 0,
    this.orphanCompletions = 0,
    this.unlabelledHabits = 0,
  });

  final int habits;
  final int completions;
  final int labels;

  /// Completions whose habit was not in the backup and in the database.
  final int orphanCompletions;

  /// Habits whose label could not be found, imported without one.
  final int unlabelledHabits;
}

class BackupService {
  BackupService(this._database);

  final AppDatabase _database;

  /// Dumps every row of the labels, habits and completions tables.
  ///
  /// The rows go straight from the database into the file, so nothing is
  /// normalised away on the way out and the import gets the full record.
  /// Returns the file name that was handed to the share sheet.
  Future<String> exportSql() async {
    final db = await _database.database;
    final labelRows = await db.query(
      AppConstants.tableLabels,
      orderBy: '${LabelColumns.name} COLLATE NOCASE ASC',
    );
    final habitRows = await db.query(
      AppConstants.tableHabits,
      orderBy: '${HabitColumns.createdAt} ASC',
    );
    final completionRows = await db.query(
      AppConstants.tableCompletions,
      orderBy: '${CompletionColumns.completedAt} ASC',
    );

    final content = SqlCodec.encode(
      labels: labelRows,
      habits: habitRows,
      completions: completionRows,
    );

    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = '${AppConstants.backupFilePrefix}_$stamp.sql';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content, flush: true);

    debugPrint(
      'Backup: wrote ${content.length} bytes with ${labelRows.length} labels, '
      '${habitRows.length} habits, ${completionRows.length} completions',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '${AppConstants.appName} backup',
      ),
    );

    return fileName;
  }

  /// Merges a backup into the database by id: records that exist are updated,
  /// new ones are inserted and completion history is kept. Returns `null` when
  /// the user cancels the file chooser.
  Future<ImportSummary?> importSql() async {
    final files = await FilePicker.pickFiles(type: FileType.any);
    if (files.isEmpty) return null;

    final picked = files.first;
    final text = utf8.decode(await _readBytes(picked), allowMalformed: true);

    final parsed = SqlCodec.decode(text);
    debugPrint(
      'Backup: parsed ${parsed.labelCount} labels, ${parsed.habits.length} '
      'habits, ${parsed.completions.length} completions from ${picked.name}',
    );

    final db = await _database.database;
    var labelCount = 0;
    var habitCount = 0;
    var completionCount = 0;
    var orphanCompletions = 0;
    var unlabelledHabits = 0;

    await db.transaction((txn) async {
      // Labels first: habits reference them, and the foreign key is enforced on
      // databases created by the current schema.
      final labelIds = <String>{
        for (final row in await txn.query(
          AppConstants.tableLabels,
          columns: [LabelColumns.id],
        ))
          row[LabelColumns.id]! as String,
      };

      for (final row in parsed.labels) {
        final id = row[LabelColumns.id]! as String;
        final changed = await txn.update(
          AppConstants.tableLabels,
          row,
          where: '${LabelColumns.id} = ?',
          whereArgs: [id],
        );
        if (changed == 0) {
          await txn.insert(
            AppConstants.tableLabels,
            row,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        labelIds.add(id);
        labelCount++;
      }

      final habitIds = <String>{
        for (final row in await txn.query(
          AppConstants.tableHabits,
          columns: [HabitColumns.id],
        ))
          row[HabitColumns.id]! as String,
      };

      for (final record in parsed.habits) {
        final row = Map<String, Object?>.of(record);
        final id = row[HabitColumns.id]! as String;

        // A habit may only point at a label that really exists. Older databases
        // (upgraded schemas) have no foreign key on label_id, so a deleted label
        // could leave a habit pointing at nothing: import those unlabelled
        // instead of failing the whole restore.
        final labelId = row[HabitColumns.labelId];
        if (labelId is String && !labelIds.contains(labelId)) {
          row[HabitColumns.labelId] = null;
          unlabelledHabits++;
        }

        final changed = await txn.update(
          AppConstants.tableHabits,
          row,
          where: '${HabitColumns.id} = ?',
          whereArgs: [id],
        );
        if (changed == 0) {
          await txn.insert(
            AppConstants.tableHabits,
            row,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
        habitIds.add(id);
        habitCount++;
      }

      // Only the two data columns are written: the autoincrement id belongs to
      // this database. Pre-loading the existing pairs keeps re-imports free of
      // duplicate history without a query per row.
      final seenCompletions = <String>{
        for (final row in await txn.query(
          AppConstants.tableCompletions,
          columns: [CompletionColumns.habitId, CompletionColumns.completedAt],
        ))
          '${row[CompletionColumns.habitId]}@${row[CompletionColumns.completedAt]}',
      };

      for (final row in parsed.completions) {
        final habitId = row[CompletionColumns.habitId]! as String;
        if (!habitIds.contains(habitId)) {
          orphanCompletions++;
          continue;
        }

        final key = '$habitId@${row[CompletionColumns.completedAt]}';
        if (!seenCompletions.add(key)) continue;

        await txn.insert(AppConstants.tableCompletions, {
          CompletionColumns.habitId: habitId,
          CompletionColumns.completedAt: row[CompletionColumns.completedAt],
        });
        completionCount++;
      }
    });

    return ImportSummary(
      habits: habitCount,
      completions: completionCount,
      labels: labelCount,
      orphanCompletions: orphanCompletions,
      unlabelledHabits: unlabelledHabits,
    );
  }

  /// Reads the picked file through the platform's own file access, which is the
  /// only way that works for content URIs (Downloads, Drive, a Files provider)
  /// on Android, then falls back to the plain path when there is one.
  Future<Uint8List> _readBytes(PlatformFile file) async {
    try {
      return await file.readAsBytes();
    } on Object catch (error) {
      final path = file.path;
      if (path == null) rethrow;
      debugPrint('Backup: platform read failed ($error), retrying via $path');
      return File(path).readAsBytes();
    }
  }
}
