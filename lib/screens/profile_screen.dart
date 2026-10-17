import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../utils/app_navigator.dart';
import '../providers/user_provider.dart';
import '../providers/theme_provider.dart';
import '../services/analytics_service.dart';
import '../models/test_model.dart';

// New Sub-screens
import 'my_preparation_screen.dart';
import 'my_learning_purchases_screen.dart';
import 'account_settings_screen.dart';
import 'preferences_screen.dart';
import 'help_support_screen.dart';
import 'about_examinantt_screen.dart';
import 'notifications_screen.dart';
import '../widgets/notification_bell_action.dart';
import '../widgets/game_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../constants/app_fonts.dart';
import '../widgets/profile_avatar_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFFA000),
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 650));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                        border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                            blurRadius: 4,
                          ),
                        ],
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
                      Tooltip(
                        message: isDark ? 'Switch to White Mode' : 'Switch to Dark Mode',
                        child: GestureDetector(
                          onTap: () {
                            final nextModeIsDark = !isDark;
                            themeProvider.toggleTheme(nextModeIsDark);
                            AppTheme.showSuccessSnackBar(
                              context,
                              nextModeIsDark ? 'Dark Mode Activated 🌙' : 'White Mode Activated ☀️',
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0E1A3D) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.wb_sunny_rounded,
                              color: isDark ? const Color(0xFFFFA000) : const Color(0xFFF59E0B),
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      NotificationBellAction(
                        color: textColor,
                        size: 18,
                        padding: const EdgeInsets.all(4),
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              AppNavigator.push(
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
                                        style: AppTextStyles.bodySmall.copyWith(color: subColor),
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
                                    AppNavigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                                    );
                                  },
                                  icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFFFFA000)),
                                  label: Text(
                                    'Edit Profile',
                                    style: AppTextStyles.bodySmall.copyWith(color: const Color(0xFFFFA000), fontWeight: FontWeight.bold),
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
                  return StreamBuilder<List<TestResult>>(
                    stream: AnalyticsService().getUserTestResultsStream(user?.uid),
                    builder: (context, snapshot) {
                      final results = snapshot.data ?? [];
                      final overall = AnalyticsService().getOverallAnalytics(results);

                      final int testsCount = results.isNotEmpty
                          ? overall.totalTests
                          : (user?.testsAttempted ?? 0);
                      final String attemptedStr = testsCount.toString();

                      final double accuracyVal = results.isNotEmpty
                          ? overall.averageAccuracy
                          : (user?.accuracy != null && user!.accuracy > 0 ? user.accuracy : 0.0);
                      final String accuracyStr = '${accuracyVal.toStringAsFixed(0)}%';

                      final int studyTimeMinutes = results.isNotEmpty && overall.totalDurationSeconds > 0
                          ? (overall.totalDurationSeconds ~/ 60)
                          : (user?.totalStudyTimeMinutes ?? 0);
                      final String studyTimeStr = studyTimeMinutes >= 60
                          ? '${studyTimeMinutes ~/ 60}h ${studyTimeMinutes % 60}m'
                          : '${studyTimeMinutes}m';

                      final int streakVal = overall.currentStreakDays > 0
                          ? overall.currentStreakDays
                          : (user?.currentStreak ?? (testsCount > 0 ? 1 : 0));
                      final String streakStr = '$streakVal ${streakVal == 1 ? "Day" : "Days"}';

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
                    title: 'Notifications & Updates',
                    desc: 'View recent announcements, alerts and reminders',
                    icon: Icons.notifications_active_outlined,
                    color: const Color(0xFFF59E0B),
                    destination: const NotificationsScreen(),
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Get free 1-on-1 guidance for course & exam preparation',
                                    style: TextStyle(color: subColor, fontSize: 12.5),
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
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: subColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
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
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
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
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Text(
          desc,
          style: AppTextStyles.bodySmall.copyWith(color: subColor),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: subColor, size: 18),
        onTap: () {
          AppNavigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/918881188678?text=Hello%20Examinantt%20Team%2C%20I%20am%20a%20student%20and%20need%20academic%20counselling%20and%20guidance.');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('WhatsApp launch error: $e');
      if (context.mounted) {
        AppTheme.showSuccessSnackBar(context, 'WhatsApp: Contact +91 8881188678');
      }
    }
  }

  Future<void> _openPhoneCall(BuildContext context) async {
    final uri = Uri.parse('tel:+918881188678');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Phone call launch error: $e');
      if (context.mounted) {
        AppTheme.showSuccessSnackBar(context, 'Admissions Desk: +91 8881188678');
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
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

