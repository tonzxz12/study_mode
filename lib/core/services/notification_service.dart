import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stream controller for in-app notifications
  final StreamController<AppNotification> _notificationController = 
      StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get notificationStream => _notificationController.stream;

  // Show blocking notification in the app
  void showBlockingAlert(String appName) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: "🚫 App Blocked!",
      message: "You opened $appName which is restricted while Study Mode is enabled. Go focus!",
      type: NotificationType.blocking,
      timestamp: DateTime.now(),
    );

    _notificationController.add(notification);
    print('📢 In-app blocking alert sent: "$appName is restricted"');

    // Auto-dismiss after 4 seconds
    Timer(const Duration(seconds: 4), () {
      dismissNotification(notification.id);
    });
  }

  // Show general notification
  void showNotification(String title, String message, {NotificationType type = NotificationType.info}) {
    final notification = AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );

    _notificationController.add(notification);
  }

  // Dismiss notification
  void dismissNotification(String id) {
    final dismissNotification = AppNotification(
      id: id,
      title: "",
      message: "",
      type: NotificationType.dismiss,
      timestamp: DateTime.now(),
    );

    _notificationController.add(dismissNotification);
  }

  void dispose() {
    _notificationController.close();
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

enum NotificationType {
  info,
  success,
  warning,
  error,
  blocking,
  dismiss,
}