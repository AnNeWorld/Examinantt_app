import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final bodyTextColor = isDark ? AppColors.textDarkSecondary : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? AppColors.backgroundDark : AppTheme.darkSlate,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Contact Us',
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Icon(
                        Icons.headset_mic_rounded,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get in Touch',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If you have any queries, feel free to reach out to us. We are always here to help you succeed.',
                    style: TextStyle(
                      fontSize: 15,
                      color: bodyTextColor,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildContactCard(
                    context,
                    icon: Icons.chat_rounded,
                    title: 'WhatsApp Support',
                    content: '+91 8881188678 (24x7 Helpdesk)',
                    color: const Color(0xFF25D366),
                    onTap: () async {
                      final Uri url = Uri.parse('https://wa.me/918881188678?text=Hello%20Examinantt%20Team%2C%20I%20need%20help%20with%20my%20preparation.');
                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp')));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    context,
                    icon: Icons.phone_rounded,
                    title: 'Call Us',
                    content: '+91 8881188678',
                    color: Colors.green,
                    onTap: () async {
                      final Uri url = Uri(scheme: 'tel', path: '+918881188678');
                      try {
                        await launchUrl(url);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Dialer app')));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    context,
                    icon: Icons.email_rounded,
                    title: 'Email Us',
                    content: 'support@examinantt.com',
                    color: Colors.orange,
                    onTap: () async {
                      final Uri url = Uri(scheme: 'mailto', path: 'support@examinantt.com');
                      try {
                        await launchUrl(url);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Email app')));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    context,
                    icon: Icons.language_rounded,
                    title: 'Official Website',
                    content: 'https://www.examinantt.com',
                    color: const Color(0xFF0070F3),
                    onTap: () async {
                      final Uri url = Uri.parse('https://www.examinantt.com');
                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open browser')));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildContactCard(
                    context,
                    icon: Icons.location_on_rounded,
                    title: 'Visit Us',
                    content: 'Near BBAU, Lucknow, U.P., India - 226025',
                    color: Colors.pink,
                    onTap: () async {
                      final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=BBAU+Lucknow');
                      try {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Maps')));
                        }
                      }
                    },
                  ),
                ].animate().fade().slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final bodyTextColor = isDark ? AppColors.textDarkSecondary : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 14,
                      color: bodyTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white24 : Colors.grey.shade300, size: 16),
          ],
        ),
      ),
    );
  }
}
