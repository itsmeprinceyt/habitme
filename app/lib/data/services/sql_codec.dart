import 'package:habit_me/core/constants/app_constants.dart';
import 'package:habit_me/data/models/completion.dart';
import 'package:habit_me/data/models/habit.dart';
import 'package:habit_me/data/models/label.dart';

/// Rows read from a backup file, already type-checked and safe to write.
class ParsedBackup {
  const ParsedBackup({
    required this.habits,
    required this.completions,
    this.labels = const [],
  });

  final List<Map<String, Object?>> habits;
  final List<Map<String, Object?>> completions;
  final List<Map<String, Object?>> labels;

  int get labelCount => labels.length;
  int get rowCount => labels.length + habits.length + completions.length;

  bool get isEmpty => rowCount == 0;
}

/// Turns the label/habit/completion tables into a portable `.sql` dump and back.
///
/// Nothing is ever executed as SQL: [decode] reads the statements positionally,
/// rejects any table or column outside [_schemas] and any value that cannot be
/// coerced to the declared column type, so a corrupt or hand-edited file fails
/// with a usable message instead of damaging the database.
abstract final class SqlCodec {
  /// Every table a backup may contain, with its exact column layout.
  static const Map<String, List<_Column>> _schemas = {
    AppConstants.tableLabels: [
      _Column(LabelColumns.id, isText: true, required: true),
      _Column(LabelColumns.name, isText: true, required: true),
      _Column(LabelColumns.color),
      _Column(LabelColumns.createdAt, required: true),
    ],
    AppConstants.tableHabits: [
      _Column(HabitColumns.id, isText: true, required: true),
      _Column(HabitColumns.name, isText: true, required: true),
      _Column(HabitColumns.labelId, isText: true),
      _Column(HabitColumns.isRecurring, required: true),
      _Column(HabitColumns.recurUnit, isText: true),
      _Column(HabitColumns.recurInterval),
      _Column(HabitColumns.notify, required: true),
      _Column(HabitColumns.isDone, required: true),
      _Column(HabitColumns.oneTimeAt),
      _Column(HabitColumns.anchorAt, required: true),
      _Column(HabitColumns.nextDueAt),
      _Column(HabitColumns.completedAt),
      _Column(HabitColumns.createdAt, required: true),
      _Column(HabitColumns.updatedAt, required: true),
    ],
    AppConstants.tableCompletions: [
      _Column(CompletionColumns.habitId, isText: true, required: true),
      _Column(CompletionColumns.completedAt, required: true),
    ],
  };

  static final List<String> _tableNames = _schemas.keys.toList();

  static final RegExp _insert = RegExp(
    'INSERT(?:\\s+OR\\s+(?:REPLACE|IGNORE|FAIL|ABORT|ROLLBACK))?'
    '\\s+INTO\\s+"?([A-Za-z_]+)"?\\s*\\(([^)]*)\\)\\s*VALUES\\s*\\(',
    caseSensitive: false,
  );

  /// Builds the dump. Rows are written in the order the tables depend on
  /// (labels, then habits, then completions) so the file can also be applied by
  /// an external SQLite tool without tripping the foreign key.
  static String encode({
    required List<Map<String, Object?>> labels,
    required List<Map<String, Object?>> habits,
    required List<Map<String, Object?>> completions,
  }) {
    final buffer = StringBuffer()
      ..writeln(AppConstants.backupMarker)
      ..writeln('-- exported ${DateTime.now().toIso8601String()}')
      ..writeln(
        '-- ${labels.length} labels, ${habits.length} habits, '
        '${completions.length} completions',
      )
      ..writeln('BEGIN TRANSACTION;');

    _writeTable(buffer, AppConstants.tableLabels, labels);
    _writeTable(buffer, AppConstants.tableHabits, habits);
    _writeTable(buffer, AppConstants.tableCompletions, completions);

    buffer.writeln('COMMIT;');
    return buffer.toString();
  }

  static void _writeTable(
    StringBuffer buffer,
    String table,
    List<Map<String, Object?>> rows,
  ) {
    final columns = _schemas[table]!;
    final columnList = columns.map((c) => c.name).join(', ');
    for (final row in rows) {
      final values = <String>[];
      for (var i = 0; i < columns.length; i++) {
        final column = columns[i];
        // Look the value up by name and tolerate a row that carries extras.
        values.add(_literal(row[column.name], column));
      }
      buffer.writeln(
        'INSERT INTO $table ($columnList) VALUES (${values.join(', ')});',
      );
    }
  }

