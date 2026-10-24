import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../providers/user_provider.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';

class CheckoutScreen extends StatefulWidget {
  final String title;
  final double price;
  final double? originalPrice;
  final String? itemId;
  final String? subtitle;
  final String? itemType; // 'Batch', 'Course', 'Test Series', 'Subscription', 'Resource', 'Live Class'
  final List<String>? features;
  final String? bannerImageUrl;
  final VoidCallback? onPaymentSuccess;

  const CheckoutScreen({
    super.key,
    required this.title,
    required this.price,
    this.itemId,
    this.originalPrice,
    this.subtitle,
    this.itemType = 'Batch',
    this.features,
    this.bannerImageUrl,
    this.onPaymentSuccess,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _transactionId;
  String? _errorMessage;
  String _selectedPaymentMethod = 'gpay';

  String _getPaymentMethodTitle() {
    switch (_selectedPaymentMethod) {
      case 'gpay':
        return 'Google Pay';
      case 'phonepe':
        return 'PhonePe';
      case 'paytm':
        return 'Paytm';
      case 'upi':
        return 'UPI / QR';
      case 'card':
        return 'Card';
      case 'netbanking':
        return 'Net Banking';
      default:
        return 'UPI';
    }
  }

  void _payNow({String? preferredMethod}) {
    final method = preferredMethod ?? _selectedPaymentMethod;
    final gatewayMethod = (method == 'gpay' || method == 'phonepe' || method == 'paytm') ? 'upi' : method;
    _startPayment(preferredMethod: gatewayMethod);
  }

  @override
  void initState() {
    super.initState();
    _initPaymentDelegate();
  }

  void _initPaymentDelegate() {
    _paymentService.initialize(
      onSuccess: (res) {
        _handleSuccessfulPayment(res.paymentId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}');
      },
      onFailure: (res) {
        if (!mounted) return;
        final cleanMsg = PaymentService.cleanErrorMessage(res);
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _errorMessage = cleanMsg;
        });
        AppTheme.showErrorSnackBar(context, cleanMsg);
      },
      onExternalWallet: (res) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _handleSuccessfulPayment(String txnId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isSuccess = true;
      _transactionId = txnId;
    });

    try {
      final purchaseId = widget.itemId != null && widget.itemId!.isNotEmpty
          ? widget.itemId!
          : '${widget.itemType?.toLowerCase() ?? "item"}_${DateTime.now().millisecondsSinceEpoch}';

      final user = Provider.of<UserProvider>(context, listen: false).user;
      final userId = user?.uid ?? FirebaseAuth.instance.currentUser?.uid;

      await FirestoreService().addPurchase(
        id: purchaseId,
        itemId: purchaseId,
        title: widget.title,
        type: widget.itemType ?? 'Batch',
        price: widget.price,
        explicitUid: userId,
      );
    } catch (e) {
      debugPrint("Error recording purchase: $e");
    }

    widget.onPaymentSuccess?.call();
  }

  void _startPayment({String? preferredMethod}) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = Provider.of<UserProvider>(context, listen: false).user;
    final userEmail = (user?.email.isNotEmpty == true)
        ? user!.email
        : (FirebaseAuth.instance.currentUser?.email ?? 'student@examinantt.com');
    final userPhone = (user?.phone.isNotEmpty == true)
        ? user!.phone
        : (FirebaseAuth.instance.currentUser?.phoneNumber ?? '9999999999');

