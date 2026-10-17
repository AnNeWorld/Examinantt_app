import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';
import 'courses_screen.dart';
import 'test_series_screen.dart';
import 'resources_screen.dart';
import 'my_purchases_screen.dart';
import '../widgets/notification_bell_action.dart';

class MyLearningPurchasesScreen extends StatefulWidget {
  const MyLearningPurchasesScreen({super.key});

  @override
  State<MyLearningPurchasesScreen> createState() => _MyLearningPurchasesScreenState();
}

class _MyLearningPurchasesScreenState extends State<MyLearningPurchasesScreen> {
  void _openInvoicePage(Map<String, dynamic> purchase) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseInvoiceScreen(purchase: purchase),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Learning & Purchases',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
        actions: const [
          NotificationBellAction(),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getUserPurchasesStream(),
        builder: (context, snapshot) {
          final livePurchases = snapshot.data ?? [];
          final activeCourses = livePurchases.where((p) =>
              (p['type'] ?? '').toString().toLowerCase().contains('batch') ||
              (p['type'] ?? '').toString().toLowerCase().contains('course')).toList();
          final activeTests = livePurchases.where((p) =>
              (p['type'] ?? '').toString().toLowerCase().contains('test') ||
              (p['type'] ?? '').toString().toLowerCase().contains('series')).toList();
          final activeResources = livePurchases.where((p) =>
              (p['type'] ?? '').toString().toLowerCase().contains('pdf') ||
              (p['type'] ?? '').toString().toLowerCase().contains('resource') ||
              (p['type'] ?? '').toString().toLowerCase().contains('notes')).toList();

          return RefreshIndicator(
            color: const Color(0xFF0070F3),
            backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 650));
              if (mounted) setState(() {});
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4 Interactive Category Buttons -> Navigate directly to dedicated pages
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.35,
                  children: [
                    _buildMetricTile(
                      context,
                      title: 'Courses & Batches',
                      subtitle: 'Active Programs',
                      value: '${activeCourses.length}',
                      valueLabel: 'Active',
                      color: const Color(0xFFFFA000),
                      icon: Icons.school_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CoursesScreen()),
                        );
                      },
                    ),
                    _buildMetricTile(
                      context,
                      title: 'Test Series',
                      subtitle: 'Available for You',
                      value: '${activeTests.length}',
                      valueLabel: 'Available',
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.assignment_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TestSeriesScreen()),
                        );
                      },
                    ),
                    _buildMetricTile(
                      context,
                      title: 'Resources',
                      subtitle: 'Notes, PDFs & More',
                      value: '${activeResources.length}',
                      valueLabel: 'Available',
                      color: const Color(0xFF3B82F6),
                      icon: Icons.menu_book_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ResourcesScreen()),
                        );
                      },
                    ),
                    _buildMetricTile(
                      context,
                      title: 'Purchase History',
                      subtitle: 'All Orders & Invoices',
                      value: '${livePurchases.length}',
                      valueLabel: 'Orders',
                      color: const Color(0xFF10B981),
                      icon: Icons.shopping_cart_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyPurchasesScreen()),
                        );
                      },
                    ),
                  ],
                ).animate().fadeIn(duration: 350.ms),
                const SizedBox(height: 24),

                // Recent Purchases Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_rounded, color: subColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Recent Purchases',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ],
                    ),
                    if (livePurchases.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyPurchasesScreen()),
                          );
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFFFFA000),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                livePurchases.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(28),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 44, color: subColor),
                            const SizedBox(height: 12),
                            Text('No Purchases Yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(height: 4),
                            Text(
                              'Your purchased courses and test series will appear here.',
                              style: TextStyle(fontSize: 12, color: subColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: livePurchases.length,
                        itemBuilder: (context, index) {
                          final purchase = livePurchases[index];
                          final type = (purchase['type'] ?? 'Package').toString();
                          final isLive = type.toLowerCase().contains('live');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () => _openInvoicePage(purchase),
                              borderRadius: BorderRadius.circular(16),
                              child: _buildRecentPurchaseRow(
                                context,
                                title: purchase['title'] ?? 'Purchase Item',
                                type: type,
                                status: purchase['status'] ?? 'Active',
                                date: purchase['date'] ?? '',
                                color: isLive ? const Color(0xFFEF4444) : const Color(0xFFFFA000),
                                icon: isLive ? Icons.videocam_rounded : Icons.local_mall_rounded,
                              ),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
                const SizedBox(height: 24),
              ],
            ),
          ),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required String valueLabel,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.04 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded, color: color, size: 14),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: subColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    valueLabel,
                    style: TextStyle(fontSize: 11.5, color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPurchaseRow(
    BuildContext context, {
    required String title,
    required String type,
    required String status,
    required String date,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    final bool isActive = status.toLowerCase() == 'active';
    final bool isRefunded = status.toLowerCase() == 'refunded';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1A3D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: TextStyle(fontSize: 11.5, color: subColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isRefunded
                      ? Colors.redAccent.withValues(alpha: 0.1)
                      : (isActive
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : const Color(0xFF3B82F6).withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isRefunded
                            ? Colors.redAccent
                            : (isActive ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isRefunded
                            ? Colors.redAccent
                            : (isActive ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              if (date.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: subColor),
                ),
              ],
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: subColor, size: 18),
        ],
      ),
    );
  }
}

