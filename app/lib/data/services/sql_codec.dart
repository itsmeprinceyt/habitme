import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/data/models/completion.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/label.dart';

class ParsedBackup {
  const ParsedBackup({
    required this.habits,
    required this.completions,
    this.labels = const [],
  });

  final List<Map<String, Object?>> habits;
  final List<Map<String, Object?>> completions;
  final List<Map<String, Object?>> labels;
}

abstract final class SqlCodec {
  static const _labelColumns = [
    LabelColumns.id,
    LabelColumns.name,
    LabelColumns.color,
    LabelColumns.createdAt,
  ];

  static const _habitColumns = [
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
  ];

  static const _completionColumns = [
    CompletionColumns.habitId,
    CompletionColumns.completedAt,
  ];

  static String encode(
    List<Habit> habits,
    List<Completion> completions, [
    List<HabitLabel> labels = const [],
  ]) {
    final buffer = StringBuffer()
      ..writeln(AppConstants.backupMarker)
      ..writeln('-- exported ${DateTime.now().toIso8601String()}')
      ..writeln('BEGIN TRANSACTION;');

    for (final label in labels) {
      final map = label.toMap();
      buffer.writeln(_statement(AppConstants.tableLabels, _labelColumns, map));
    }
    for (final habit in habits) {
      final map = habit.toMap();
      buffer.writeln(_statement(AppConstants.tableHabits, _habitColumns, map));
    }
    for (final completion in completions) {
      final map = completion.toMap();
      buffer.writeln(
        _statement(AppConstants.tableCompletions, _completionColumns, map),
      );
    }

    buffer.writeln('COMMIT;');
    return buffer.toString();
  }

  static String _statement(
    String table,
    List<String> columns,
    Map<String, Object?> map,
  ) {
    final values = columns.map((c) => _literal(map[c])).join(', ');
    return 'INSERT INTO $table (${columns.join(', ')}) VALUES ($values);';
  }

  static String _literal(Object? value) {
    if (value == null) return 'NULL';
    if (value is num) return value.toString();
    final escaped = value.toString().replaceAll("'", "''");
    return "'$escaped'";
  }

  static ParsedBackup decode(String text) {
    final cleaned = text.startsWith('\uFEFF') ? text.substring(1) : text;
    if (!cleaned.trimLeft().startsWith(AppConstants.backupMarker)) {
      throw const FormatException('Not a HabitMe backup file');
    }

    final labels = <Map<String, Object?>>[];
    final habits = <Map<String, Object?>>[];
    final completions = <Map<String, Object?>>[];
    final statement = RegExp(
      r'INSERT(?:\s+OR\s+REPLACE)?\s+INTO\s+(habits|completions|labels)\s*\(([^)]*)\)\s*VALUES\s*\(',
      caseSensitive: false,
    );

    var pos = 0;
    while (pos < cleaned.length) {
      pos = _skipSpace(cleaned, pos);
      if (pos >= cleaned.length) break;

      if (cleaned.startsWith('--', pos)) {
        final end = cleaned.indexOf('\n', pos);
        pos = end == -1 ? cleaned.length : end + 1;
        continue;
      }

      final upper = cleaned
          .substring(pos, pos + 20 > cleaned.length ? cleaned.length : pos + 20)
          .toUpperCase();
      if (upper.startsWith('BEGIN TRANSACTION;')) {
        pos += 'BEGIN TRANSACTION;'.length;
        continue;
      }
      if (upper.startsWith('BEGIN;')) {
        pos += 'BEGIN;'.length;
        continue;
      }
      if (upper.startsWith('COMMIT;')) {
        pos += 'COMMIT;'.length;
        continue;
      }

      final match = statement.matchAsPrefix(cleaned, pos);
      if (match == null) {
        throw const FormatException('Unsupported statement in backup file');
      }

      final table = match.group(1)!.toLowerCase();
      final columns = match.group(2)!.split(',').map((c) => c.trim()).toList();
      final List<String> allowed;
      if (table == AppConstants.tableLabels) {
        allowed = _labelColumns;
      } else if (table == AppConstants.tableHabits) {
        allowed = _habitColumns;
      } else {
        allowed = _completionColumns;
      }

      if (columns.any((c) => !allowed.contains(c))) {
        throw const FormatException('Unknown column in backup file');
      }

      final reader = _ValueReader(cleaned, match.end);
      final values = reader.readValues();
      if (values.length != columns.length) {
        throw const FormatException('Column and value count mismatch');
      }
      pos = reader.position;

      final row = <String, Object?>{
        for (var i = 0; i < columns.length; i++) columns[i]: values[i],
      };
      if (table == AppConstants.tableLabels) {
        HabitLabel.fromMap(row);
        labels.add(row);
      } else if (table == AppConstants.tableHabits) {
        Habit.fromMap(row);
        habits.add(row);
      } else {
        Completion.fromMap(row);
        completions.add(row);
      }
    }

    return ParsedBackup(
      labels: labels,
      habits: habits,
      completions: completions,
    );
  }

  static int _skipSpace(String text, int pos) {
    while (pos < text.length && text[pos].trim().isEmpty) {
      pos++;
    }
    return pos;
  }
}

class _ValueReader {
  _ValueReader(this._text, this.position);

  final String _text;
  int position;

  List<Object?> readValues() {
    final values = <Object?>[];
    while (true) {
      values.add(_readValue());
      _skipWhitespace();
      if (position >= _text.length) {
        throw const FormatException('Unexpected end of backup file');
      }
      final char = _text[position];
      position++;
      if (char == ',') continue;
      if (char == ')') break;
      throw const FormatException('Malformed values in backup file');
    }
    _skipWhitespace();
    if (position < _text.length && _text[position] == ';') position++;
    return values;
  }

  Object? _readValue() {
    _skipWhitespace();
    if (position >= _text.length) {
      throw const FormatException('Unexpected end of backup file');
    }
    if (_text[position] == "'") return _readString();

    final start = position;
    while (position < _text.length &&
        _text[position] != ',' &&
        _text[position] != ')') {
      position++;
    }
    final token = _text.substring(start, position).trim();
    if (token.toUpperCase() == 'NULL') return null;
    final number = int.tryParse(token);
    if (number == null) {
      throw const FormatException('Invalid value in backup file');
    }
    return number;
  }

  String _readString() {
    position++;
    final buffer = StringBuffer();
    while (position < _text.length) {
      final char = _text[position];
      if (char == "'") {
        if (position + 1 < _text.length && _text[position + 1] == "'") {
          buffer.write("'");
          position += 2;
          continue;
        }
        position++;
        return buffer.toString();
      }
      buffer.write(char);
      position++;
    }
    throw const FormatException('Unterminated string in backup file');
  }

  void _skipWhitespace() {
    while (position < _text.length && _text[position].trim().isEmpty) {
      position++;
    }
  }
}