    _paymentService.openCheckout(
      amountInRupees: widget.price,
      name: widget.title,
      description: 'Exam preparation access for ${widget.title}',
      email: userEmail,
      contact: userPhone,
      preferredMethod: preferredMethod,
      onFailure: (res) {
        if (!mounted) return;
        final cleanMsg = PaymentService.cleanErrorMessage(res);
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _errorMessage = cleanMsg;
        });
        AppTheme.showErrorSnackBar(context, cleanMsg);
      },
    );

    // Auto-reset loading state if checkout doesn't pop up after 15s
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isLoading && !_isSuccess) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOriginalPrice = widget.originalPrice ?? (widget.price * 1.5).roundToDouble();
    final discount = (effectiveOriginalPrice - widget.price).clamp(0.0, double.infinity);
    final scaffoldBg = isDark ? const Color(0xFF070E1A) : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? const Color(0xFF070E1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54;
    final iconBg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: textColor),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secure Checkout',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Text(
                  '256-Bit SSL Encrypted Razorpay',
                  style: TextStyle(
                    color: subColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  'VERIFIED',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isSuccess ? _buildSuccessView(isDark) : _buildCheckoutContent(effectiveOriginalPrice, discount, isDark),
      bottomNavigationBar: _isSuccess ? null : _buildBottomStickyBar(isDark),
    );
  }

  Widget _buildCheckoutContent(double effectiveOriginalPrice, double discount, bool isDark) {
    final user = Provider.of<UserProvider>(context).user;
    final userName = user?.name.isNotEmpty == true
        ? user!.name
        : (FirebaseAuth.instance.currentUser?.displayName ?? 'Student');
    final userEmail = user?.email.isNotEmpty == true
        ? user!.email
        : (FirebaseAuth.instance.currentUser?.email ?? 'student@examinantt.com');
    final userPhone = user?.phone.isNotEmpty == true
        ? user!.phone
        : (FirebaseAuth.instance.currentUser?.phoneNumber ?? 'Not provided');

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black54;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 1. Order Summary Card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0070F3), Color(0xFF00C6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0070F3).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7A00).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFF7A00).withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              (widget.itemType ?? 'BATCH').toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFFF7A00),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle ?? 'Full syllabus comprehensive batch with live classes, study notes, mock tests & mentor access',
                            style: TextStyle(
                              color: subColor,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0B1B36) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF0284C7), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Full 1-Year Academic Validity (Till Exam)',
                        style: TextStyle(
                          color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF0369A1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Deliverables / Features Included
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFFB800), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "What's Included in this Plan",
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...((widget.features != null && widget.features!.isNotEmpty)
                    ? widget.features!.map((f) => _buildFeatureItem(f, isDark))
                    : [
                        _buildFeatureItem('🎥 Daily Unlimited Interactive Live Classes & High-Definition Recordings', isDark),
                        _buildFeatureItem('📑 Chapterwise Color Formula Sheets & High-Yield DPP Notes', isDark),
                        _buildFeatureItem('🎯 All India Rank Test Series with AI Performance Analysis', isDark),
                        _buildFeatureItem('💬 24×7 Instant Faculty Doubt Resolution & Community Chat', isDark),
                        _buildFeatureItem('🏆 Free Previous 10 Years Solved Question Papers (PYQs)', isDark),
                      ]),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Student Account Details
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, color: Color(0xFF0070F3), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Student Information',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Logged In',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Name', userName, isDark),
                Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 16),
                _buildInfoRow('Email', userEmail, isDark),
                Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 16),
                _buildInfoRow('Phone', userPhone, isDark),
                const SizedBox(height: 10),
                Text(
                  'ℹ️ Course access & official invoice will be instantly unlocked for this account.',
                  style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black45, fontSize: 12.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Price Breakdown
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Price Breakdown',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPriceRow(
                  'Original Batch MRP',
                  '₹${effectiveOriginalPrice.toStringAsFixed(0)}',
                  isDark: isDark,
                  isCrossed: true,
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Early Bird Scholarship Discount',
                    '-₹${discount.toStringAsFixed(0)}',
                    isDark: isDark,
                    color: const Color(0xFF10B981),
                  ),
                ],
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Platform & Live Streaming Fee',
                  'FREE (₹0)',
                  isDark: isDark,
                  color: const Color(0xFF0284C7),
                ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  'GST & Education Cess (18%)',
                  'Included (Absorbed)',
                  isDark: isDark,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Payable Amount',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'All inclusive price',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹${widget.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Coupon EXAMSPECIAL automatically applied',
                        style: TextStyle(
                          color: const Color(0xFF10B981).withValues(alpha: 0.95),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. Payment Methods Selection Card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payment_rounded, color: Color(0xFF0070F3), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your preferred method or pay directly via Razorpay:',
                  style: TextStyle(color: subColor, fontSize: 13),
                ),
                const SizedBox(height: 14),
                _buildPaymentOptionItem(
                  id: 'gpay',
                  title: 'Google Pay (GPay)',
                  subtitle: 'Direct 1-Tap UPI Payment',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF4285F4),
                  badge: 'POPULAR',
                  isDark: isDark,
                ),
                _buildPaymentOptionItem(
                  id: 'phonepe',
                  title: 'PhonePe',
                  subtitle: 'Instant UPI Direct Checkout',
                  icon: Icons.flash_on_rounded,
                  iconColor: const Color(0xFF5F259F),
                  badge: 'FAST',
                  isDark: isDark,
                ),
                _buildPaymentOptionItem(
                  id: 'paytm',
                  title: 'Paytm UPI',
                  subtitle: 'Pay via Paytm App or Wallet',
                  icon: Icons.payments_rounded,
                  iconColor: const Color(0xFF00B9F1),
                  isDark: isDark,
                ),
                _buildPaymentOptionItem(
                  id: 'upi',
                  title: 'Scan QR / Any Other UPI App',
                  subtitle: 'BHIM, Amazon Pay, Cred, Navi & all UPI apps',
                  icon: Icons.qr_code_scanner_rounded,
                  iconColor: const Color(0xFF10B981),
                  isDark: isDark,
                ),
                _buildPaymentOptionItem(
                  id: 'card',
                  title: 'Debit / Credit Cards',
                  subtitle: 'Visa, MasterCard, RuPay & all major banks',
                  icon: Icons.credit_card_rounded,
                  iconColor: const Color(0xFF0284C7),
                  isDark: isDark,
                ),
                _buildPaymentOptionItem(
                  id: 'netbanking',
                  title: 'Net Banking',
                  subtitle: 'SBI, HDFC, ICICI, Axis & 50+ banks supported',
                  icon: Icons.account_balance_rounded,
                  iconColor: const Color(0xFFA855F7),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '100% Safe 256-Bit SSL Encrypted Razorpay Gateway',
                        style: TextStyle(color: subColor, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionItem({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    String? badge,
  }) {
    final isSelected = _selectedPaymentMethod == id;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black54;

    Color itemBg;
    if (isSelected) {
      itemBg = isDark ? const Color(0xFF0070F3).withValues(alpha: 0.15) : const Color(0xFFEFF6FF);
    } else {
      itemBg = isDark ? const Color(0xFF0A1629) : Colors.grey.shade50;
    }

    Color itemBorder;
    if (isSelected) {
      itemBorder = const Color(0xFF0070F3);
    } else {
      itemBorder = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200;
    }

    return InkWell(
      onTap: () {
        if (_selectedPaymentMethod == id) {
          _payNow();
        } else {
          setState(() {
            _selectedPaymentMethod = id;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: itemBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: itemBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subColor,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0070F3), Color(0xFF0056BD)]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0070F3).withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pay ➔',
                      style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              )
            else
              Icon(
                Icons.radio_button_off_rounded,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E2E4A) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFeatureItem(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF334155),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black54, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {required bool isDark, bool isCrossed = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black87, fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            decoration: isCrossed ? TextDecoration.lineThrough : null,
            decorationColor: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStickyBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1629) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Payable',
                      style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.black54, fontSize: 12.5),
                    ),
                    Text(
                      '₹${widget.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _payNow(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0070F3),
                        disabledBackgroundColor: const Color(0xFF0070F3).withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Pay ₹${widget.price.toStringAsFixed(0)} via ${_getPaymentMethodTitle()} & Unlock',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView(bool isDark) {
    final now = DateTime.now();
    final dateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(now);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white.withValues(alpha: 0.75) : Colors.black54;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF10B981), width: 2),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Enrollment Successful! 🎉',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Congratulations! You have successfully unlocked ${widget.title}.',
              style: TextStyle(
                color: subColor,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildCard(
              isDark: isDark,
              child: Column(
                children: [
                  _buildInfoRow('Item', widget.title, isDark),
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 16),
                  _buildInfoRow('Amount Paid', '₹${widget.price.toStringAsFixed(0)}', isDark),
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 16),
                  _buildInfoRow('Transaction ID', _transactionId ?? 'Verified', isDark),
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 16),
                  _buildInfoRow('Date & Time', dateFormatted, isDark),
                  Divider(color: isDark ? Colors.white10 : Colors.grey.shade200, height: 16),
                  _buildInfoRow('Status', 'Active & Unlocked', isDark),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Start Learning Now 🚀',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