  static String _literal(Object? value, _Column column) {
    if (value == null) return 'NULL';
    if (column.isText) return "'${value.toString().replaceAll("'", "''")}'";
    if (value is bool) return value ? '1' : '0';
    if (value is int) return '$value';
    if (value is num) return value.toInt().toString();
    final parsed = int.tryParse(value.toString());
    if (parsed != null) return '$parsed';
    // Never drop a value because of an unexpected type: keep it quoted and let
    // decode() decide whether it fits the column.
    return "'${value.toString().replaceAll("'", "''")}'";
  }

  static ParsedBackup decode(String text) {
    final source = _normalizeLineEndings(text);

    if (!_startsWithMarker(source)) {
      throw FormatException(
        'This file is not a HabitMe backup - it must start with '
        '"${AppConstants.backupMarker}".',
      );
    }

    final rows = <String, List<Map<String, Object?>>>{
      for (final table in _tableNames) table: <Map<String, Object?>>[],
    };

    var pos = 0;
    while (true) {
      pos = _skipSpace(source, pos);
      if (pos >= source.length) break;

      // Comment line: skip to the end of the line.
      if (source.startsWith('--', pos)) {
        final end = source.indexOf('\n', pos);
        pos = end == -1 ? source.length : end + 1;
        continue;
      }

      // Transaction wrappers and pragmas carry no data: step over them.
      if (_startsWithAnyOf(source, pos, const [
        'BEGIN',
        'COMMIT',
        'END',
        'PRAGMA',
      ])) {
        final end = source.indexOf(';', pos);
        pos = end == -1 ? source.length : end + 1;
        continue;
      }

      final match = _insert.matchAsPrefix(source, pos);
      if (match == null) {
        throw FormatException(
          'Unsupported statement on line ${_lineAt(source, pos)}: '
          '${_snippet(source, pos)}',
        );
      }

      final table = match.group(1)!.toLowerCase();
      final schema = _schemas[table];
      if (schema == null) {
        throw FormatException(
          'Line ${_lineAt(source, pos)}: table "$table" is not part of a '
          'HabitMe backup.',
        );
      }

      final columns = match
          .group(2)!
          .split(',')
          .map((column) => column.trim().replaceAll('"', ''))
          .where((column) => column.isNotEmpty)
          .toList();

      for (final column in columns) {
        if (!schema.any((c) => c.name == column)) {
          throw FormatException(
            'Line ${_lineAt(source, pos)}: unknown column "$column" for table '
            '"$table".',
          );
        }
      }

      final reader = _ValueReader(source, match.end);
      while (true) {
        final values = reader.readTuple();
        if (values.length != columns.length) {
          throw FormatException(
            'Line ${_lineAt(source, pos)}: ${values.length} values do not match '
            'the ${columns.length} columns of "$table".',
          );
        }
        pos = reader.position;

        final row = <String, Object?>{};
        for (var i = 0; i < columns.length; i++) {
          row[columns[i]] = values[i];
        }
        rows[table]!.add(_validate(table, row));

        final next = _skipSpace(source, pos);
        if (next < source.length && source[next] == ',') {
          // Another value tuple of the same statement: VALUES (..), (..);
          final open = _skipSpace(source, next + 1);
          if (open >= source.length || source[open] != '(') {
            throw FormatException(
              'Line ${_lineAt(source, pos)}: malformed value list.',
            );
          }
          reader.reset(open + 1);
          continue;
        }

        pos = _expectTerminator(source, next, pos);
        break;
      }
    }

    final backup = ParsedBackup(
      labels: rows[AppConstants.tableLabels]!,
      habits: rows[AppConstants.tableHabits]!,
      completions: rows[AppConstants.tableCompletions]!,
    );

    if (backup.isEmpty) {
      throw const FormatException(
        'The backup file contains no labels, habits or completions.',
      );
    }
    return backup;
  }

