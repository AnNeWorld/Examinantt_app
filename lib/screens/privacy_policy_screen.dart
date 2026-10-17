import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final bodyTextColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    final metaColor = isDark ? AppColors.textDarkSecondary : Colors.grey.shade600;
    final dividerColor = isDark ? Colors.white12 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFFA000),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 650));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for Examinantt',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Last updated: July 2026',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: metaColor,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: dividerColor),
            const SizedBox(height: 18),
            Text(
              'Your privacy is extremely important to us. This Privacy Policy explains what information we collect, how we use it, and your rights regarding your personal data.',
              style: TextStyle(
                fontSize: 14,
                color: bodyTextColor,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Information We Collect',
              content:
                  'We collect personal information that you provide to us when you register on the app, express an interest in obtaining information about us or our courses, or otherwise contact us. This includes your name, email address, phone number, exam preparation target, and device identifiers.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '2. How We Use Your Information',
              content:
                  'We use collected information to facilitate account creation, provide mock test analytics, manage purchases, deliver live streaming lectures, send important study updates, and enhance your personalized learning experience.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '3. Will Your Information Be Shared?',
              content:
                  'We do NOT sell your personal data. We only share information with your express consent, to comply with legal obligations, to protect your safety, or with trusted service providers (e.g., payment gateways and hosting providers) strictly necessary for delivering app services.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '4. Data Security',
              content:
                  'We employ industry-standard encryption, SSL protocols, and cloud access controls to safeguard your data. While we implement rigorous protections, no transmission over the internet can be 100% immune from security threats.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '5. Your Rights and Preferences',
              content:
                  'You have the right to request access to the personal data we hold about you, request corrections or updates, or delete your account. You can manage your profile settings anytime directly from the Profile section of the app.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '6. Contact Us',
              content:
                  'If you have questions, feedback, or data privacy requests, please reach out to us at support@examinantt.com or write to our support desk in Lucknow, Uttar Pradesh, India.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                '© 2026 Examinantt. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: metaColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSection({
    required String title,
    required String content,
    required Color textColor,
    required Color bodyTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: bodyTextColor,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
