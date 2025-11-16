import 'package:hive/hive.dart';

part 'app_blocking_settings.g.dart';

@HiveType(typeId: 6)
class AppBlockingSettings extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String userId;

  @HiveField(2)
  bool isEnabled;

  @HiveField(3)
  List<String> blockedApps;

  @HiveField(4)
  String blockingMode; // 'TIMER_ONLY', 'CONTINUOUS', 'SCHEDULE'

  @HiveField(5)
  int checkIntervalMs;

  @HiveField(6)
  bool showNotifications;

  @HiveField(7)
  bool vibrateOnBlock;

  @HiveField(8)
  String blockMessage;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  AppBlockingSettings({
    required this.id,
    required this.userId,
    this.isEnabled = false,
    this.blockedApps = const [],
    this.blockingMode = 'TIMER_ONLY',
    this.checkIntervalMs = 1000,
    this.showNotifications = true,
    this.vibrateOnBlock = true,
    this.blockMessage = 'This app is blocked during study time. Stay focused! 📚',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  AppBlockingSettings copyWith({
    String? id,
    String? userId,
    bool? isEnabled,
    List<String>? blockedApps,
    String? blockingMode,
    int? checkIntervalMs,
    bool? showNotifications,
    bool? vibrateOnBlock,
    String? blockMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppBlockingSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isEnabled: isEnabled ?? this.isEnabled,
      blockedApps: blockedApps ?? List<String>.from(this.blockedApps),
      blockingMode: blockingMode ?? this.blockingMode,
      checkIntervalMs: checkIntervalMs ?? this.checkIntervalMs,
      showNotifications: showNotifications ?? this.showNotifications,
      vibrateOnBlock: vibrateOnBlock ?? this.vibrateOnBlock,
      blockMessage: blockMessage ?? this.blockMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'isEnabled': isEnabled,
      'blockedApps': blockedApps,
      'blockingMode': blockingMode,
      'checkIntervalMs': checkIntervalMs,
      'showNotifications': showNotifications,
      'vibrateOnBlock': vibrateOnBlock,
      'blockMessage': blockMessage,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppBlockingSettings.fromFirestore(Map<String, dynamic> data) {
    return AppBlockingSettings(
      id: data['id'] as String,
      userId: data['userId'] as String,
      isEnabled: data['isEnabled'] as bool? ?? false,
      blockedApps: List<String>.from(data['blockedApps'] as List? ?? []),
      blockingMode: data['blockingMode'] as String? ?? 'TIMER_ONLY',
      checkIntervalMs: data['checkIntervalMs'] as int? ?? 1000,
      showNotifications: data['showNotifications'] as bool? ?? true,
      vibrateOnBlock: data['vibrateOnBlock'] as bool? ?? true,
      blockMessage: data['blockMessage'] as String? ?? 'This app is blocked during study time. Stay focused! 📚',
      createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt'] as String) : DateTime.now(),
      updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt'] as String) : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'AppBlockingSettings(id: $id, enabled: $isEnabled, blockedApps: ${blockedApps.length}, mode: $blockingMode)';
  }
}