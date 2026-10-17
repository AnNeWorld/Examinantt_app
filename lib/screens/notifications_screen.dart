import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/notification_model.dart';
import 'courses_screen.dart';
import 'test_series_screen.dart';
import 'resources_screen.dart';
import 'doubts_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF071228) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF0D1D3A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF071228) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: FirestoreService().getNotificationsStream(),
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              if (list.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => _confirmClearAll(context, list),
                icon: const Icon(Icons.clear_all_rounded, size: 18, color: Colors.redAccent),
                label: const Text(
                  'Clear All',
                  style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: FirestoreService().getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(color: subtitleColor, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return RefreshIndicator(
              color: const Color(0xFFFFA000),
              backgroundColor: cardBg,
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 650));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0E1E3D) : const Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 52,
                              color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'All Caught Up!',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You do not have any new notifications or announcements right now.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFFFFA000),
            backgroundColor: cardBg,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 650));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
              final notif = notifications[index];
              final categoryInfo = _getCategoryInfo(notif);

              return Dismissible(
                key: Key(notif.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 28),
                ),
                onDismissed: (direction) async {
                  await FirestoreService().deleteNotification(notif.id);
                  if (!context.mounted) return;
                  AppTheme.showSuccessSnackBar(context, 'Notification removed');
                },
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationDetailScreen(notification: notif),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: categoryInfo.color.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              categoryInfo.icon,
                              color: categoryInfo.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: categoryInfo.color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        categoryInfo.badgeText,
                                        style: TextStyle(
                                          color: categoryInfo.color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(notif.date),
                                      style: TextStyle(color: subtitleColor, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif.subtitle,
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 12.5,
                                    height: 1.35,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fade(delay: (35 * index).ms).slideY(begin: 0.05, end: 0);
            },
          );
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context, List<NotificationModel> list) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0C1D3B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Notifications?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'This will permanently delete ${list.length} notifications from your history.',
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final n in list) {
                await FirestoreService().deleteNotification(n.id);
              }
              if (context.mounted) {
                AppTheme.showSuccessSnackBar(context, 'All notifications cleared');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      if (difference.inMinutes <= 1) return 'Just now';
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('dd MMM').format(date);
    }
  }

  static _NotificationCategory _getCategoryInfo(NotificationModel notif) {
    final title = notif.title.toLowerCase();
    final sub = notif.subtitle.toLowerCase();

    if (title.contains('test') || sub.contains('test') || title.contains('quiz') || sub.contains('quiz')) {
      return _NotificationCategory(
        icon: Icons.assignment_turned_in_rounded,
        color: const Color(0xFFF59E0B),
        badgeText: 'TEST SERIES',
        actionLabel: 'Go to Test Series',
        destination: _DestinationType.testSeries,
      );
    } else if (title.contains('batch') || sub.contains('batch') || title.contains('course') || sub.contains('course') || title.contains('unlocked')) {
      return _NotificationCategory(
        icon: Icons.school_rounded,
        color: const Color(0xFF10B981),
        badgeText: 'BATCH / COURSE',
        actionLabel: 'Explore Courses & Batches',
        destination: _DestinationType.courses,
      );
    } else if (title.contains('doubt') || sub.contains('doubt') || title.contains('answer')) {
      return _NotificationCategory(
        icon: Icons.help_outline_rounded,
        color: const Color(0xFF8B5CF6),
        badgeText: 'DOUBT FORUM',
        actionLabel: 'Open Doubt Forum',
        destination: _DestinationType.doubts,
      );
    } else if (title.contains('resource') || sub.contains('resource') || title.contains('note') || sub.contains('pdf')) {
      return _NotificationCategory(
        icon: Icons.library_books_rounded,
        color: const Color(0xFF06B6D4),
        badgeText: 'STUDY MATERIAL',
        actionLabel: 'View Study Resources',
        destination: _DestinationType.resources,
      );
    } else {
      return _NotificationCategory(
        icon: Icons.campaign_rounded,
        color: const Color(0xFF38BDF8),
        badgeText: 'ANNOUNCEMENT',
        actionLabel: 'Return to Notifications',
        destination: _DestinationType.none,
      );
    }
  }
}

enum _DestinationType { none, testSeries, courses, doubts, resources }

class _NotificationCategory {
  final IconData icon;
  final Color color;
  final String badgeText;
  final String actionLabel;
  final _DestinationType destination;

  _NotificationCategory({
    required this.icon,
    required this.color,
    required this.badgeText,
    required this.actionLabel,
    required this.destination,
  });
}

/// ============================================================================
/// DEDICATED FULL SCREEN: NOTIFICATION DETAIL PAGE
/// ============================================================================
class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF071228) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF0D1D3A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;

    final category = NotificationsScreen._getCategoryInfo(notification);
    final formattedFullDate = DateFormat('EEEE, dd MMMM yyyy • hh:mm a').format(notification.date);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Notification Details',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF071228) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete Notification',
            onPressed: () async {
              await FirestoreService().deleteNotification(notification.id);
              if (!context.mounted) return;
              AppTheme.showSuccessSnackBar(context, 'Notification deleted');
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Category Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    category.color.withValues(alpha: isDark ? 0.2 : 0.12),
                    category.color.withValues(alpha: isDark ? 0.05 : 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: category.color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: category.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            category.badgeText,
                            style: TextStyle(
                              color: category.color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formattedFullDate,
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: -0.05, end: 0),

            const SizedBox(height: 20),

            // Main Notification Content Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 14),
                  Text(
                    notification.subtitle.isNotEmpty
                        ? notification.subtitle
                        : 'No additional details provided with this notification.',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 50.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 28),

            // Relevant Action Button
            if (category.destination != _DestinationType.none) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    switch (category.destination) {
                      case _DestinationType.testSeries:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TestSeriesScreen()),
                        );
                        break;
                      case _DestinationType.courses:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CoursesScreen()),
                        );
                        break;
                      case _DestinationType.doubts:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DoubtsScreen()),
                        );
                        break;
                      case _DestinationType.resources:
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ResourcesScreen()),
                        );
                        break;
                      default:
                        Navigator.pop(context);
                    }
                  },
                  icon: Icon(category.icon, size: 18),
                  label: Text(
                    category.actionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: category.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Back / Dismiss Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

