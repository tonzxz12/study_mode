import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;

  @HiveField(1)
  bool notificationsEnabled;

  @HiveField(2)
  Duration defaultStudyDuration;

  @HiveField(3)
  Duration defaultBreakDuration;

  @HiveField(4)
  bool studyModeEnabled;

  @HiveField(5)
  List<String> blockedApps;

  @HiveField(6)
  String selectedTheme;

  AppSettings({
    this.isDarkMode = false,
    this.notificationsEnabled = true,
    Duration? defaultStudyDuration,
    Duration? defaultBreakDuration,
    this.studyModeEnabled = false,
    List<String>? blockedApps,
    this.selectedTheme = 'blue',
  })  : defaultStudyDuration = defaultStudyDuration ?? const Duration(minutes: 25),
        defaultBreakDuration = defaultBreakDuration ?? const Duration(minutes: 5),
        blockedApps = blockedApps ?? [];

  AppSettings copyWith({
    bool? isDarkMode,
    bool? notificationsEnabled,
    Duration? defaultStudyDuration,
    Duration? defaultBreakDuration,
    bool? studyModeEnabled,
    List<String>? blockedApps,
    String? selectedTheme,
  }) {
    return AppSettings(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultStudyDuration: defaultStudyDuration ?? this.defaultStudyDuration,
      defaultBreakDuration: defaultBreakDuration ?? this.defaultBreakDuration,
      studyModeEnabled: studyModeEnabled ?? this.studyModeEnabled,
      blockedApps: blockedApps ?? List.from(this.blockedApps),
      selectedTheme: selectedTheme ?? this.selectedTheme,
    );
  }

  @override
  String toString() {
    return 'AppSettings(darkMode: $isDarkMode, notifications: $notificationsEnabled)';
  }
}
