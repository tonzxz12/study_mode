import 'package:hive/hive.dart';

part 'subject.g.dart';

@HiveType(typeId: 0)
class Subject extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String color;

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.color,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Subject copyWith({
    String? id,
    String? name,
    String? color,
    String? description,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Subject(id: $id, name: $name, color: $color)';
  }
}
