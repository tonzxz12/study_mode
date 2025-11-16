import 'package:hive/hive.dart';

part 'calendar_event.g.dart';

@HiveType(typeId: 4)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime startTime;

  @HiveField(4)
  DateTime endTime;

  @HiveField(5)
  int durationMinutes;

  @HiveField(6)
  String? subjectId; // Optional connection to subject

  @HiveField(7)
  String? taskId; // Optional connection to task

  @HiveField(8)
  String userId;

  @HiveField(9)
  bool isCompleted;

  @HiveField(10)
  DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.userId,
    this.description = '',
    DateTime? endTime,
    int? durationMinutes,
    this.subjectId,
    this.taskId,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : durationMinutes = durationMinutes ?? 25,
       endTime = endTime ?? startTime.add(Duration(minutes: durationMinutes ?? 25)),
       createdAt = createdAt ?? DateTime.now();

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? subjectId,
    String? taskId,
    String? userId,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      subjectId: subjectId ?? this.subjectId,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
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
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'subjectId': subjectId,
      'taskId': taskId,
      'userId': userId,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static CalendarEvent fromFirestore(Map<String, dynamic> data) {
    return CalendarEvent(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: DateTime.parse(data['endTime'] as String),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 25,
      subjectId: data['subjectId'] as String?,
      taskId: data['taskId'] as String?,
      userId: data['userId'] as String,
      isCompleted: data['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(data['createdAt'] as String),
    );
  }

  @override
  String toString() {
    return 'CalendarEvent(id: $id, title: $title, duration: ${durationMinutes}min)';
  }
}