/// Dedicated Full Screen for Order / Invoice Details (Replaces previous popup dialog)
class PurchaseInvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> purchase;

  const PurchaseInvoiceScreen({super.key, required this.purchase});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0A122C) : Colors.grey.shade50;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;

    final String title = purchase['title'] ?? 'Purchased Item';
    final String type = purchase['type'] ?? 'Course / Package';
    final String date = purchase['date'] ?? 'N/A';
    final String price = (purchase['price'] ?? '₹0').toString();
    final String status = purchase['status'] ?? 'Active';
    final bool isActive = status.toLowerCase() == 'active';
    final bool isRefunded = status.toLowerCase() == 'refunded';
    final String orderId = (purchase['id'] ?? 'ORD_${DateTime.now().millisecondsSinceEpoch}').toString();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Invoice & Order Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status & Order Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isRefunded
                          ? Colors.redAccent.withValues(alpha: 0.12)
                          : const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRefunded ? Icons.assignment_return_rounded : Icons.check_circle_rounded,
                      color: isRefunded ? Colors.redAccent : const Color(0xFF10B981),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    price.startsWith('₹') ? price : '₹$price',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFFFA000),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRefunded ? 'Refunded' : 'Payment Successful',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isRefunded ? Colors.redAccent : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(fontSize: 12.5, color: subColor),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Order Breakdown Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Information',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  _buildInvoiceRow('Order ID', orderId, textColor, subColor),
                  Divider(color: borderColor, height: 24),
                  _buildInvoiceRow('Purchase Date', date, textColor, subColor),
                  Divider(color: borderColor, height: 24),
                  _buildInvoiceRow('Payment Method', 'Online (Razorpay / UPI)', textColor, subColor),
                  Divider(color: borderColor, height: 24),
                  _buildInvoiceRow('Access Validity', 'Full Target Exam Validity', textColor, subColor),
                  Divider(color: borderColor, height: 24),
                  _buildInvoiceRow(
                    'Status',
                    status,
                    isRefunded ? Colors.redAccent : const Color(0xFF10B981),
                    subColor,
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action: Download PDF Invoice
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  AppTheme.showSuccessSnackBar(context, 'Invoice PDF downloaded successfully!');
                },
                icon: const Icon(Icons.download_rounded, size: 20),
                label: const Text('Download PDF Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA000),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action: Access Learning Material
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  final t = type.toLowerCase();
                  if (t.contains('test')) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TestSeriesScreen()));
                  } else if (t.contains('pdf') || t.contains('resource')) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourcesScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen()));
                  }
                },
                icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                label: const Text('Start Learning Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                  side: BorderSide(color: isDark ? AppColors.accent : AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            if (isActive) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: cardBg,
                        title: const Text('Request Refund?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        content: const Text('Are you sure you want to request a refund for this purchase? Our support team will review it within 24-48 hours.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              AppTheme.showSuccessSnackBar(context, 'Refund request submitted successfully! Ticket #REF-${DateTime.now().millisecondsSinceEpoch % 10000}');
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            child: const Text('Submit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline_rounded, size: 16, color: Colors.redAccent),
                  label: const Text('Need Help or Request Refund?', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, Color textColor, Color subColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: subColor)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
