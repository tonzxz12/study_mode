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

  StudySession({
    required this.id,
    required this.subjectId,
    required this.startTime,
    this.endTime,
    Duration? targetDuration,
    this.notes = '',
    this.isCompleted = false,
    this.focusScore = 0.0,
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
  }) {
    return StudySession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      targetDuration: targetDuration ?? this.targetDuration,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      focusScore: focusScore ?? this.focusScore,
    );
  }

  @override
  String toString() {
    return 'StudySession(id: $id, subject: $subjectId, duration: ${actualDuration.inMinutes}min)';
  }
}