  /// Coerces the values to the column types and lets the models double-check
  /// the row, so a bad record is reported instead of breaking a later write.
  static Map<String, Object?> _validate(
    String table,
    Map<String, Object?> raw,
  ) {
    final schema = _schemas[table]!;
    final row = <String, Object?>{};
    for (final column in schema) {
      row[column.name] = column.coerce(raw[column.name], table);
    }

    try {
      switch (table) {
        case AppConstants.tableLabels:
          HabitLabel.fromMap(row);
        case AppConstants.tableHabits:
          Habit.fromMap(row);
        case AppConstants.tableCompletions:
          Completion.fromMap(row);
      }
    } on Object catch (error) {
      throw FormatException(
        'Invalid ${_singular(table)} in the backup: $error',
      );
    }
    return row;
  }

  static String _singular(String table) => switch (table) {
    AppConstants.tableLabels => 'label',
    AppConstants.tableHabits => 'habit',
    _ => 'completion',
  };

  static String _normalizeLineEndings(String text) {
    final withoutBom = text.startsWith('\uFEFF') ? text.substring(1) : text;
    return withoutBom.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  static bool _startsWithMarker(String source) {
    final firstLine = source.trimLeft();
    return firstLine.startsWith(AppConstants.backupMarker) ||
        firstLine.startsWith('-- habit-tracker-backup');
  }

  static bool _startsWithAnyOf(String source, int pos, List<String> prefixes) {
    final head = source
        .substring(pos, pos + 16 > source.length ? source.length : pos + 16)
        .toUpperCase();
    return prefixes.any(head.startsWith);
  }

  static int _skipSpace(String text, int pos) {
    while (pos < text.length && text[pos].trim().isEmpty) {
      pos++;
    }
    return pos;
  }

  static int _expectTerminator(String source, int next, int pos) {
    if (next < source.length && source[next] == ';') return next + 1;
    // Some editors drop the final semicolon; the statement is still complete.
    if (next >= source.length) return source.length;
    throw FormatException(
      'Line ${_lineAt(source, pos)}: statement is not terminated with ";".',
    );
  }

  static int _lineAt(String source, int pos) {
    var line = 1;
    for (var i = 0; i < pos && i < source.length; i++) {
      if (source[i] == '\n') line++;
    }
    return line;
  }

  static String _snippet(String source, int pos) {
    final end = source.indexOf('\n', pos);
    final stop = end == -1 || end > pos + 60 ? pos + 60 : end;
    return '${source.substring(pos, stop > pos ? stop : pos)}...';
  }
}

/// One column of a whitelisted table.
class _Column {
  const _Column(this.name, {this.isText = false, this.required = false});

  final String name;
  final bool isText;
  final bool required;

  /// Normalises a parsed value to what the table actually stores, so the later
  /// database write cannot fail on a type that only looks right.
  Object? coerce(Object? value, String table) {
    if (value == null) {
      if (required) {
        throw FormatException(
          'The backup has a NULL in the required column "$name" of "$table".',
        );
      }
      return null;
    }

    if (isText) {
      final text = value.toString();
      if (text.isEmpty && required) {
        throw FormatException('The backup has an empty "$name" in "$table".');
      }
      return text;
    }

    if (value is int) return value;
    if (value is bool) return value ? 1 : 0;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value.toString().trim());
    if (parsed == null) {
      throw FormatException(
        'The value "$value" for "$name" in "$table" is not a number.',
      );
    }
    return parsed;
  }
}

/// Reads the `(...)` value list of an INSERT statement.
class _ValueReader {
  _ValueReader(this._text, this.position);

  final String _text;
  int position;

  void reset(int next) => position = next;

  List<Object?> readTuple() {
    final values = <Object?>[];
    while (true) {
      values.add(_readValue());
      _skipWhitespace();
      if (position >= _text.length) {
        throw const FormatException(
          'The backup file ends inside a value list.',
        );
      }
      final char = _text[position];
      position++;
      if (char == ',') continue;
      if (char == ')') break;
      throw FormatException(
        'Unexpected "$char" where a value was expected '
        '(line ${SqlCodec._lineAt(_text, position)}).',
      );
    }
    return values;
  }

  Object? _readValue() {
    _skipWhitespace();
    if (position >= _text.length) {
      throw const FormatException('The backup file ends inside a value list.');
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
      throw FormatException(
        'Invalid value "${token.isEmpty ? '<empty>' : token}" at line '
        '${SqlCodec._lineAt(_text, start)}.',
      );
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
    throw const FormatException(
      'An unfinished text value was found in the backup.',
    );
  }

  void _skipWhitespace() {
    while (position < _text.length && _text[position].trim().isEmpty) {
      position++;
    }
  }
}
