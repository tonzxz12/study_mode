import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationOverlay extends StatefulWidget {
  final Widget child;

  const NotificationOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with TickerProviderStateMixin {
  final List<AppNotification> _activeNotifications = [];
  late StreamSubscription<AppNotification> _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = NotificationService()
        .notificationStream
        .listen(_handleNotification);
  }

  void _handleNotification(AppNotification notification) {
    if (notification.type == NotificationType.dismiss) {
      setState(() {
        _activeNotifications.removeWhere((n) => n.id == notification.id);
      });
    } else {
      setState(() {
        _activeNotifications.add(notification);
      });
    }
  }

  void _dismissNotification(String id) {
    NotificationService().dismissNotification(id);
  }

  @override
  void dispose() {
    _notificationSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          // Notification overlay
          if (_activeNotifications.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 16,
              right: 16,
              child: Column(
                children: _activeNotifications
                    .map((notification) =>
                        _buildNotificationCard(context, notification))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    Color cardColor;
    Color textColor;
    IconData icon;

    switch (notification.type) {
      case NotificationType.blocking:
        cardColor = Colors.red.shade600;
        textColor = Colors.white;
        icon = Icons.block;
        break;
      case NotificationType.error:
        cardColor = Colors.red.shade600;
        textColor = Colors.white;
        icon = Icons.error;
        break;
      case NotificationType.warning:
        cardColor = Colors.orange.shade600;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case NotificationType.success:
        cardColor = Colors.green.shade600;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      default:
        cardColor = Colors.blue.shade600;
        textColor = Colors.white;
        icon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: textColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _dismissNotification(notification.id),
                icon: Icon(
                  Icons.close,
                  color: textColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}