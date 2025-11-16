// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalendarEventAdapter extends TypeAdapter<CalendarEvent> {
  @override
  final int typeId = 4;

  @override
  CalendarEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalendarEvent(
      id: fields[0] as String,
      title: fields[1] as String,
      startTime: fields[3] as DateTime,
      userId: fields[8] as String,
      description: fields[2] as String,
      endTime: fields[4] as DateTime?,
      durationMinutes: fields[5] as int?,
      subjectId: fields[6] as String?,
      taskId: fields[7] as String?,
      isCompleted: fields[9] as bool,
      createdAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CalendarEvent obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.durationMinutes)
      ..writeByte(6)
      ..write(obj.subjectId)
      ..writeByte(7)
      ..write(obj.taskId)
      ..writeByte(8)
      ..write(obj.userId)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
