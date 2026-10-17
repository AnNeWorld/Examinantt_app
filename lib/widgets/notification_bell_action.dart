import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../screens/notifications_screen.dart';

/// Unified, real-time notification bell action widget for all AppBars and headers.
/// Automatically listens to Firestore notifications stream, displays the dynamic
/// count badge, and opens the dedicated NotificationsScreen on tap.
class NotificationBellAction extends StatelessWidget {
  final Color? color;
  final double size;
  final EdgeInsetsGeometry padding;

  const NotificationBellAction({
    super.key,
    this.color,
    this.size = 22,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : Colors.black87;
    final iconColor = color ?? defaultColor;

    return StreamBuilder<List<NotificationModel>>(
      stream: FirestoreService().getNotificationsStream(),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        final count = notifications.length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              padding: padding,
              icon: Icon(
                count > 0 ? Icons.notifications_active_outlined : Icons.notifications_none_rounded,
                color: iconColor,
                size: size,
              ),
              tooltip: 'Notifications',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
