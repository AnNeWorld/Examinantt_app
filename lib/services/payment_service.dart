import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'firestore_service.dart';
import '../utils/app_theme.dart';

import 'payment_platform_stub.dart'
    if (dart.library.io) 'payment_platform_io.dart'
    if (dart.library.html) 'payment_platform_web.dart';

class PaymentService {
  // Live Razorpay Key
  static const String razorpayKey = 'rzp_live_TAGGnZwDvZubIP';

  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  late final PaymentPlatformDelegate _delegate = getPaymentDelegate();

  Function(PaymentSuccessResponse)? onSuccess;
  Function(PaymentFailureResponse)? onFailure;
  Function(ExternalWalletResponse)? onExternalWallet;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    this.onSuccess = onSuccess;
    this.onFailure = onFailure;
    this.onExternalWallet = onExternalWallet;

    _delegate.initialize(
      onSuccess: onSuccess,
      onFailure: onFailure,
      onExternalWallet: onExternalWallet,
    );
  }

  /// 1-Step Direct Payment & Unlock Function
  /// Launches Razorpay directly, records purchase in Firestore upon payment, and unlocks access immediately!
  Future<void> payAndUnlock({
    required BuildContext context,
    required String title,
    required double price,
    required String itemType, // 'Batch', 'Course', 'Test Series', 'Resource'
    String? itemId,
    String? subtitle,
    VoidCallback? onSuccess,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final phone = user?.phoneNumber ?? '8881188678';
    final email = user?.email ?? 'student@examinantt.com';
    final effectiveItemId = (itemId != null && itemId.isNotEmpty)
        ? itemId
        : '${itemType.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Free item
    if (price <= 0) {
      await FirestoreService().addPurchase(
        id: effectiveItemId,
        itemId: effectiveItemId,
        title: title,
        type: itemType,
        price: 0,
      );
      if (context.mounted) {
        AppTheme.showSuccessSnackBar(context, '🎉 $title Unlocked Successfully!');
      }
      onSuccess?.call();
      return;
    }

    // 2. Open Razorpay directly!
    openCheckout(
      amountInRupees: price,
      name: title,
      description: subtitle ?? 'Enrollment in $title on Examinantt',
      contact: phone,
      email: email,
      onSuccess: (res) async {
        try {
          await FirestoreService().addPurchase(
            id: effectiveItemId,
            itemId: effectiveItemId,
            title: title,
            type: itemType,
            price: price,
          );
          await FirestoreService().addNotification(
            title: '$title Unlocked! 🎉',
            subtitle: 'Payment of ₹${price.toStringAsFixed(0)} verified. Full access granted.',
          );
        } catch (e) {
          debugPrint('[PaymentService] Error saving purchase: $e');
        }

        if (context.mounted) {
          AppTheme.showSuccessSnackBar(context, '🎉 Payment Successful! $title Unlocked!');
        }
        onSuccess?.call();
      },
      onFailure: (res) {
        if (context.mounted) {
          final msg = (res.message ?? '').trim();
          if (!msg.toLowerCase().contains('cancel')) {
            AppTheme.showErrorSnackBar(context, msg.isNotEmpty ? msg : 'Payment could not be completed.');
          }
        }
      },
      onExternalWallet: (_) {},
    );
  }

  void openCheckout({
    double? amountInRupees,
    double? amount,
    required String name,
    required String description,
    String? contact,
    String? email,
    String? preferredMethod,
    String? upiAppPackage,
    Function(PaymentSuccessResponse)? onSuccess,
    Function(PaymentFailureResponse)? onFailure,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    if (onSuccess != null) this.onSuccess = onSuccess;
    if (onFailure != null) this.onFailure = onFailure;
    if (onExternalWallet != null) this.onExternalWallet = onExternalWallet;

    final double finalAmount = amountInRupees ?? amount ?? 0.0;

    // 1. If the item is free (₹0), complete immediately without opening payment gateway
    if (finalAmount <= 0.0) {
      debugPrint('[PaymentService] Amount is 0. Unlocking for free.');
      (this.onSuccess ?? onSuccess)?.call(
        PaymentSuccessResponse(
          'free_order_${DateTime.now().millisecondsSinceEpoch}',
          null,
          null,
          null,
        ),
      );
      return;
    }

    final int amountInPaise = (finalAmount * 100).round();
    if (amountInPaise < 100) {
      (this.onFailure ?? onFailure)?.call(
        PaymentFailureResponse(
          Razorpay.INVALID_OPTIONS,
          'Amount must be at least ₹1.00',
          null,
        ),
      );
      return;
    }

    // Resolve contact
    String? resolvedContact = contact?.trim();
    if (resolvedContact == null || resolvedContact.isEmpty) {
      resolvedContact = FirebaseAuth.instance.currentUser?.phoneNumber;
    }
    String cleanContact = '8881188678';
    if (resolvedContact != null && resolvedContact.isNotEmpty) {
      final digits = resolvedContact.replaceAll(RegExp(r'[^0-9+]'), '');
      if (digits.length >= 10) {
        cleanContact = digits;
      }
    }

    // Resolve email
    String? resolvedEmail = email?.trim();
    if (resolvedEmail == null || resolvedEmail.isEmpty) {
      resolvedEmail = FirebaseAuth.instance.currentUser?.email;
    }
    String cleanEmail = 'student@examinantt.com';
    if (resolvedEmail != null && resolvedEmail.isNotEmpty && resolvedEmail.contains('@')) {
      cleanEmail = resolvedEmail;
    }

    _delegate.openCheckout(
      finalAmount: finalAmount,
      amountInPaise: amountInPaise,
      name: name.isNotEmpty ? name : 'Examinantt',
      description: description.isNotEmpty ? description : 'Examinantt Premium Purchase',
      contact: cleanContact,
      email: cleanEmail,
      preferredMethod: preferredMethod,
      upiAppPackage: upiAppPackage,
      onSuccess: (res) => (this.onSuccess ?? onSuccess)?.call(res),
      onFailure: (res) => (this.onFailure ?? onFailure)?.call(res),
      onExternalWallet: (res) => (this.onExternalWallet ?? onExternalWallet)?.call(res),
    );
  }

  void dispose() {
    _delegate.dispose();
  }
}
