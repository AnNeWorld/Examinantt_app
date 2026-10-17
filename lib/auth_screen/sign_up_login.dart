import 'package:examinantt_app/utils/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import '../providers/user_provider.dart';
import '../screens/main_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  int currentStep = 0;
  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSuccessPopup(String message) {
    if (!mounted) return;

    bool dismissed = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!dismissed && dialogCtx.mounted) {
            dismissed = true;
            if (Navigator.of(dialogCtx, rootNavigator: true).canPop()) {
              Navigator.of(dialogCtx, rootNavigator: true).pop();
            }
          }
        });

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!dismissed && dialogCtx.mounted) {
              dismissed = true;
              if (Navigator.of(dialogCtx, rootNavigator: true).canPop()) {
                Navigator.of(dialogCtx, rootNavigator: true).pop();
              }
            }
          },
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  void _goToStep2() {
    if (_step1FormKey.currentState!.validate()) {
      setState(() => currentStep = 1);
    }
  }

  Future<void> _handleSignIn() async {
    if (!_step2FormKey.currentState!.validate()) {
      return;
    }
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final userProvider = Provider.of<UserProvider>(
      context,
      listen: false,
    );
    final messenger = ScaffoldMessenger.of(context);
    setState(() => isLoading = true);
    final error = await userProvider.login(email, password);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (error != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showSuccessPopup('Login Successful!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && currentStep > 0) {
          setState(() => currentStep = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF001026),
        body: Stack(
          children: [
            // Classic Executive Deep Navy Gradient Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF00193D),
                      Color(0xFF001028),
                      Color(0xFF000814),
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenHeight = constraints.maxHeight;
                  final screenWidth = constraints.maxWidth;

                  final isSmallPhone = screenWidth < 380;
                  final isTablet = screenWidth >= 600;

                  // Responsive sizing & scaling according to device dimensions
                  final double horizontalMargin = isTablet ? 32.0 : (isSmallPhone ? 16.0 : 22.0);
                  final double cardMaxWidth = isTablet
                      ? (screenWidth * 0.78).clamp(560.0, 680.0)
                      : double.infinity;

                  // Generous sizing for clear readability & premium look
                  final double logoSize = isTablet ? 88.0 : (isSmallPhone ? 62.0 : 72.0);
                  final double brandFontSize = isTablet ? 30.0 : (isSmallPhone ? 24.0 : 27.0);
                  final double brandSubtitleSize = isTablet ? 15.5 : (isSmallPhone ? 13.0 : 14.0);
                  final double logoToCardGap = isTablet ? 30.0 : (isSmallPhone ? 18.0 : 24.0);

                  final double cardPaddingH = isTablet ? 36.0 : (isSmallPhone ? 20.0 : 26.0);
                  final double cardPaddingV = isTablet ? 36.0 : (isSmallPhone ? 22.0 : 28.0);
                  final double welcomeFontSize = isTablet ? 28.0 : (isSmallPhone ? 22.0 : 25.0);
                  final double welcomeSubtitleSize = isTablet ? 15.0 : (isSmallPhone ? 13.0 : 14.0);

                  final double labelFontSize = isTablet ? 15.5 : (isSmallPhone ? 13.5 : 14.5);
                  final double inputFontSize = isTablet ? 16.5 : (isSmallPhone ? 14.5 : 15.5);
                  final double inputPaddingV = isTablet ? 17.0 : (isSmallPhone ? 13.0 : 15.5);
                  final double fieldGap = isTablet ? 18.0 : (isSmallPhone ? 12.0 : 15.0);

                  final double buttonHeight = isTablet ? 58.0 : (isSmallPhone ? 50.0 : 54.0);
                  final double buttonFontSize = isTablet ? 19.0 : (isSmallPhone ? 16.5 : 17.5);
                  final double footerFontSize = isTablet ? 15.5 : (isSmallPhone ? 13.5 : 14.5);

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: screenHeight,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: cardMaxWidth),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontalMargin,
                              vertical: isTablet ? 36.0 : 20.0,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Prominent Examinantt Logo & Branding
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFFF7A00).withValues(alpha: 0.38),
                                              blurRadius: 24,
                                              spreadRadius: 3,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/app_icon.png',
                                            height: logoSize,
                                            width: logoSize,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Examinantt',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: brandFontSize,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Premier Exam Preparation Platform',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFFA0AEC0),
                                          fontSize: brandSubtitleSize,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: logoToCardGap),

                                // Substantial, Premium Multi-Step Login Card
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: cardPaddingH,
                                    vertical: cardPaddingV,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF071938).withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.40),
                                        blurRadius: 28,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Animated Step Switcher
                                      AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 300),
                                        switchInCurve: Curves.easeOutCubic,
                                        switchOutCurve: Curves.easeInCubic,
                                        transitionBuilder: (child, animation) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: Offset(currentStep == 0 ? -0.04 : 0.04, 0),
                                                end: Offset.zero,
                                              ).animate(animation),
                                              child: child,
                                            ),
                                          );
                                        },
                                        child: currentStep == 0
                                            ? _buildStep1(
                                                welcomeFontSize: welcomeFontSize,
                                                welcomeSubtitleSize: welcomeSubtitleSize,
                                                labelFontSize: labelFontSize,
                                                inputFontSize: inputFontSize,
                                                inputPaddingV: inputPaddingV,
                                                fieldGap: fieldGap,
                                                buttonHeight: buttonHeight,
                                                buttonFontSize: buttonFontSize,
                                                footerFontSize: footerFontSize,
                                              )
                                            : _buildStep2(
                                                welcomeFontSize: welcomeFontSize,
                                                welcomeSubtitleSize: welcomeSubtitleSize,
                                                labelFontSize: labelFontSize,
                                                inputFontSize: inputFontSize,
                                                inputPaddingV: inputPaddingV,
                                                fieldGap: fieldGap,
                                                buttonHeight: buttonHeight,
                                                buttonFontSize: buttonFontSize,
                                                footerFontSize: footerFontSize,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1({
    required double welcomeFontSize,
    required double welcomeSubtitleSize,
    required double labelFontSize,
    required double inputFontSize,
    required double inputPaddingV,
    required double fieldGap,
    required double buttonHeight,
    required double buttonFontSize,
    required double footerFontSize,
  }) {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('step_1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back',
            style: GoogleFonts.plusJakartaSans(
              fontSize: welcomeFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your mobile number or email to continue.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFA0AEC0),
              fontSize: welcomeSubtitleSize,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: fieldGap + 4),

          // Mobile Number or Email Label
          Text(
            'Mobile Number or Email',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: labelFontSize,
              color: const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: inputFontSize,
              fontWeight: FontWeight.w500,
            ),
            onFieldSubmitted: (_) => _goToStep2(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Mobile number or email is required';
              }
              final input = value.trim();
              final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
              final isPhone = digits.length == 10 ||
                  (digits.length >= 10 && digits.length <= 13 && !input.contains('@'));
              final isEmail =
                  RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
              if (!isPhone && !isEmail) {
                return 'Enter a valid 10-digit mobile number or email';
              }
              return null;
            },
            decoration: _inputDecoration(
              'Enter your mobile number or email',
              Icons.phone_android_rounded,
              inputFontSize,
              inputPaddingV,
            ),
          ),
          SizedBox(height: fieldGap + 8),

          // Continue Button
          Container(
            width: double.infinity,
            height: buttonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF7A00),
                  Color(0xFFFF9526),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _goToStep2,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continue',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: fieldGap + 4),

          // Sign up link
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: footerFontSize,
                    color: const Color(0xFFA0AEC0),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    AppNavigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Sign up for free',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFFF7A00),
                        fontWeight: FontWeight.w800,
                        fontSize: footerFontSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2({
    required double welcomeFontSize,
    required double welcomeSubtitleSize,
    required double labelFontSize,
    required double inputFontSize,
    required double inputPaddingV,
    required double fieldGap,
    required double buttonHeight,
    required double buttonFontSize,
    required double footerFontSize,
  }) {

    return Form(
      key: _step2FormKey,
      child: Column(
        key: const ValueKey('step_2'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Password',
            style: GoogleFonts.plusJakartaSans(
              fontSize: welcomeFontSize,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your password to sign in to Examinantt.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFA0AEC0),
              fontSize: welcomeSubtitleSize,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: fieldGap + 4),

          // Password Field Label
          Text(
            'Password',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: labelFontSize,
              color: const Color(0xFFF1F5F9),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: inputFontSize,
              fontWeight: FontWeight.w500,
            ),
            onFieldSubmitted: (_) => _handleSignIn(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              if (value.trim().length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Enter your password',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: inputFontSize - 1.0,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: const Color(0xFF00122C),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: inputPaddingV,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                size: 22,
                color: Color(0xFFFF7A00),
              ),
              suffixIcon: IconButton(
                splashRadius: 20,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 22,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: () => setState(
                  () => obscurePassword = !obscurePassword,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFFF7A00),
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.2,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFEF4444),
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Remember me + Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: rememberMe,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        checkColor: Colors.black,
                        activeColor: const Color(0xFFFF7A00),
                        onChanged: (v) => setState(
                          () => rememberMe = v ?? false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Remember me',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: labelFontSize - 0.5,
                          color: const Color(0xFFE2E8F0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  AppNavigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFFF7A00),
                      fontWeight: FontWeight.w700,
                      fontSize: labelFontSize - 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: fieldGap + 4),

          // Sign In Button
          Container(
            width: double.infinity,
            height: buttonHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF7A00),
                  Color(0xFFFF9526),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.40),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sign In',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: fieldGap),

          // Back / Switch Account Button
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => currentStep = 0),
              icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFFA0AEC0)),
              label: Text(
                'Back to account step',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFA0AEC0),
                  fontSize: footerFontSize - 0.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, double fontSize, double paddingV) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF64748B),
        fontSize: fontSize - 1.0,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: const Color(0xFF00122C),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: paddingV,
      ),
      prefixIcon: Icon(icon, size: 22, color: const Color(0xFFFF7A00)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFFF7A00),
          width: 1.8,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.2,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
    );
  }
}
