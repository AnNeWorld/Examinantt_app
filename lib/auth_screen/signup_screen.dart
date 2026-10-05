import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final stateController = TextEditingController();
  final districtController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _showSuccessPopup(String message) {
    if (!mounted) return;

    bool dismissed = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        Future.delayed(const Duration(milliseconds: 1000), () {
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: const Color(0xFF071938),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              decoration: BoxDecoration(
                color: const Color(0xFF071938),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFF7A00).withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A00).withValues(alpha: 0.2),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 38),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Welcome to Examinantt!',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: const Color(0xFFA0AEC0),
                      height: 1.4,
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
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    stateController.dispose();
    districtController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF64748B),
        fontSize: 14.5,
      ),
      filled: true,
      fillColor: const Color(0xFF00122C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFFFF7A00)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF7A00), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.6),
      ),
    );
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
                  const SizedBox(height: 12),

                  // Top bar with Back Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF071938),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          'Create Account',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Prominent Classic Examinantt Logo & Branding
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
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
                                height: 64,
                                width: 64,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Examinantt',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Start Your Success Journey',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFA0AEC0),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0),

                  const SizedBox(height: 20),

                  // Classic Sign Up Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
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
                            'Sign Up',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Create your student profile to access all features.',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFA0AEC0),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Full Name
                          Text(
                            'Full Name',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: const Color(0xFFF1F5F9),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15.5),
                            validator: (value) => value == null || value.trim().isEmpty ? 'Full Name is required' : null,
                            decoration: _inputDecoration('Enter your full name', Icons.person_outline_rounded),
                          ),
                          const SizedBox(height: 18),

                          // Email Address
                          Text(
                            'Email Address',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: const Color(0xFFF1F5F9),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15.5),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            decoration: _inputDecoration('you@example.com', Icons.mail_outline_rounded),
                          ),
                          const SizedBox(height: 18),

                          // Mobile Number
                          Text(
                            'Mobile Number',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: const Color(0xFFF1F5F9),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15.5),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Mobile Number is required';
                              }
                              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                              if (digits.length < 10) {
                                return 'Enter a valid 10-digit mobile number';
                              }
                              return null;
                            },
                            decoration: _inputDecoration('Enter 10-digit mobile number', Icons.phone_android_rounded),
                          ),
                          const SizedBox(height: 18),

                          // State & District Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'State',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: stateController,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                      decoration: _inputDecoration('State', Icons.location_on_outlined),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'District',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: districtController,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                      decoration: _inputDecoration('District', Icons.location_city_rounded),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Password & Confirm Password
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: passwordController,
                                      obscureText: !_isPasswordVisible,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required';
                                        if (value.length < 6) return 'Min 6 chars';
                                        return null;
                                      },
                                      decoration: _inputDecoration('••••••••', Icons.lock_outline_rounded).copyWith(
                                        suffixIcon: IconButton(
                                          splashRadius: 18,
                                          icon: Icon(
                                            _isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: const Color(0xFF94A3B8),
                                            size: 18,
                                          ),
                                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Confirm',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: confirmPasswordController,
                                      obscureText: !_isConfirmPasswordVisible,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) return 'Required';
                                        if (value != passwordController.text) return 'Mismatch';
                                        return null;
                                      },
                                      decoration: _inputDecoration('••••••••', Icons.lock_outline_rounded).copyWith(
                                        suffixIcon: IconButton(
                                          splashRadius: 18,
                                          icon: Icon(
                                            _isConfirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: const Color(0xFF94A3B8),
                                            size: 18,
                                          ),
                                          onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Create Account Button
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
                                      setState(() => isLoading = true);
                                      final name = nameController.text.trim();
                                      final email = emailController.text.trim();
                                      final phone = phoneController.text.trim();
                                      final password = passwordController.text.trim();
                                      final messenger = ScaffoldMessenger.of(context);

                                      final error = await Provider.of<UserProvider>(
                                        context,
                                        listen: false,
                                      ).signup(
                                        name: name,
                                        email: email,
                                        phone: phone,
                                        password: password,
                                      );

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
                                        _showSuccessPopup('Account Created Successfully!');
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Create Account',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 19,
                                          color: Colors.white,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Sign In Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14.5,
                                  color: const Color(0xFFA0AEC0),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    'Sign in',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFFF7A00),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(
                        begin: 0.1,
                        end: 0,
                        curve: Curves.easeOutCubic,
                        duration: 500.ms,
                      ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
