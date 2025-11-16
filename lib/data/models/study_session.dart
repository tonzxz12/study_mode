import 'package:hive/hive.dart';

part 'study_session.g.dart';

@HiveType(typeId: 1)
class StudySession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String subjectId;

  @HiveField(2)
  DateTime startTime;

  @HiveField(3)
  DateTime? endTime;

  @HiveField(4)
  Duration targetDuration;

  @HiveField(5)
  String notes;

  @HiveField(6)
  bool isCompleted;

  @HiveField(7)
  double focusScore;

  @HiveField(8)
  String title;

  @HiveField(9)
  String? calendarEventId;

  @HiveField(10)
  List<String> blockedApps;

  @HiveField(11)
  String userId;

  StudySession({
    required this.id,
    required this.subjectId,
    required this.userId,
    required this.startTime,
    this.endTime,
    Duration? targetDuration,
    this.notes = '',
    this.isCompleted = false,
    this.focusScore = 0.0,
    this.title = '',
    this.calendarEventId,
    this.blockedApps = const [],
  }) : targetDuration = targetDuration ?? const Duration(hours: 1);

  Duration get actualDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return Duration.zero;
  }

  bool get isActive => endTime == null && !isCompleted;

  StudySession copyWith({
    String? id,
    String? subjectId,
    DateTime? startTime,
    DateTime? endTime,
    Duration? targetDuration,
    String? notes,
    bool? isCompleted,
    double? focusScore,
    String? title,
    String? calendarEventId,
    List<String>? blockedApps,
    String? userId,
  }) {
    return StudySession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      targetDuration: targetDuration ?? this.targetDuration,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      focusScore: focusScore ?? this.focusScore,
      title: title ?? this.title,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      blockedApps: blockedApps ?? this.blockedApps,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'subjectId': subjectId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'targetDuration': targetDuration.inMinutes,
      'notes': notes,
      'isCompleted': isCompleted,
      'focusScore': focusScore,
      'title': title,
      'calendarEventId': calendarEventId,
      'blockedApps': blockedApps,
    };
  }

  factory StudySession.fromFirestore(Map<String, dynamic> data) {
    return StudySession(
      id: data['id'] as String,
      subjectId: data['subjectId'] as String,
      userId: data['userId'] as String,
      startTime: DateTime.parse(data['startTime'] as String),
      endTime: data['endTime'] != null ? DateTime.parse(data['endTime'] as String) : null,
      targetDuration: Duration(minutes: (data['targetDuration'] as num).toInt()),
      notes: data['notes'] as String? ?? '',
      isCompleted: data['isCompleted'] as bool? ?? false,
      focusScore: (data['focusScore'] as num?)?.toDouble() ?? 0.0,
      title: data['title'] as String? ?? '',
      calendarEventId: data['calendarEventId'] as String?,
      blockedApps: List<String>.from(data['blockedApps'] as List? ?? []),
    );
  }

  @override
  String toString() {
    return 'StudySession(id: $id, subject: $subjectId, duration: ${actualDuration.inMinutes}min)';
  }
}