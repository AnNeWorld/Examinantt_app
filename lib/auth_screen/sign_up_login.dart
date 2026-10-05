import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _formKey = GlobalKey<FormState>();
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

  void _showSuccessPopup(String message) {
    if (!mounted) return;

    bool dismissed = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        // Auto-dismiss popup quickly after 600ms so it never stays stuck
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Prominent Classic Examinantt Logo & Branding with ambient glow
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Ambient warm glow that scrolls together with logo
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFF7A00).withValues(alpha: 0.07),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF7A00)
                                        .withValues(alpha: 0.40),
                                    blurRadius: 28,
                                    spreadRadius: 3,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/app_icon.png',
                                height: 72,
                                width: 72,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Examinantt',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Premier Exam Preparation Platform',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFA0AEC0),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.8,
                                wordSpacing: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 24),

                  // Classic Login Card
                  Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF071938).withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Sign in to access your tests and preparation.',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFA0AEC0),
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.6,
                                wordSpacing: 1.6,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 26),

                            // Mobile Number or Email Field Label
                            Text(
                              'Mobile Number or Email',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                color: const Color(0xFFF1F5F9),
                                letterSpacing: 0.8,
                                wordSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 9),
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.text,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.7,
                                wordSpacing: 1.5,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Mobile number or email is required';
                                }
                                final input = value.trim();
                                final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
                                final isPhone = digits.length == 10 || (digits.length >= 10 && digits.length <= 13 && !input.contains('@'));
                                final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
                                if (!isPhone && !isEmail) {
                                  return 'Enter a valid 10-digit mobile number or email';
                                }
                                return null;
                              },
                              decoration: _inputDecoration(
                                'Enter your mobile number or email',
                                Icons.phone_android_rounded,
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Password Field Label
                            Text(
                              'Password',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                color: const Color(0xFFF1F5F9),
                                letterSpacing: 0.8,
                                wordSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 9),
                            TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.7,
                                wordSpacing: 1.5,
                              ),
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
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.7,
                                  wordSpacing: 1.5,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF00122C),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 17,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 22,
                                  color: Color(0xFFFF7A00),
                                ),
                                suffixIcon: IconButton(
                                  splashRadius: 22,
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
                                    width: 1.6,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Remember me + Forgot password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: Checkbox(
                                        value: rememberMe,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        side: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.3),
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
                                    Text(
                                      'Remember for 30 days',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        color: const Color(0xFFE2E8F0),
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        wordSpacing: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen(),
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
                                        fontSize: 14.5,
                                        letterSpacing: 0.6,
                                        wordSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),

                            // Sign In Button
                            Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
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
                                    color: const Color(0xFFFF7A00)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () async {
                                        if (!_formKey.currentState!.validate()) {
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
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Sign In',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 1.4,
                                              wordSpacing: 2.0,
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
                            const SizedBox(height: 22),

                            // Sign up link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    color: const Color(0xFFA0AEC0),
                                    letterSpacing: 0.6,
                                    wordSpacing: 1.4,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const SignupScreen(),
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
                                        fontSize: 15,
                                        letterSpacing: 0.6,
                                        wordSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(
                          begin: 0.15,
                          end: 0,
                          curve: Curves.easeOutCubic,
                          duration: 600.ms,
                        ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF64748B),
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.7,
        wordSpacing: 1.5,
      ),
      filled: true,
      fillColor: const Color(0xFF00122C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
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
          width: 1.6,
        ),
      ),
    );
  }
}
