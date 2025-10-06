// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      isDarkMode: fields[0] as bool,
      notificationsEnabled: fields[1] as bool,
      defaultStudyDuration: fields[2] as Duration?,
      defaultBreakDuration: fields[3] as Duration?,
      studyModeEnabled: fields[4] as bool,
      blockedApps: (fields[5] as List?)?.cast<String>(),
      selectedTheme: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.defaultStudyDuration)
      ..writeByte(3)
      ..write(obj.defaultBreakDuration)
      ..writeByte(4)
      ..write(obj.studyModeEnabled)
      ..writeByte(5)
      ..write(obj.blockedApps)
      ..writeByte(6)
      ..write(obj.selectedTheme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
