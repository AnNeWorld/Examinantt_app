import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/firestore_service.dart';

class MyLearningPurchasesScreen extends StatefulWidget {
  const MyLearningPurchasesScreen({super.key});

  @override
  State<MyLearningPurchasesScreen> createState() => _MyLearningPurchasesScreenState();
}

class _MyLearningPurchasesScreenState extends State<MyLearningPurchasesScreen> {
  List<Map<String, dynamic>> purchases = [];

  void _showMetricDetailsDialog(String category, List<String> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text(category, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.isEmpty
                  ? [Text('No active items found.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13))]
                  : items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFFFFA000), size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13))),
                  ],
                ),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Color(0xFFFFA000))),
            ),
          ],
        );
      },
    );
  }

  void _showInvoiceDialog(Map<String, dynamic> purchase) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = (purchase['status'] ?? 'Active').toString().toLowerCase() == 'active';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
              title: Text('Purchase Invoice', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(purchase['title'] ?? 'Purchased Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Type: ${purchase['type'] ?? 'Course/Package'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Purchase Date:', style: TextStyle(fontSize: 12)),
                      Text(purchase['date'] ?? 'N/A', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount Paid:', style: TextStyle(fontSize: 12)),
                      Text(purchase['price'] ?? '₹0', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFFFA000))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Status:', style: TextStyle(fontSize: 12)),
                      Text(purchase['status'] ?? 'Success', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: (purchase['status'] ?? '') == 'Refunded' ? Colors.redAccent : Colors.green)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading invoice PDF...')),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Download PDF Invoice', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1B2C56) : Colors.grey.shade200,
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      minimumSize: const Size(double.infinity, 36),
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Request Refund?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              content: const Text('Are you sure you want to request a refund for this purchase?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Refund request submitted successfully!')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text('Request Refund', style: TextStyle(color: Colors.white)),
                                )
                              ],
                            );
                          },
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        minimumSize: const Size(double.infinity, 36),
                      ),
                      child: const Text('Cancel & Request Refund', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Color(0xFFFFA000))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCatalogSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                'Explore Programs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.school, color: Color(0xFFFFA000)),
                title: const Text('Complete Preparation Batches'),
                subtitle: const Text('Live Classes & Notes'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService().getUserPurchasesStream(),
        builder: (context, snapshot) {
          final livePurchases = snapshot.data ?? [];
          final activeCourses = livePurchases.where((p) => (p['type'] ?? '').toString().contains('Batch') || (p['type'] ?? '').toString().contains('Course')).toList();
          final activeTests = livePurchases.where((p) => (p['type'] ?? '').toString().contains('Test')).toList();
          final activeResources = livePurchases.where((p) => (p['type'] ?? '').toString().contains('PDF') || (p['type'] ?? '').toString().contains('Resource')).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_mall_outlined, color: Color(0xFFFFA000), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Learning & Purchases',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'All your learning programs, test series and resources in one place.',
                              style: TextStyle(fontSize: 12, color: subColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA000).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFFFFA000), size: 28),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 24),

                // 4 Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
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
                      onTap: () => _showMetricDetailsDialog('Active Courses', activeCourses.map((c) => (c['title'] ?? 'Course').toString()).toList()),
                    ),
                    _buildMetricTile(
                      context,
                      title: 'Test Series',
                      subtitle: 'Available for You',
                      value: '${activeTests.length}',
                      valueLabel: 'Available',
                      color: const Color(0xFF8B5CF6),
                      icon: Icons.assignment_rounded,
                      onTap: () => _showMetricDetailsDialog('Active Test Series', activeTests.map((t) => (t['title'] ?? 'Test Series').toString()).toList()),
                    ),
                    _buildMetricTile(
                      context,
                      title: 'Resources',
                      subtitle: 'Notes, PDFs & More',
                      value: '${activeResources.length}',
                      valueLabel: 'Available',
                      color: const Color(0xFF3B82F6),
                      icon: Icons.menu_book_rounded,
                      onTap: () => _showMetricDetailsDialog('Available Resources', activeResources.map((r) => (r['title'] ?? 'Resource').toString()).toList()),
                    ),
                    _buildMetricTile(
                      context,
                      title: 'Purchase History',
                      subtitle: 'All Orders & Invoices',
                      value: '${livePurchases.length}',
                      valueLabel: 'Orders',
                      color: const Color(0xFF10B981),
                      icon: Icons.shopping_cart_rounded,
                      onTap: () {},
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 28),

                // Recent Purchases
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
                  ],
                ),
                const SizedBox(height: 12),
                livePurchases.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 40, color: subColor),
                            const SizedBox(height: 12),
                            Text('No Purchases Yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(height: 4),
                            Text('Your purchased courses and test series will appear here.', style: TextStyle(fontSize: 12, color: subColor), textAlign: TextAlign.center),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: livePurchases.length,
                        itemBuilder: (context, index) {
                          final purchase = livePurchases[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () => _showInvoiceDialog(purchase),
                              borderRadius: BorderRadius.circular(16),
                              child: _buildRecentPurchaseRow(
                                context,
                                title: purchase['title'] ?? 'Purchase Item',
                                type: purchase['type'] ?? 'Package',
                                status: purchase['status'] ?? 'Active',
                                date: purchase['date'] ?? '',
                                color: const Color(0xFFFFA000),
                                icon: Icons.local_mall_rounded,
                              ),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 28),

                // Bottom Banner Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFA000).withValues(alpha: 0.08),
                        const Color(0xFFFFA000).withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.military_tech_rounded, color: Color(0xFFFFA000), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Get more, achieve more!',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore programs and resources to take your preparation to the next level.',
                              style: TextStyle(fontSize: 11, color: subColor, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _showCatalogSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA000),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Explore Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
              ],
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 9, color: subColor),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
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
                    style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold),
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
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
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: TextStyle(fontSize: 11, color: subColor),
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
                        fontSize: 9,
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
              const SizedBox(height: 6),
              Text(
                date,
                style: TextStyle(fontSize: 10, color: subColor),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: subColor, size: 18),
        ],
      ),
    );
  }
}
