// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_blocking_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppBlockingSettingsAdapter extends TypeAdapter<AppBlockingSettings> {
  @override
  final int typeId = 6;

  @override
  AppBlockingSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppBlockingSettings(
      id: fields[0] as String,
      userId: fields[1] as String,
      isEnabled: fields[2] as bool,
      blockedApps: (fields[3] as List).cast<String>(),
      blockingMode: fields[4] as String,
      checkIntervalMs: fields[5] as int,
      showNotifications: fields[6] as bool,
      vibrateOnBlock: fields[7] as bool,
      blockMessage: fields[8] as String,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppBlockingSettings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.isEnabled)
      ..writeByte(3)
      ..write(obj.blockedApps)
      ..writeByte(4)
      ..write(obj.blockingMode)
      ..writeByte(5)
      ..write(obj.checkIntervalMs)
      ..writeByte(6)
      ..write(obj.showNotifications)
      ..writeByte(7)
      ..write(obj.vibrateOnBlock)
      ..writeByte(8)
      ..write(obj.blockMessage)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBlockingSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
