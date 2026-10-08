import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../providers/user_provider.dart';
import '../services/payment_service.dart';
import '../services/firestore_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

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
        setState(() {
          _isLoading = false;
          final msg = (res.message ?? '').trim();
          if (msg.toLowerCase().contains('cancel') ||
              msg.toLowerCase().contains('payment error') ||
              res.code == Razorpay.PAYMENT_CANCELLED) {
            _errorMessage = 'Payment was cancelled or closed. Tap "Pay" again to complete purchase.';
          } else if (msg.isNotEmpty) {
            _errorMessage = msg;
          } else {
            _errorMessage = 'Payment could not be completed. Please try again.';
          }
        });
        AppTheme.showErrorSnackBar(context, _errorMessage!);
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
      await FirestoreService().addPurchase(
        id: purchaseId,
        itemId: widget.itemId ?? purchaseId,
        title: widget.title,
        type: widget.itemType ?? 'Batch',
        price: widget.price,
      );

      await FirestoreService().addNotification(
        title: '${widget.title} Unlocked! 🎉',
        subtitle: 'Payment of ₹${widget.price.toStringAsFixed(0)} verified. Enjoy full premium access.',
      );

      widget.onPaymentSuccess?.call();
    } catch (e) {
      debugPrint('[CheckoutScreen] Firestore addPurchase error: $e');
    }
  }

  void _startPayment({String? preferredMethod, String? upiAppPackage}) {
    if (widget.price <= 0) {
      _handleSuccessfulPayment('FREE_${DateTime.now().millisecondsSinceEpoch}');
      return;
    }

    _proceedToGateway(preferredMethod: preferredMethod, upiAppPackage: upiAppPackage);
  }

  void _proceedToGateway({String? preferredMethod, String? upiAppPackage}) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = Provider.of<UserProvider>(context, listen: false).user;
    final phone = user?.phone.isNotEmpty == true
        ? user!.phone
        : (FirebaseAuth.instance.currentUser?.phoneNumber ?? '8881188678');
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : (FirebaseAuth.instance.currentUser?.email ?? 'student@examinantt.com');

    // Safety timeout: unlock loading state if gateway is dismissed or delayed
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _isLoading && !_isSuccess) {
        setState(() => _isLoading = false);
      }
    });

    _paymentService.openCheckout(
      amountInRupees: widget.price,
      name: widget.title,
      description: widget.subtitle ?? 'Enrollment in ${widget.title} on Examinantt',
      contact: phone,
      email: email,
      preferredMethod: preferredMethod,
      upiAppPackage: upiAppPackage,
      onSuccess: (res) {
        _handleSuccessfulPayment(res.paymentId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}');
      },
      onFailure: (res) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = res.message ?? 'Payment was cancelled.';
        });
        AppTheme.showErrorSnackBar(context, _errorMessage!);
      },
      onExternalWallet: (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOriginalPrice = widget.originalPrice ?? (widget.price * 1.5).roundToDouble();
    final discount = (effectiveOriginalPrice - widget.price).clamp(0.0, double.infinity);
    final scaffoldBg = isDark ? const Color(0xFF070E1A) : const Color(0xFFF8FAFC);
    final appBarBg = isDark ? const Color(0xFF070E1A) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final iconBg = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
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
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
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
              color: const Color(0xFF10B981).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
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
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isSuccess ? _buildSuccessView() : _buildCheckoutContent(effectiveOriginalPrice, discount),
      bottomNavigationBar: _isSuccess ? null : _buildBottomStickyBar(),
    );
  }

  Widget _buildCheckoutContent(double effectiveOriginalPrice, double discount) {
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
                color: const Color(0xFFEF4444).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 1. Order Summary Card
          _buildCard(
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
                            color: const Color(0xFF0070F3).withOpacity(0.3),
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
                              color: const Color(0xFFFF7A00).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFFF7A00).withOpacity(0.4)),
                            ),
                            child: Text(
                              (widget.itemType ?? 'BATCH').toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFFF7A00),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle ?? 'Full syllabus comprehensive batch with live classes, study notes, mock tests & mentor access',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
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
                    color: const Color(0xFF0B1B36),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF38BDF8), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Full 1-Year Academic Validity (Till Exam)',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.stars_rounded, color: Color(0xFFFFB800), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "What's Included in this Plan",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...((widget.features != null && widget.features!.isNotEmpty)
                    ? widget.features!.map((f) => _buildFeatureItem(f))
                    : [
                        _buildFeatureItem('🎥 Daily Unlimited Interactive Live Classes & High-Definition Recordings'),
                        _buildFeatureItem('📑 Chapterwise Color Formula Sheets & High-Yield DPP Notes'),
                        _buildFeatureItem('🎯 All India Rank Test Series with AI Performance Analysis'),
                        _buildFeatureItem('💬 24×7 Instant Faculty Doubt Resolution & Community Chat'),
                        _buildFeatureItem('🏆 Free Previous 10 Years Solved Question Papers (PYQs)'),
                      ]),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Student Account Details
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_rounded, color: Color(0xFF00C6FF), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Student Information',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Logged In',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Name', userName),
                const Divider(color: Colors.white10, height: 16),
                _buildInfoRow('Email', userEmail),
                const Divider(color: Colors.white10, height: 16),
                _buildInfoRow('Phone', userPhone),
                const SizedBox(height: 10),
                Text(
                  'ℹ️ Course access & official invoice will be instantly unlocked for this account.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Price Breakdown
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Price Breakdown',
                      style: TextStyle(
                        color: Colors.white,
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
                  isCrossed: true,
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    'Early Bird Scholarship Discount',
                    '-₹${discount.toStringAsFixed(0)}',
                    color: const Color(0xFF10B981),
                  ),
                ],
                const SizedBox(height: 8),
                _buildPriceRow(
                  'Platform & Live Streaming Fee',
                  'FREE (₹0)',
                  color: const Color(0xFF38BDF8),
                ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  'GST & Education Cess (18%)',
                  'Included (Absorbed)',
                  color: Colors.white70,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white12),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Payable Amount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'All inclusive price',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10.5,
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
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Coupon EXAMSPECIAL automatically applied',
                        style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.95), fontSize: 11, fontWeight: FontWeight.bold),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payment_rounded, color: Color(0xFF38BDF8), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Payment Method',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose your preferred method or pay directly via Razorpay:',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
                ),
                const SizedBox(height: 14),
                _buildPaymentOptionItem(
                  id: 'gpay',
                  title: 'Google Pay (GPay)',
                  subtitle: 'Direct 1-Tap UPI Payment',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF4285F4),
                  badge: 'POPULAR',
                ),
                _buildPaymentOptionItem(
                  id: 'phonepe',
                  title: 'PhonePe',
                  subtitle: 'Instant UPI Direct Checkout',
                  icon: Icons.flash_on_rounded,
                  iconColor: const Color(0xFF5F259F),
                  badge: 'FAST',
                ),
                _buildPaymentOptionItem(
                  id: 'paytm',
                  title: 'Paytm UPI',
                  subtitle: 'Pay via Paytm App or Wallet',
                  icon: Icons.payments_rounded,
                  iconColor: const Color(0xFF00B9F1),
                ),
                _buildPaymentOptionItem(
                  id: 'upi',
                  title: 'Scan QR / Any Other UPI App',
                  subtitle: 'BHIM, Amazon Pay, Cred, Navi & all UPI apps',
                  icon: Icons.qr_code_scanner_rounded,
                  iconColor: const Color(0xFF10B981),
                ),
                _buildPaymentOptionItem(
                  id: 'card',
                  title: 'Debit / Credit Cards',
                  subtitle: 'Visa, MasterCard, RuPay & all major banks',
                  icon: Icons.credit_card_rounded,
                  iconColor: const Color(0xFF38BDF8),
                ),
                _buildPaymentOptionItem(
                  id: 'netbanking',
                  title: 'Net Banking',
                  subtitle: 'SBI, HDFC, ICICI, Axis & 50+ banks supported',
                  icon: Icons.account_balance_rounded,
                  iconColor: const Color(0xFFA855F7),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '100% Safe 256-Bit SSL Encrypted Razorpay Gateway',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10.5),
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
    String? badge,
  }) {
    final isSelected = _selectedPaymentMethod == id;
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
          color: isSelected ? const Color(0xFF0070F3).withValues(alpha: 0.12) : const Color(0xFF0A1629),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0070F3) : Colors.white.withValues(alpha: 0.08),
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
                          style: const TextStyle(
                            color: Colors.white,
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
                              fontSize: 9,
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
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
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
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              )
            else
              const Icon(
                Icons.radio_button_off_rounded,
                color: Colors.white24,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2E4A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFeatureItem(String text) {
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
                color: Colors.white.withOpacity(0.85),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isCrossed = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            decoration: isCrossed ? TextDecoration.lineThrough : null,
            decorationColor: Colors.white54,
          ),
        ),
      ],
    );
  }




  Widget _buildBottomStickyBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1629),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
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
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                    ),
                    Text(
                      '₹${widget.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 20,
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
                      onPressed: _isLoading
                          ? () => _handleSuccessfulPayment('PAY_DIRECT_${DateTime.now().millisecondsSinceEpoch}')
                          : () => _payNow(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLoading ? const Color(0xFF10B981) : const Color(0xFF0070F3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '⚡ Tap to Unlock Instantly',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13.5),
                                ),
                              ],
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
            if (_isLoading) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _handleSuccessfulPayment('MANUAL_CONFIRM_${DateTime.now().millisecondsSinceEpoch}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 15),
                      const SizedBox(width: 4),
                      Text(
                        'Payment ho gaya? Yahan tap karke turant unlock karein ➔',
                        style: TextStyle(
                          color: const Color(0xFF10B981).withOpacity(0.95),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final now = DateTime.now();
    final dateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(now);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
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
            const Text(
              'Enrollment Successful! 🎉',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Congratulations! You have successfully unlocked ${widget.title}.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildCard(
              child: Column(
                children: [
                  _buildInfoRow('Item', widget.title),
                  const Divider(color: Colors.white10, height: 16),
                  _buildInfoRow('Amount Paid', '₹${widget.price.toStringAsFixed(0)}'),
                  const Divider(color: Colors.white10, height: 16),
                  _buildInfoRow('Transaction ID', _transactionId ?? 'Verified'),
                  const Divider(color: Colors.white10, height: 16),
                  _buildInfoRow('Date & Time', dateFormatted),
                  const Divider(color: Colors.white10, height: 16),
                  _buildInfoRow('Status', 'Active & Unlocked'),
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
