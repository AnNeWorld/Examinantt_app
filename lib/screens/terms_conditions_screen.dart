import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
          'Terms & Conditions',
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
              'Terms and Conditions for Examinantt',
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
              'Please read these terms and conditions carefully before using our mobile application and online learning services.',
              style: TextStyle(
                fontSize: 14,
                color: bodyTextColor,
                height: 1.6,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: '1. Acceptance of Terms',
              content:
                  'By accessing and using this app, you accept and agree to be bound by the terms and provisions of this agreement. In addition, when using this app\'s particular services, you shall be subject to any posted guidelines or rules applicable to such services.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '2. User Account',
              content:
                  'If you create an account on the app, you are responsible for maintaining the security of your account and credentials. You are fully responsible for all activities that occur under the account and any other actions taken in connection with it. Sharing account credentials across multiple individuals is strictly prohibited.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '3. Payment and Subscriptions',
              content:
                  'Certain courses, test series, and learning resources on the app are available through one-time payments or recurring subscriptions. All payments processed via authorized gateways are final and non-refundable unless explicitly stated otherwise in our Refund Policy. Subscriptions automatically renew unless cancelled prior to the renewal date.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '4. Intellectual Property',
              content:
                  'All study material, mock test series, live lectures, video recordings, PPT notes, question banks, brand marks, and software code are the exclusive intellectual property of Examinantt. Users may not copy, reproduce, distribute, or reverse engineer any part of the service without prior written permission.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '5. User Conduct and Restrictions',
              content:
                  'You agree not to use the platform for any unlawful purpose or to solicit others to perform or participate in any unlawful acts. Harassment, abuse, insulting language, spamming, and attempting to compromise server security or data integrity are grounds for immediate termination of your account.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '6. Modifications to Terms',
              content:
                  'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. We will notify users of any material changes by updating the "Last updated" date of these Terms or via in-app notification.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '7. Governing Law and Jurisdiction',
              content:
                  'These Terms and Conditions shall be governed by and construed in accordance with the laws of India. Any disputes arising out of or related to the use of Examinantt shall be subject to the exclusive jurisdiction of the competent courts in Lucknow, Uttar Pradesh.',
              textColor: textColor,
              bodyTextColor: bodyTextColor,
            ),
            _buildSection(
              title: '8. Contact Information',
              content:
                  'If you have any questions or feedback regarding these Terms & Conditions, please reach out to our team at support@examinantt.com or through the Help & Support section in the app.',
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
