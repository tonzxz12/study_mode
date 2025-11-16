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

  @HiveField(5)
  String userId;

  Subject({
    required this.id,
    required this.name,
    required this.userId,
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
    String? userId,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      color: color ?? this.color,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  static Subject fromFirestore(Map<String, dynamic> data) {
    return Subject(
      id: data['id'] as String,
      name: data['name'] as String,
      userId: data['userId'] as String,
      color: data['color'] as String,
      description: data['description'] as String? ?? '',
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'Subject(id: $id, name: $name, color: $color)';
  }
}
