import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isAnnual = true;
  late PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final title = isAnnual ? 'Annual Pro Plan' : 'Monthly Pro Plan';
    final price = isAnnual ? 999.0 : 199.0;
    try {
      await FirestoreService().addPurchase(
        id: 'sub_${isAnnual ? "annual" : "monthly"}_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        type: 'Subscription',
        price: price,
      );
      await FirestoreService().addNotification(
        title: 'Subscription Activated 👑',
        subtitle: 'Successfully subscribed to $title via Razorpay!',
      );
    } catch (e) {
      debugPrint('[SubscriptionScreen] Error recording purchase: $e');
    }
    if (!mounted) return;
    AppTheme.showSuccessSnackBar(context, 'Payment Successful: $title Activated!');
    Navigator.pop(context);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    FirestoreService().addNotification(
      title: 'Subscription Cancelled/Failed ❌',
      subtitle: 'Attempt to subscribe was cancelled or failed.',
    );
    AppTheme.showErrorSnackBar(
      context,
      'Payment Failed: ${response.message ?? "User cancelled or transaction failed"}',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    AppTheme.showSuccessSnackBar(
      context,
      'External Wallet: ${response.walletName ?? ""}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0A1E3F) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subColor = isDark ? const Color(0xFF8E9CB2) : Colors.grey.shade700;
    const goldColor = Color(0xFFFFA000);
    final appBarBg = isDark ? const Color(0xFF00122C) : Colors.white;

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
        appBar: AppBar(
          backgroundColor: appBarBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Premium Plans',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Header Icon & Title
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: goldColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: goldColor.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: goldColor.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 40, color: goldColor),
              ).animate().scale(duration: 400.ms),
              const SizedBox(height: 16),
              Text(
                'Unlock Your Potential',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 8),
              Text(
                'Get unlimited access to all mock tests, video classes, and premium study materials.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: subColor,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 28),

              // Billing Toggle (Monthly / Annual)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    _buildToggleButton('Monthly', !isAnnual),
                    _buildToggleButton('Annually (Save 40%)', isAnnual),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),

              // Gold Pass Card
              _buildPlanCard(
                title: 'Gold Pass',
                price: isAnnual ? '₹2,999' : '₹399',
                duration: isAnnual ? '/year' : '/month',
                isPopular: true,
                badgeColor: goldColor,
                features: [
                  'All SSC & Banking Mock Tests',
                  'Live & Recorded Video Classes',
                  'Downloadable PDF Notes',
                  'Priority Doubt Solving',
                  'Ad-free Experience',
                  'AIR Ranking Analytics',
                ],
              ).animate().fadeIn(delay: 250.ms).scale(begin: const Offset(0.95, 0.95)),

              const SizedBox(height: 20),

              // Silver Pass Card
              _buildPlanCard(
                title: 'Silver Pass',
                price: isAnnual ? '₹1,499' : '₹199',
                duration: isAnnual ? '/year' : '/month',
                isPopular: false,
                badgeColor: const Color(0xFF00C6FF),
                features: [
                  'Only SSC Mock Tests',
                  'Limited Video Classes',
                  'Downloadable PDF Notes',
                  'Standard Support',
                ],
              ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    const goldColor = Color(0xFFFFA000);
    const subColor = Color(0xFF8E9CB2);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isAnnual = text.contains('Annually');
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? goldColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: goldColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFF00122C) : subColor,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String duration,
    required bool isPopular,
    required Color badgeColor,
    required List<String> features,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0A1E3F) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subColor = isDark ? const Color(0xFF8E9CB2) : Colors.grey.shade700;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPopular ? badgeColor.withValues(alpha: 0.6) : (isDark ? Colors.white10 : Colors.grey.shade300),
          width: isPopular ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPopular ? badgeColor.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: badgeColor, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'MOST POPULAR',
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          if (isPopular) const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isPopular ? badgeColor : textColor),
              ),
              const SizedBox(width: 4),
              Text(
                duration,
                style: TextStyle(fontSize: 13, color: subColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: badgeColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final double amount = double.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));
                PaymentService().payAndUnlock(
                  context: context,
                  title: 'Subscription - $title',
                  price: amount,
                  itemType: 'Subscription',
                  subtitle: 'Examinantt $title Plan with all premium features unlocked',
                  onSuccess: () {
                    if (mounted) setState(() {});
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? badgeColor : const Color(0xFF1E293B),
                foregroundColor: isPopular ? const Color(0xFF00122C) : Colors.white,
                elevation: isPopular ? 4 : 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Choose $title',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: isPopular ? const Color(0xFF00122C) : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
