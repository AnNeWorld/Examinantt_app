import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../auth_screen/sign_up_login.dart';
import 'about_us_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class AboutExaminanttScreen extends StatefulWidget {
  const AboutExaminanttScreen({super.key});

  @override
  State<AboutExaminanttScreen> createState() => _AboutExaminanttScreenState();
}

class _AboutExaminanttScreenState extends State<AboutExaminanttScreen> {
  void _showRatingDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int rating = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
              title: Text('Rate Examinantt', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Enjoying your learning journey? Rate your experience:'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starVal = index + 1;
                        return IconButton(
                          icon: Icon(
                            starVal <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFFFA000),
                            size: 36,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              rating = starVal;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Thank you for the $rating-star rating!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showShareDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text('Share App Link', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share Examinantt with your classmates and study groups:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131D38) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'https://examinantt.com/app',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFFFFA000), size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
              child: const Text('Done', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSocialsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text('Follow Us', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.telegram, color: Color(0xFF0088cc)),
                  title: const Text('Telegram Community'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating opening Telegram channel...')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library_rounded, color: Colors.red),
                  title: const Text('YouTube Channel'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating opening YouTube channel...')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C)),
                  title: const Text('Instagram Page'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulating opening Instagram...')));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWhatsNewDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text('What\'s New in v1.2.4', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Stateful dynamic settings for exam preparation.'),
                SizedBox(height: 6),
                Text('• Interactive mobile & email verification simulators.'),
                SizedBox(height: 6),
                Text('• Fully integrated live support chatbot assistant.'),
                SizedBox(height: 6),
                Text('• Smooth animations and dark mode refinements.'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
              child: const Text('Great!', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _deleteAccountDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: const Text('Delete Account Permanently?', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: const Text(
            'This action is irreversible. All of your mock tests, achievements, goals, and purchases will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Provider.of<UserProvider>(context, listen: false).logout();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account permanently deleted.')),
                );
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Examinantt',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFFFA000), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'About Examinantt',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Know more about us, our policies and your account.',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFFFFA000), size: 28),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            // Section 1: About & Policies Card
            _buildSectionHeader(context, 'About & Policies', Icons.shield_outlined, const Color(0xFF3B82F6)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildPolicyRow(
                    context,
                    title: 'About Us',
                    desc: 'Know our vision, mission and journey',
                    icon: Icons.info_outline_rounded,
                    color: const Color(0xFF3B82F6),
                    destination: const AboutUsScreen(),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildPolicyRow(
                    context,
                    title: 'Terms & Conditions',
                    desc: 'Read our terms and conditions',
                    icon: Icons.article_outlined,
                    color: const Color(0xFF3B82F6),
                    destination: const TermsConditionsScreen(),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildPolicyRow(
                    context,
                    title: 'Privacy Policy',
                    desc: 'Understand how we protect your data',
                    icon: Icons.security_outlined,
                    color: const Color(0xFF3B82F6),
                    destination: const PrivacyPolicyScreen(),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildPolicyRow(
                    context,
                    title: 'Refund Policy',
                    desc: 'Learn about refunds and cancellations',
                    icon: Icons.currency_exchange_rounded,
                    color: const Color(0xFF3B82F6),
                    destination: const Scaffold(body: Center(child: Text('Refund Policy'))),
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildPolicyRow(
                    context,
                    title: 'Community Guidelines',
                    desc: 'Guidelines for a safe and respectful community',
                    icon: Icons.people_outline_rounded,
                    color: const Color(0xFF3B82F6),
                    destination: const Scaffold(body: Center(child: Text('Community Guidelines'))),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Section 2: App & Community
            _buildSectionHeader(context, 'App & Community', Icons.star_border_rounded, const Color(0xFFFFA000)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                _buildCommunityCard(context, 'Rate Examinantt', 'Share your feedback on Play Store', Icons.star_rounded, const Color(0xFFFFA000), onTap: _showRatingDialog),
                _buildCommunityCard(context, 'Share Examinantt', 'Invite your friends and classmates', Icons.share_rounded, const Color(0xFF10B981), onTap: _showShareDialog),
                _buildCommunityCard(context, 'Follow Us', 'Stay updated on social media', Icons.favorite_rounded, Colors.redAccent, onTap: _showSocialsDialog),
                _buildCommunityCard(context, 'What\'s New', 'See the latest updates in app', Icons.notifications_active_rounded, const Color(0xFF00C6FF), onTap: _showWhatsNewDialog),
              ],
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Section 3: App Information Card
            _buildSectionHeader(context, 'App Information', Icons.developer_mode_outlined, const Color(0xFF8B5CF6)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: subColor, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'App Version',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Latest',
                          style: TextStyle(fontSize: 9, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('1.2.4', style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: subColor, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Last Updated',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                      Text('20 May 2024', style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Section 4: Actions (Log Out / Delete Account)
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                    ),
                    title: Text(
                      'Log Out',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    subtitle: Text(
                      'Sign out from your account',
                      style: TextStyle(fontSize: 10, color: subColor),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: subColor, size: 18),
                    onTap: () async {
                      Provider.of<UserProvider>(context, listen: false).logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 18),
                    ),
                    title: const Text(
                      'Delete Account',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    subtitle: Text(
                      'Permanently delete your account and all data',
                      style: TextStyle(fontSize: 10, color: Colors.red.withValues(alpha: 0.7)),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.red, size: 18),
                    onTap: _deleteAccountDialog,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Bottom trust banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D38) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_user_outlined, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your trust matters to us',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'We are committed to providing a safe, secure and seamless learning experience.',
                          style: TextStyle(fontSize: 10, color: subColor, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
        ),
      ],
    );
  }

  Widget _buildPolicyRow(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
      ),
      subtitle: Text(
        desc,
        style: TextStyle(fontSize: 10, color: subColor),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: subColor, size: 18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
    );
  }

  Widget _buildCommunityCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(fontSize: 8, color: subColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
