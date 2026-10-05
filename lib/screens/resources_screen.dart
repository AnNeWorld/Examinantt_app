// ignore_for_file: unused_element, unused_field
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../widgets/resource_page_sections.dart';
import '../widgets/create_edit_resource_sheet.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _pendingResourceTitle;
  double? _pendingResourcePrice;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final title = _pendingResourceTitle ?? 'Study Resource';
    final price = _pendingResourcePrice ?? 49.0;
    final resId = 'res_${title.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    await FirestoreService().addPurchase(
      id: resId,
      title: title,
      type: 'Resource',
      price: price,
    );

    await FirestoreService().addNotification(
      title: 'Resource Unlocked 📖',
      subtitle: 'Successfully unlocked $title in real-time!',
    );
    if (!mounted) return;
    AppTheme.showSuccessSnackBar(context, 'Payment Successful: $title Unlocked in Real-Time!');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    FirestoreService().addNotification(
      title: 'Payment Cancelled/Failed ❌',
      subtitle: 'Attempt to unlock resource was cancelled or failed.',
    );
    if (!mounted) return;
    AppTheme.showErrorSnackBar(
      context,
      'Payment Failed: ${response.message ?? "User cancelled or transaction failed"}',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    AppTheme.showSuccessSnackBar(context, 'External Wallet: ${response.walletName ?? ""}');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool showAddResource = _activeTabIndex == 0 || _activeTabIndex == 2;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? null : AppTheme.backgroundLight,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF001638), Color(0xFF000F29)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: showAddResource
            ? FloatingActionButton.extended(
                heroTag: 'fab_add_resource',
                onPressed: () => CreateEditResourceSheet.show(context),
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Resource', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              )
            : null,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar matching Home, Batches, Tests & PDF Header
              _buildTopAppBar(),

              // Complete 7 Pages from Resource page.pdf
              Expanded(
                child: ResourcePageSections(
                  onTabChanged: (index) {
                    if (mounted) {
                      setState(() {
                        _activeTabIndex = index;
                      });
                    }
                  },
                  onExamChanged: (exam) {
                    AppTheme.showSuccessSnackBar(context, 'Exam switched to $exam');
                  },
                  onResourceOpened: (title) {
                    AppTheme.showSuccessSnackBar(context, 'Opening $title...');
                  },
                  onUnlockRequested: (title, price) {
                    PaymentService().payAndUnlock(
                      context: context,
                      title: title,
                      price: price,
                      itemType: 'Resource',
                      subtitle: 'Instant lifetime access to $title study material',
                      onSuccess: () {
                        if (mounted) setState(() {});
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Standard Header matching PDF: Shield Badge + EXAMINANTT RESOURCE CENTER + Bell (3) + Search
  Widget _buildTopAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? Colors.transparent : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scaffoldBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Logo Badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA000).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.shield_rounded, color: Color(0xFFFFA000), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EXAMINANTT',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.8),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text(
                  'RESOURCE CENTER',
                  style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Notification with badge 3 matching PDF
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: textColor),
                onPressed: () {
                  AppTheme.showSuccessSnackBar(context, 'You have 3 new study resources available!');
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFA000),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: const Text(
                    '3',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          if (_activeTabIndex == 0 || _activeTabIndex == 2)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981)),
              tooltip: 'Add Resource',
              onPressed: () => CreateEditResourceSheet.show(context),
            ),
          IconButton(
            icon: Icon(Icons.search_rounded, color: textColor),
            onPressed: () {
              AppTheme.showSuccessSnackBar(context, 'Search notes, question papers & formulas...');
            },
          ),
        ],
      ),
    );
  }
}
