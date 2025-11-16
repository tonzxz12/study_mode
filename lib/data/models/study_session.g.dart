// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudySessionAdapter extends TypeAdapter<StudySession> {
  @override
  final int typeId = 1;

  @override
  StudySession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudySession(
      id: fields[0] as String,
      subjectId: fields[1] as String,
      userId: fields[11] as String,
      startTime: fields[2] as DateTime,
      endTime: fields[3] as DateTime?,
      targetDuration: fields[4] as Duration?,
      notes: fields[5] as String,
      isCompleted: fields[6] as bool,
      focusScore: fields[7] as double,
      title: fields[8] as String,
      calendarEventId: fields[9] as String?,
      blockedApps: (fields[10] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, StudySession obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subjectId)
      ..writeByte(2)
      ..write(obj.startTime)
      ..writeByte(3)
      ..write(obj.endTime)
      ..writeByte(4)
      ..write(obj.targetDuration)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.focusScore)
      ..writeByte(8)
      ..write(obj.title)
      ..writeByte(9)
      ..write(obj.calendarEventId)
      ..writeByte(10)
      ..write(obj.blockedApps)
      ..writeByte(11)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
