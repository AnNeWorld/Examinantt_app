import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/images.dart';
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
  bool isEmailLogin = true;
  bool isOtpSent = false;
  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;
  final String _verificationId = "";
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _showSuccessPopup(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.pop(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  Future<void> _verifyManualOtp() async {
    if (passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter OTP')));
      return;
    }
    setState(() => isLoading = true);

    await Future.delayed(
      const Duration(seconds: 1),
    ); // Simulate network request
    if (passwordController.text == '123456') {
      if (mounted) {
        setState(() => isLoading = false);
        _showSuccessPopup('Login Successful!');
      }
    } else {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Image Slider
          CarouselSlider(
            options: CarouselOptions(
              height: MediaQuery.of(context).size.height,
              viewportFraction: 1.0,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 2),
              autoPlayAnimationDuration: const Duration(milliseconds: 800),
            ),
            items: AppImages.sliderImages.map((imageUrl) {
              return Builder(
                builder: (BuildContext context) {
                  return Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                  );
                },
              );
            }).toList(),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      // Top Logo
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  'assets/app_icon.png',
                                  height: 20,
                                  width: 20,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Examinantt',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Bottom Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 0),
                                  const Text(
                                    'Welcome Back!',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Please enter your details.',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Toggle: Email / Mobile OTP
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        _toggleButton(
                                          'Email Login',
                                          isEmailLogin,
                                          () {
                                            setState(() => isEmailLogin = true);
                                          },
                                        ),
                                        _toggleButton(
                                          'Mobile OTP Login',
                                          !isEmailLogin,
                                          () {
                                            setState(() {
                                              isEmailLogin = false;
                                              isOtpSent = false;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Email/Mobile field
                                  Text(
                                    isEmailLogin ? 'Email' : 'Mobile Number',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    controller: emailController,
                                    keyboardType: isEmailLogin
                                        ? TextInputType.emailAddress
                                        : TextInputType.phone,
                                    style: const TextStyle(color: Colors.black),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                        ? (isEmailLogin
                                              ? 'Email is required'
                                              : 'Mobile number is required')
                                        : null,
                                    decoration: _inputDecoration(
                                      isEmailLogin
                                          ? 'Enter your email'
                                          : 'Enter mobile number',
                                      isEmailLogin
                                          ? Icons.mail_outline
                                          : Icons.phone_android,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Password/OTP field
                                  if (isEmailLogin ||
                                      (!isEmailLogin && isOtpSent)) ...[
                                    Text(
                                      isEmailLogin ? 'Password' : 'OTP',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: isEmailLogin
                                          ? obscurePassword
                                          : false,
                                      keyboardType: isEmailLogin
                                          ? TextInputType.text
                                          : TextInputType.number,
                                      style: const TextStyle(color: Colors.black),
                                      autofillHints: isEmailLogin
                                          ? null
                                          : const [AutofillHints.oneTimeCode],
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                          ? (isEmailLogin
                                                ? 'Password is required'
                                                : 'OTP is required')
                                          : null,
                                      onChanged: (val) {
                                        if (!isEmailLogin && val.length == 6) {
                                          _verifyManualOtp();
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: isEmailLogin
                                            ? 'Enter your password'
                                            : 'Enter OTP',
                                        hintStyle: const TextStyle(
                                          color: Colors.black38,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        prefixIcon: Icon(
                                          isEmailLogin
                                              ? Icons.lock_outline
                                              : Icons.message,
                                          size: 20,
                                          color: Colors.black54,
                                        ),
                                        suffixIcon: isEmailLogin
                                            ? IconButton(
                                                icon: Icon(
                                                  obscurePassword
                                                      ? Icons.visibility_off
                                                      : Icons.visibility,
                                                  size: 20,
                                                  color: Colors.black54,
                                                ),
                                                onPressed: () => setState(
                                                  () => obscurePassword =
                                                      !obscurePassword,
                                                ),
                                              )
                                            : null,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // Remember me + Forgot password
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: rememberMe,
                                            side: const BorderSide(
                                              color: Colors.black54,
                                            ),
                                            checkColor: Colors.white,
                                            activeColor: Colors.black,
                                            onChanged: (v) => setState(
                                              () => rememberMe = v ?? false,
                                            ),
                                          ),
                                          const Text(
                                            'Remember for 30 days',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ForgotPasswordScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Forgot password?',
                                          style: TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Sign In button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : () async {
                                              if (!_formKey.currentState!
                                                  .validate()) {
                                                return;
                                              }

                                              if (!isEmailLogin && !isOtpSent) {
                                                setState(() => isLoading = true);
                                                await Future.delayed(
                                                  const Duration(seconds: 1),
                                                ); // Simulate network delay
                                                if (mounted) {
                                                  setState(() {
                                                    isOtpSent = true;
                                                    isLoading = false;
                                                  });
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'OTP Sent! (Dummy OTP: 123456)',
                                                      ),
                                                    ),
                                                  );

                                                  await Future.delayed(
                                                    const Duration(
                                                      milliseconds: 600,
                                                    ),
                                                  );
                                                  if (mounted) {
                                                    passwordController.text =
                                                        '123456';
                                                    _verifyManualOtp(); // Auto submit
                                                  }
                                                }
                                                return;
                                              }

                                              if (isEmailLogin) {
                                                setState(() => isLoading = true);
                                                try {
                                                  await _auth
                                                      .signInWithEmailAndPassword(
                                                        email: emailController.text
                                                            .trim(),
                                                        password: passwordController
                                                            .text
                                                            .trim(),
                                                      );
                                                  if (mounted) {
                                                    setState(
                                                      () => isLoading = false,
                                                    );
                                                    _showSuccessPopup(
                                                      'Login Successful!',
                                                    );
                                                  }
                                                } on FirebaseAuthException catch (
                                                  e
                                                ) {
                                                  if (mounted) {
                                                    setState(
                                                      () => isLoading = false,
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          e.message ??
                                                              'Login failed',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              } else {
                                                _verifyManualOtp();
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
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
                                                  isEmailLogin
                                                      ? 'Sign In'
                                                      : (isOtpSent
                                                            ? 'Verify & Sign In'
                                                            : 'Send OTP'),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons.arrow_forward,
                                                  size: 18,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Sign up link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        "Don't have an account? ",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
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
                                        child: const Text(
                                          'Sign up for free',
                                          style: TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().slideY(
                        begin: 1,
                        end: 0,
                        curve: Curves.easeOutCubic,
                        duration: 600.ms,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active
                ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.black : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefixIcon: Icon(icon, size: 20, color: Colors.black54),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );
  }
}
