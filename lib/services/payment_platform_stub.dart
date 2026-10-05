import 'package:razorpay_flutter/razorpay_flutter.dart';

abstract class PaymentPlatformDelegate {
  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  });

  void openCheckout({
    required double finalAmount,
    required int amountInPaise,
    required String name,
    required String description,
    required String contact,
    required String email,
    String? preferredMethod,
    String? upiAppPackage,
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  });

  void dispose();
}

PaymentPlatformDelegate getPaymentDelegate() => throw UnsupportedError('No payment delegate available');
