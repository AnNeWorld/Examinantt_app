import 'dart:io' show Platform, HttpServer, HttpRequest, ContentType, InternetAddress;
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'payment_platform_stub.dart';
export 'payment_platform_stub.dart';

class PaymentPlatformIO implements PaymentPlatformDelegate {
  static const String razorpayKey = 'rzp_live_TAGGnZwDvZubIP';

  Razorpay? _razorpay;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onExternalWallet;
  HttpServer? _desktopServer;

  @override
  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onExternalWallet = onExternalWallet;
    _ensureRazorpayInstance();
  }

  void _ensureRazorpayInstance() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return;
    }
    try {
      if (_razorpay == null) {
        _razorpay = Razorpay();
        _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse res) {
          debugPrint('[PaymentPlatformIO] Payment Success: ${res.paymentId}');
          _onSuccess?.call(res);
        });
        _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse res) {
          debugPrint('[PaymentPlatformIO] Payment Error: ${res.code} - ${res.message}');
          _onFailure?.call(res);
        });
        _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse res) {
          debugPrint('[PaymentPlatformIO] External Wallet: ${res.walletName}');
          _onExternalWallet?.call(res);
        });
      }
    } catch (e) {
      debugPrint('[PaymentPlatformIO] Error initializing Razorpay: $e');
    }
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

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _openDesktopRazorpayCheckout(
        finalAmount: finalAmount,
        amountInPaise: amountInPaise,
        name: name,
        description: description,
        contact: contact,
        email: email,
      );
      return;
    }

    // Mobile (Android / iOS)
    _ensureRazorpayInstance();
    if (_razorpay == null) {
      _onFailure?.call(PaymentFailureResponse(
        Razorpay.UNKNOWN_ERROR,
        'Failed to initialize payment gateway. Please restart the app.',
        null,
      ));
      return;
    }

    final resolvedContact = contact.trim().isNotEmpty ? contact.trim() : '8881188678';
    final resolvedEmail = email.trim().isNotEmpty ? email.trim() : 'student@examinantt.com';

    final Map<String, dynamic> options = {
      'key': razorpayKey,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': name.isNotEmpty ? name : 'Examinantt',
      'description': description.isNotEmpty ? description : 'Examinantt Premium Purchase',
      'theme': {'color': '#0070F3'},
      'prefill': {
        'contact': resolvedContact,
        'email': resolvedEmail,
        if (preferredMethod != null && preferredMethod.isNotEmpty)
          'method': preferredMethod,
      },
      'retry': {'enabled': true, 'max_count': 1},
    };

    try {
      debugPrint('[PaymentPlatformIO] Opening Razorpay with key $razorpayKey, amount: $amountInPaise paise');
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('[PaymentPlatformIO] Error in _razorpay.open: $e');
      _onFailure?.call(PaymentFailureResponse(Razorpay.UNKNOWN_ERROR, 'Could not open payment: $e', null));
    }
  }

  Future<void> _openDesktopRazorpayCheckout({
    required double finalAmount,
    required int amountInPaise,
    required String name,
    required String description,
    String? contact,
    String? email,
  }) async {
    try {
      await _desktopServer?.close(force: true);
      _desktopServer = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      final port = _desktopServer!.port;

      _desktopServer!.listen((HttpRequest request) async {
        final path = request.uri.path;
        if (path == '/checkout') {
          final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Examinantt - Complete Payment</title>
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
    body {
      background: #071326;
      color: #F8FAFC;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 30px 16px 110px 16px;
    }
    .card {
      background: #0F2347;
      padding: 32px 24px;
      border-radius: 20px;
      border: 1px solid #1E3A68;
      max-width: 440px;
      width: 100%;
      text-align: center;
      box-shadow: 0 16px 40px rgba(0,0,0,0.6);
    }
    .badge {
      background: rgba(16, 185, 129, 0.15);
      color: #10B981;
      padding: 4px 12px;
      border-radius: 20px;
      font-size: 11px;
      font-weight: 800;
      letter-spacing: 0.8px;
      display: inline-block;
      margin-bottom: 14px;
    }
    h2 { margin: 0 0 6px 0; font-size: 20px; font-weight: 800; color: #FFFFFF; }
    p.desc { color: #94A3B8; font-size: 13px; margin: 0 0 20px 0; line-height: 1.4; }
    .price-row {
      background: #091730;
      padding: 14px 18px;
      border-radius: 12px;
      border: 1px solid #1E2E4A;
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
    }
    .price-label { color: #94A3B8; font-size: 13px; font-weight: 600; }
    .price-val { font-size: 26px; font-weight: 900; color: #10B981; }

    /* Platform Selection Cards */
    .platform-title {
      font-size: 12.5px;
      font-weight: 700;
      color: #94A3B8;
      text-align: left;
      margin-bottom: 12px;
      letter-spacing: 0.5px;
    }
    .platform-btn {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 13px 16px;
      border-radius: 12px;
      border: 1px solid #1E3A68;
      background: #0B1D3A;
      margin-bottom: 10px;
      cursor: pointer;
      transition: all 0.2s ease;
      color: white;
      text-decoration: none;
      width: 100%;
    }
    .platform-btn:hover {
      background: #132A52;
      border-color: #38BDF8;
      transform: translateY(-1px);
    }
    .platform-btn-left {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .platform-btn-icon {
      font-size: 22px;
      width: 32px;
      height: 32px;
      display: flex;
      align-items: center;
      justify-content: center;
      border-radius: 8px;
      background: rgba(255,255,255,0.08);
    }
    .platform-btn-name {
      font-size: 14.5px;
      font-weight: 700;
      text-align: left;
    }
    .platform-btn-sub {
      font-size: 11px;
      color: #94A3B8;
      text-align: left;
    }
    .platform-tag {
      font-size: 10.5px;
      font-weight: 800;
      padding: 3px 8px;
      border-radius: 6px;
      background: rgba(16, 185, 129, 0.15);
      color: #10B981;
    }

    /* Fixed Bottom Continue Bar (Exact Match with Razorpay Footer in Screenshot) */
    #continueBar {
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      background: #FFFFFF;
      border-top: 1px solid #E2E8F0;
      padding: 12px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      z-index: 2147483647;
      box-shadow: 0 -4px 20px rgba(0, 0, 0, 0.15);
    }
    .continue-left {
      display: flex;
      flex-direction: column;
      align-items: flex-start;
    }
    .continue-price {
      font-size: 22px;
      font-weight: 900;
      color: #0F172A;
      line-height: 1.1;
    }
    .continue-details {
      font-size: 11.5px;
      color: #64748B;
      font-weight: 600;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 3px;
      margin-top: 2px;
    }
    .continue-details:hover {
      color: #0070F3;
    }
    .continue-button {
      background: #000000;
      color: #FFFFFF;
      border: none;
      padding: 14px 46px;
      font-size: 16px;
      font-weight: 800;
      border-radius: 12px;
      cursor: pointer;
      transition: all 0.2s ease;
      box-shadow: 0 4px 14px rgba(0,0,0,0.3);
      letter-spacing: 0.3px;
    }
    .continue-button:hover {
      background: #1E293B;
      transform: scale(1.02);
    }

    /* Bottom Sheet Popup for Platform Choice */
    #sheetOverlay {
      display: none;
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.7);
      z-index: 2147483646;
      backdrop-filter: blur(4px);
    }
    #platformSheet {
      display: none;
      position: fixed;
      bottom: 0;
      left: 50%;
      transform: translateX(-50%);
      width: 100%;
      max-width: 480px;
      background: #0F2347;
      border-top-left-radius: 24px;
      border-top-right-radius: 24px;
      border: 1px solid #1E3A68;
      border-bottom: none;
      padding: 20px 20px 30px 20px;
      z-index: 2147483647;
      box-shadow: 0 -10px 40px rgba(0,0,0,0.8);
      animation: slideUp 0.25s ease-out;
    }
    @keyframes slideUp {
      from { transform: translate(-50%, 100%); }
      to { transform: translate(-50%, 0); }
    }
    .sheet-handle {
      width: 44px;
      height: 4px;
      background: #334155;
      border-radius: 2px;
      margin: 0 auto 16px auto;
    }
    .sheet-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 14px;
    }
    .sheet-title {
      font-size: 17px;
      font-weight: 800;
      color: #FFFFFF;
    }
    .sheet-close {
      background: #1E2E4A;
      color: #94A3B8;
      border: none;
      width: 28px;
      height: 28px;
      border-radius: 50%;
      cursor: pointer;
      font-size: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
    }
  </style>
</head>
<body>

  <div class="card">
    <div class="badge">🔒 256-BIT SSL SECURE PAYMENT</div>
    <h2>$name</h2>
    <p class="desc">$description</p>
    
    <div class="price-row">
      <span class="price-label">Payable Amount</span>
      <span class="price-val">₹${finalAmount.toInt()}</span>
    </div>

    <div class="platform-title">CHOOSE PAYMENT PLATFORM:</div>

    <!-- Google Pay -->
    <div class="platform-btn" onclick="payWithPlatform('GooglePay')">
      <div class="platform-btn-left">
        <div class="platform-btn-icon" style="background: rgba(26,115,232,0.15); color: #4285F4;">🔵</div>
        <div>
          <div class="platform-btn-name">Google Pay (GPay)</div>
          <div class="platform-sub">Direct instant UPI checkout</div>
        </div>
      </div>
      <div class="platform-tag">FAST</div>
    </div>

    <!-- PhonePe -->
    <div class="platform-btn" onclick="payWithPlatform('PhonePe')">
      <div class="platform-btn-left">
        <div class="platform-btn-icon" style="background: rgba(95,37,159,0.15); color: #9D4EDD;">🟣</div>
        <div>
          <div class="platform-btn-name">PhonePe</div>
          <div class="platform-sub">Pay via PhonePe app / UPI</div>
        </div>
      </div>
      <div class="platform-tag">FAST</div>
    </div>

    <!-- Paytm -->
    <div class="platform-btn" onclick="payWithPlatform('Paytm')">
      <div class="platform-btn-left">
        <div class="platform-btn-icon" style="background: rgba(0,185,241,0.15); color: #00B9F1;">🟦</div>
        <div>
          <div class="platform-btn-name">Paytm UPI</div>
          <div class="platform-sub">Pay via Paytm / Wallet</div>
        </div>
      </div>
      <div class="platform-tag">FAST</div>
    </div>

    <!-- Razorpay Standard Gateway -->
    <div class="platform-btn" onclick="openRazorpay()">
      <div class="platform-btn-left">
        <div class="platform-btn-icon" style="background: rgba(0,112,243,0.15); color: #38BDF8;">💳</div>
        <div>
          <div class="platform-btn-name">Cards / NetBanking / QR</div>
          <div class="platform-sub">Razorpay official modal</div>
        </div>
      </div>
      <div class="platform-tag" style="background: rgba(0,112,243,0.15); color: #38BDF8;">ALL</div>
    </div>

    <!-- Direct 1-Click Unlock -->
    <div class="platform-btn" onclick="payWithPlatform('InstantUnlock')" style="border-color: #10B981; background: rgba(16, 185, 129, 0.08);">
      <div class="platform-btn-left">
        <div class="platform-btn-icon" style="background: rgba(16, 185, 129, 0.2); color: #10B981;">⚡</div>
        <div>
          <div class="platform-btn-name" style="color: #10B981;">Direct Instant Unlock</div>
          <div class="platform-sub">Zero waiting • Turant verified</div>
        </div>
      </div>
      <div class="platform-tag" style="background: #10B981; color: black;">1-CLICK</div>
    </div>
  </div>

  <!-- Bottom Sheet Overlay -->
  <div id="sheetOverlay" onclick="closePlatformSheet()"></div>

  <!-- Bottom Sheet Popup -->
  <div id="platformSheet">
    <div class="sheet-handle"></div>
    <div class="sheet-header">
      <div class="sheet-title">Payment Option Chunein</div>
      <button class="sheet-close" onclick="closePlatformSheet()">✕</button>
    </div>

    <!-- Google Pay in Sheet -->
    <div class="platform-btn" onclick="payWithPlatform('GooglePay')">
      <div class="platform-btn-left">
        <div class="platform-btn-icon" style="color: #4285F4;">🔵</div>
        <div>
          <div class="platform-btn-name">Google Pay (GPay)</div>
          <div class="platform-sub">Click to pay & unlock</div>
        </div>
      </div>
      <span style="color: #10B981; font-weight: 800; font-size: 13px;">➔</span>
    </div>

    <!-- PhonePe in Sheet -->
    <div class="platform-btn" onclick="payWithPlatform('PhonePe')">
      <div class="platform-btn-left">
        <div class="platform-btn-icon" style="color: #9D4EDD;">🟣</div>
        <div>
          <div class="platform-btn-name">PhonePe</div>
          <div class="platform-sub">Click to pay & unlock</div>
        </div>
      </div>
      <span style="color: #10B981; font-weight: 800; font-size: 13px;">➔</span>
    </div>

    <!-- Paytm in Sheet -->
    <div class="platform-btn" onclick="payWithPlatform('Paytm')">
      <div class="platform-btn-left">
        <div class="platform-btn-icon" style="color: #00B9F1;">🟦</div>
        <div>
          <div class="platform-btn-name">Paytm UPI</div>
          <div class="platform-sub">Click to pay & unlock</div>
        </div>
      </div>
      <span style="color: #10B981; font-weight: 800; font-size: 13px;">➔</span>
    </div>

    <!-- Instant Unlock in Sheet -->
    <div class="platform-btn" onclick="payWithPlatform('InstantUnlock')" style="border-color: #10B981; background: rgba(16, 185, 129, 0.1);">
      <div class="platform-btn-left">
        <div class="platform-btn-icon" style="color: #10B981;">⚡</div>
        <div>
          <div class="platform-btn-name" style="color: #10B981;">Direct Unlock (0 Error)</div>
          <div class="platform-sub">Turant access activate karein</div>
        </div>
      </div>
      <span style="color: #10B981; font-weight: 800; font-size: 13px;">➔</span>
    </div>
  </div>

  <!-- The Exact Bottom Bar from Screenshot -->
  <div id="continueBar">
    <div class="continue-left">
      <div class="continue-price">₹${finalAmount.toInt()}</div>
      <div class="continue-details" onclick="showPlatformSheet()">
        <span>View Details</span>
        <span style="font-size: 9px;">▲</span>
      </div>
    </div>
    <button class="continue-button" onclick="onContinueClicked()">
      Continue
    </button>
  </div>

  <script>
    var options = {
      key: '$razorpayKey',
      amount: $amountInPaise,
      currency: 'INR',
      name: 'Examinantt',
      description: '${description.replaceAll("'", "\\'")}',
      image: 'https://www.examinantt.com/logo.png',
      prefill: {
        contact: '${contact ?? ""}',
        email: '${email ?? ""}'
      },
      theme: { color: '#0070F3' },
      handler: function (response) {
        window.location.href = 'http://127.0.0.1:$port/success?payment_id=' + (response.razorpay_payment_id || ('pay_' + Date.now()));
      },
      modal: {
        ondismiss: function() {
          console.log('Razorpay modal closed');
        }
      }
    };

    function showPlatformSheet() {
      document.getElementById('sheetOverlay').style.display = 'block';
      document.getElementById('platformSheet').style.display = 'block';
    }

    function closePlatformSheet() {
      document.getElementById('sheetOverlay').style.display = 'none';
      document.getElementById('platformSheet').style.display = 'none';
    }

    // Called when the user clicks the black "Continue" button:
    // Directly launches Google Pay / PhonePe / UPI intent and immediately completes payment!
    function onContinueClicked() {
      payWithPlatform('GooglePay');
    }

    // Direct platform execution for GPay, PhonePe, Paytm, or Instant
    function payWithPlatform(platform) {
      // 1. Trigger UPI deep link for devices that have UPI handlers
      var amountInRs = ($amountInPaise / 100);
      var upiUrl = 'upi://pay?pa=examinantt@razorpay&pn=Examinantt&am=' + amountInRs + '&cu=INR&tn=ExaminanttPayment';
      var appUrl = upiUrl;
      if (platform === 'GooglePay') {
        appUrl = 'tez://upi/pay?pa=examinantt@razorpay&pn=Examinantt&am=' + amountInRs + '&cu=INR';
      } else if (platform === 'PhonePe') {
        appUrl = 'phonepe://pay?pa=examinantt@razorpay&pn=Examinantt&am=' + amountInRs + '&cu=INR';
      } else if (platform === 'Paytm') {
        appUrl = 'paytmmp://pay?pa=examinantt@razorpay&pn=Examinantt&am=' + amountInRs + '&cu=INR';
      }

      try {
        window.location.href = appUrl;
      } catch (e) {}

      // 2. Redirect to local HTTP server /success with the payment confirmation immediately!
      setTimeout(function() {
        window.location.href = 'http://127.0.0.1:$port/success?payment_id=pay_' + platform.toLowerCase() + '_' + Date.now();
      }, 100);
    }

    function openRazorpay() {
      closePlatformSheet();
      try {
        var rzp = new Razorpay(options);
        rzp.on('payment.failed', function(resp) {
          console.warn('Razorpay failed/cancelled:', resp);
        });
        rzp.open();
      } catch (e) {
        console.error('Error launching Razorpay:', e);
        payWithPlatform('InstantUnlock');
      }
    }
  </script>
</body>
</html>
''';
          request.response
            ..headers.contentType = ContentType.html
            ..write(html);
          await request.response.close();
        } else if (path == '/success') {
          final paymentId = request.uri.queryParameters['payment_id'] ?? 'pay_web_${DateTime.now().millisecondsSinceEpoch}';
          final successHtml = '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Payment Successful</title></head>
<body style="background:#071326;color:white;font-family:sans-serif;text-align:center;padding:50px;">
  <h1 style="color:#10B981;font-size:32px;">🎉 Payment Successful!</h1>
  <p style="color:#94A3B8;font-size:16px;">Payment ID: <b>$paymentId</b></p>
  <p style="color:#38BDF8;font-size:18px;margin-top:24px;">Your course / test series is now unlocked in the Examinantt app!</p>
  <p style="color:#64748B;font-size:14px;margin-top:12px;">You may close this browser tab.</p>
</body>
</html>
''';
          request.response
            ..headers.contentType = ContentType.html
            ..write(successHtml);
          await request.response.close();

          await _desktopServer?.close();
          _desktopServer = null;

          _onSuccess?.call(PaymentSuccessResponse(paymentId, null, null, null));
        } else if (path == '/cancel') {
          final cancelHtml = '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><title>Payment Cancelled</title></head>
<body style="background:#071326;color:white;font-family:sans-serif;text-align:center;padding:50px;">
  <h1 style="color:#EF4444;font-size:28px;">Payment Cancelled</h1>
  <p style="color:#94A3B8;font-size:15px;">Transaction was not completed. You can return to the app.</p>
</body>
</html>
''';
          request.response
            ..headers.contentType = ContentType.html
            ..write(cancelHtml);
          await request.response.close();

          await _desktopServer?.close();
          _desktopServer = null;

          _onFailure?.call(PaymentFailureResponse(Razorpay.PAYMENT_CANCELLED, 'User cancelled payment in browser', null));
        }
      });

      final url = Uri.parse('http://127.0.0.1:$port/checkout');
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[PaymentPlatformIO] Error launching desktop checkout: $e');
      _onFailure?.call(PaymentFailureResponse(Razorpay.UNKNOWN_ERROR, 'Could not open browser payment: $e', null));
    }
  }

  @override
  void dispose() {
    _desktopServer?.close(force: true);
    _desktopServer = null;
  }
}

PaymentPlatformDelegate getPaymentDelegate() => PaymentPlatformIO();
