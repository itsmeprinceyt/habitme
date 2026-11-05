import 'package:uuid/uuid.dart';

abstract final class LabelColumns {
  static const id = 'id';
  static const name = 'name';
  static const color = 'color';
  static const createdAt = 'created_at';
}

class HabitLabel {
  const HabitLabel({
    required this.id,
    required this.name,
    this.color,
    required this.createdAt,
  });

  factory HabitLabel.create({required String name, int? color, DateTime? now}) {
    final created = now ?? DateTime.now();
    return HabitLabel(
      id: const Uuid().v4(),
      name: name.trim(),
      color: color,
      createdAt: created,
    );
  }

  factory HabitLabel.fromMap(Map<String, Object?> map) {
    return HabitLabel(
      id: map[LabelColumns.id] as String,
      name: map[LabelColumns.name] as String,
      color: map[LabelColumns.color] as int?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[LabelColumns.createdAt] as int,
      ),
    );
  }

  final String id;
  final String name;
  final int? color;
  final DateTime createdAt;

  HabitLabel copyWith({String? name, int? color, DateTime? createdAt}) {
    return HabitLabel(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      LabelColumns.id: id,
      LabelColumns.name: name,
      LabelColumns.color: color,
      LabelColumns.createdAt: createdAt.millisecondsSinceEpoch,
    };
  }
}
