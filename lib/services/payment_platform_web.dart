// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, unused_field
import 'dart:convert';
import 'dart:js' as js;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'payment_platform_stub.dart';
export 'payment_platform_stub.dart';

class PaymentPlatformWeb implements PaymentPlatformDelegate {
  static const String razorpayKey = 'rzp_live_TAGGnZwDvZubIP';

  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;

  @override
  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;
  }

  @override
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
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;

    final options = {
      'key': razorpayKey,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': name.isNotEmpty ? name : 'Examinantt',
      'description': description.isNotEmpty ? description : 'Examinantt Premium Purchase',
      'theme': {'color': '#0070F3'},
      'prefill': {
        if (contact.isNotEmpty) 'contact': contact,
        if (email.isNotEmpty) 'email': email,
      },
    };

    final optionsJson = jsonEncode(options);

    try {
      js.context.callMethod('payWithRazorpayWeb', [
        optionsJson,
        (String paymentId) {
          _onSuccess?.call(PaymentSuccessResponse(paymentId, null, null, null));
        },
        (String errorMsg) {
          _onFailure?.call(PaymentFailureResponse(Razorpay.PAYMENT_CANCELLED, errorMsg, null));
        },
      ]);
    } catch (e) {
      _onFailure?.call(PaymentFailureResponse(Razorpay.UNKNOWN_ERROR, e.toString(), null));
    }
  }

  @override
  void dispose() {}
}

PaymentPlatformDelegate getPaymentDelegate() => PaymentPlatformWeb();
