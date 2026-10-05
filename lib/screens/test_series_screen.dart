// ignore_for_file: unused_element, unused_field
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'test_history_screen.dart';
import '../widgets/test_page_sections.dart';

class TestSeriesScreen extends StatefulWidget {
  const TestSeriesScreen({super.key});

  @override
  State<TestSeriesScreen> createState() => _TestSeriesScreenState();
}

class _TestSeriesScreenState extends State<TestSeriesScreen> {
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _paymentService.initialize(
      onSuccess: (PaymentSuccessResponse response) {
        if (!mounted) return;
        AppTheme.showSuccessSnackBar(context, 'Payment Successful! Series Unlocked.');
        setState(() {});
      },
      onFailure: (PaymentFailureResponse response) {
        if (!mounted) return;
        AppTheme.showErrorSnackBar(
          context,
          'Payment Failed: ${response.message ?? "User cancelled or transaction failed"}',
        );
      },
      onExternalWallet: (ExternalWalletResponse response) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar matching Home, Batches & PDF Header
              _buildTopAppBar(),

              // Complete 7 Pages from test page.pdf
              Expanded(
                child: TestPageSections(
                  onOpenHistory: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TestHistoryScreen()),
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

  // Standard Header matching PDF: Hamburger / Shield + EXAMINANTT TEST CENTER + Bell + Search
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
                  'TEST CENTER',
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
                  AppTheme.showSuccessSnackBar(context, 'You have 3 new test notifications!');
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
          IconButton(
            icon: Icon(Icons.search_rounded, color: textColor),
            onPressed: () {
              AppTheme.showSuccessSnackBar(context, 'Search mock tests & question banks...');
            },
          ),
        ],
      ),
    );
  }
}
