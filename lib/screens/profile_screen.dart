import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';

// New Sub-screens
import 'my_preparation_screen.dart';
import 'my_learning_purchases_screen.dart';
import 'account_settings_screen.dart';
import 'preferences_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'about_examinantt_screen.dart';
import '../auth_screen/sign_up_login.dart';
import '../widgets/game_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../widgets/profile_avatar_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0E1A3D) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 14),
                    ),
                  ),
                  Text(
                    'Profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Row(
                    children: [
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          final isDarkMode = themeProvider.isDarkMode;
                          return GestureDetector(
                            onTap: () {
                              themeProvider.toggleTheme(!isDarkMode);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0E1A3D) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                              ),
                              child: Icon(
                                isDarkMode ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                                color: isDarkMode ? const Color(0xFFFFA000) : const Color(0xFF0F172A),
                                size: 16,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0E1A3D) : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                              ),
                              child: Icon(Icons.settings_outlined, color: textColor, size: 16),
                            ),
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Main User Profile Card
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.user;
                  final name = (user != null && user.name.trim().isNotEmpty)
                      ? user.name
                      : 'Student User';
                  final email = (user != null && user.email.trim().isNotEmpty)
                      ? user.email
                      : '';
                  final phone = (user != null && user.phone.trim().isNotEmpty)
                      ? user.phone
                      : 'Not provided';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFA000).withValues(alpha: isDark ? 0.03 : 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Watermark Shield Graphic on the background right
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Opacity(
                            opacity: isDark ? 0.05 : 0.03,
                            child: Icon(Icons.verified_user_rounded, size: 120, color: textColor),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Glowing Avatar Circle
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFFFA000).withValues(alpha: 0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    ProfileAvatarWidget(
                                      size: 72,
                                      initial: initial,
                                      showCameraIcon: false,
                                      isEditable: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // User information details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.verified_rounded, color: Color(0xFFFFA000), size: 16),
                                        ],
                                      ),
                                      Text(
                                        'Student',
                                        style: TextStyle(fontSize: 12, color: subColor),
                                      ),
                                      if (email.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.mail_outline_rounded, size: 12, color: subColor),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                email,
                                                style: TextStyle(fontSize: 11, color: subColor),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_android_rounded, size: 12, color: subColor),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              phone,
                                              style: TextStyle(fontSize: 11, color: subColor),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Badges & Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Free User Badge
                                const GamePulseBadge(
                                  label: 'FREE LEARNER',
                                  icon: Icons.military_tech_rounded,
                                  color: Color(0xFFFFA000),
                                ),
                                // Edit Profile Outline button
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFFFFA000)),
                                  label: const Text(
                                    'Edit Profile',
                                    style: TextStyle(fontSize: 12, color: Color(0xFFFFA000), fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFFFA000)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24, thickness: 1),
                            // Trusted by banner
                            Row(
                              children: [
                                const Icon(Icons.people_alt_outlined, color: Color(0xFFFFA000), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Trusted by ',
                                  style: TextStyle(fontSize: 11, color: subColor),
                                ),
                                const Text(
                                  '50K+ Students',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFFFA000)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),

              // Profile Stats Grid Card
              Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  final user = userProvider.user;
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirestoreService().getUserTestResultsStream(),
                    builder: (context, snapshot) {
                      final results = snapshot.data ?? [];
                      final summary = FirestoreService().calculateStatsFromResults(results, user);
                      final attemptedStr = summary.testsAttempted.toString();
                      final accuracyStr = '${summary.accuracy.toStringAsFixed(0)}%';

                      final int minutes = user?.totalStudyTimeMinutes ?? 120;
                      final studyTimeStr = '${minutes ~/ 60}h ${minutes % 60}m';
                      final streakStr = '${user?.currentStreak ?? 5} Days';

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatCol(context, 'Tests Attempted', attemptedStr, Icons.track_changes_rounded, const Color(0xFFFFA000)),
                            _buildStatDivider(),
                            _buildStatCol(context, 'Avg. Accuracy', accuracyStr, Icons.trending_up_rounded, const Color(0xFFFFA000)),
                            _buildStatDivider(),
                            _buildStatCol(context, 'Study Time', studyTimeStr, Icons.access_time_rounded, const Color(0xFFFFA000)),
                            _buildStatDivider(),
                            _buildStatCol(context, 'Current Streak', streakStr, Icons.local_fire_department_rounded, const Color(0xFFFFA000)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 24),

              // Settings/Options Listing Section
              Text(
                'Account & Options',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [

                  _buildNavigationMenuTile(
                    context,
                    title: 'My Preparation',
                    desc: 'Track and manage your target exams',
                    icon: Icons.school_outlined,
                    color: const Color(0xFF3B82F6),
                    destination: MyPreparationScreen(),
                  ),
                  _buildNavigationMenuTile(
                    context,
                    title: 'My Learning & Purchases',
                    desc: 'Batches, test series and study material',
                    icon: Icons.local_mall_outlined,
                    color: const Color(0xFF8B5CF6),
                    destination: MyLearningPurchasesScreen(),
                  ),
                  _buildNavigationMenuTile(
                    context,
                    title: 'Account Settings',
                    desc: 'Update profile details, Stream and Board info',
                    icon: Icons.manage_accounts_outlined,
                    color: const Color(0xFF10B981),
                    destination: AccountSettingsScreen(),
                  ),
                  _buildNavigationMenuTile(
                    context,
                    title: 'Preferences',
                    desc: 'Configure notifications, language and theme',
                    icon: Icons.tune_rounded,
                    color: const Color(0xFFFFA000),
                    destination: PreferencesScreen(),
                  ),
                  _buildNavigationMenuTile(
                    context,
                    title: 'Privacy & Security',
                    desc: 'Device access and details visibility settings',
                    icon: Icons.security_outlined,
                    color: const Color(0xFFEC4899),
                    destination: PrivacySecurityScreen(),
                  ),
                  _buildNavigationMenuTile(
                    context,
                    title: 'Help & Support',
                    desc: 'FAQs, contact chat, and tickets',
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xFF00C6FF),
                    destination: HelpSupportScreen(),
                  ),
                  _buildNavigationMenuTile(
                    context,
                    title: 'About Examinantt',
                    desc: 'Company information and terms of service',
                    icon: Icons.info_outline_rounded,
                    color: const Color(0xFF90A4AE),
                    destination: const AboutExaminanttScreen(),
                  ),
                  const SizedBox(height: 16),

                  // Still Need Help? Talk to our expert counsellor
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0A1E3C) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1B3B69) : const Color(0xFFBFDBFE),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0070F3).withValues(alpha: isDark ? 0.12 : 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0070F3).withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.headset_mic_rounded, color: Color(0xFF38BDF8), size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Still need help? Talk to our expert counsellor',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Get free 1-on-1 guidance for course & exam preparation',
                                    style: TextStyle(color: subColor, fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCounsellorBtn(
                                title: 'WhatsApp',
                                icon: Icons.chat_rounded,
                                color: const Color(0xFF25D366),
                                onTap: () => _openWhatsApp(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCounsellorBtn(
                                title: 'Call Us',
                                icon: Icons.call_rounded,
                                color: const Color(0xFF0070F3),
                                onTap: () => _openPhoneCall(context),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCounsellorBtn(
                                title: 'Email Us',
                                icon: Icons.email_rounded,
                                color: const Color(0xFFA855F7),
                                onTap: () => _openEmail(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Log Out Tile
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                      ),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text(
                        'Sign out of your Examinantt account',
                        style: TextStyle(color: Colors.redAccent, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent, size: 16),
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Delete Account Tile
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.shade700.withValues(alpha: 0.4),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_forever_rounded, color: Colors.red.shade400, size: 22),
                      ),
                      title: Text(
                        'Delete Account',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Permanently delete your account & data',
                        style: TextStyle(color: Colors.red.shade400, fontSize: 11),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.red.shade400, size: 16),
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3), width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Log Out',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your Examinantt account? You will need to sign in again to access your courses and test series.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.redAccent,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      await Provider.of<UserProvider>(context, listen: false).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  child: const Text('Yes, Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade700.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Confirm Account Deletion',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action CANNOT be undone. All your test attempts, statistics, purchases, and profile data will be permanently removed.',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.red.shade700,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      await Provider.of<UserProvider>(context, listen: false).logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  child: const Text('Yes, Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: subColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.grey.shade400.withValues(alpha: 0.2),
    );
  }

  Widget _buildNavigationMenuTile(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
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
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/919876543210?text=Hello%20Examinantt%20Team%2C%20I%20am%20a%20student%20and%20need%20academic%20counselling%20and%20guidance.');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
      if (context.mounted) {
        AppTheme.showSuccessSnackBar(context, 'WhatsApp: Contact +91 98765 43210');
      }
    }
  }

  Future<void> _openPhoneCall(BuildContext context) async {
    final uri = Uri.parse('tel:+919876543210');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Phone call launch error: $e');
      if (context.mounted) {
        AppTheme.showSuccessSnackBar(context, 'Admissions Desk: 1800-123-456 / +91 98765 43210');
      }
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:support@examinantt.com?subject=Student%20Counselling%20Inquiry');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Email launch error: $e');
      if (context.mounted) {
        AppTheme.showSuccessSnackBar(context, 'Email Support: support@examinantt.com');
      }
    }
  }

  Widget _buildCounsellorBtn({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

