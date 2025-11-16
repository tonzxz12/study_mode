import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 3)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String subjectId;

  @HiveField(4)
  String priority;

  @HiveField(5)
  DateTime dueDate;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String userId;

  Task({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.userId,
    this.description = '',
    this.priority = 'Medium',
    required this.dueDate,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? subjectId,
    String? priority,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    String? userId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Firestore serialization
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'priority': priority,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  static Task fromFirestore(Map<String, dynamic> data) {
    return Task(
      id: data['id'] as String,
      title: data['title'] as String,
      subjectId: data['subjectId'] as String,
      userId: data['userId'] as String,
      description: data['description'] as String? ?? '',
      priority: data['priority'] as String? ?? 'Medium',
      dueDate: DateTime.parse(data['dueDate'] as String),
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, subject: $subjectId, due: ${dueDate.day}/${dueDate.month})';
  }
}