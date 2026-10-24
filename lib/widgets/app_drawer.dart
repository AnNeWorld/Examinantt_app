// ignore_for_file: unused_import, unused_element
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';

// Destination Screens
import '../utils/app_navigator.dart';
import '../screens/profile_screen.dart';
import '../screens/my_learning_purchases_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/doubts_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/pyqs_screen.dart';
import '../screens/current_affairs_screen.dart';
import '../screens/job_alerts_screen.dart';
import '../screens/account_settings_screen.dart';
import '../screens/certificate_verification_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/about_examinantt_screen.dart';
import '../screens/preferences_screen.dart';
import '../screens/notifications_screen.dart';
import '../models/notification_model.dart';
import '../auth_screen/sign_up_login.dart';

class AppDrawer extends StatelessWidget {
  final int? currentIndex;
  final void Function(int index)? onSelectTab;

  const AppDrawer({
    super.key,
    this.currentIndex,
    this.onSelectTab,
  });

  void _navigateToTab(BuildContext context, int tabIndex) {
    Navigator.of(context).pop(); // Close drawer
    if (onSelectTab != null) {
      onSelectTab!(tabIndex);
    }
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(context).pop(); // Close drawer
    AppNavigator.push(context, screen);
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF0F1E36) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Log Out',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out from Examinantt? You will need to sign in again to access your enrolled courses and tests.',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.of(context).pop(); // Close drawer
              final userProvider = Provider.of<UserProvider>(context, listen: false);
              await userProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Yes, Log Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final drawerBg = isDark ? const Color(0xFF071120) : Colors.white;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : AppColors.textLight;
    final dividerColor = isDark ? const Color(0xFF1A2840) : Colors.grey.shade200;

    final user = userProvider.user;
    final name = (user != null && user.name.trim().isNotEmpty) ? user.name : 'Examinantt Student';
    final email = (user != null && user.email.trim().isNotEmpty) ? user.email : '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    final selectedExam = userProvider.selectedExam;

    final drawerWidth = MediaQuery.of(context).size.width * 0.84;

    return Drawer(
      width: drawerWidth > 360 ? 360 : drawerWidth,
      backgroundColor: drawerBg,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          children: [
            // ================================================================
            // 1. TOP PREMIUM HEADER
            // ================================================================
            _buildDrawerHeader(
              context: context,
              isDark: isDark,
              name: name,
              email: email,
              initial: initial,
              selectedExam: selectedExam,
              userProvider: userProvider,
            ),

            // ================================================================
            // 2. SCROLLABLE MENU ITEMS
            // ================================================================
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                physics: const BouncingScrollPhysics(),
                children: [
                  // --- SECTION 1: PRIMARY TABS ---
                  _buildSectionHeader('EXPLORE & LEARN', secondaryTextColor),
                  _buildDrawerTile(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    subtitle: 'Dashboard, updates & live feeds',
                    isSelected: currentIndex == 0,
                    iconColor: const Color(0xFF3B82F6),
                    onTap: () => _navigateToTab(context, 0),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.school_rounded,
                    title: 'Batches & Courses',
                    subtitle: 'Live batches & full preparation',
                    isSelected: currentIndex == 1,
                    iconColor: const Color(0xFF10B981),
                    onTap: () => _navigateToTab(context, 1),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.assignment_rounded,
                    title: 'Test Series',
                    subtitle: 'Mock tests, chapter tests & PYQs',
                    isSelected: currentIndex == 2,
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () => _navigateToTab(context, 2),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.library_books_rounded,
                    title: 'Study Resources',
                    subtitle: 'Notes, formula sheets & PDFs',
                    isSelected: currentIndex == 3,
                    iconColor: const Color(0xFF8B5CF6),
                    onTap: () => _navigateToTab(context, 3),
                    isDark: isDark,
                  ),

                  Divider(color: dividerColor, height: 20),

                  // --- SECTION 2: MY LEARNING & TOOLS ---
                  _buildSectionHeader('MY LEARNING', secondaryTextColor),
                  _buildDrawerTile(
                    icon: Icons.shopping_bag_outlined,
                    title: 'My Purchases',
                    subtitle: 'Enrolled courses, tests & notes',
                    iconColor: const Color(0xFF06B6D4),
                    onTap: () => _navigateToScreen(context, const MyLearningPurchasesScreen()),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.history_edu_rounded,
                    title: 'PYQs (Previous Papers)',
                    subtitle: 'Previous year question papers',
                    iconColor: const Color(0xFF14B8A6),
                    onTap: () => _navigateToScreen(context, const PyqsScreen()),
                    isDark: isDark,
                  ),
                  StreamBuilder<List<NotificationModel>>(
                    stream: FirestoreService().getNotificationsStream(),
                    builder: (context, notifSnap) {
                      final count = notifSnap.data?.length ?? 0;
                      return _buildDrawerTile(
                        icon: Icons.notifications_active_outlined,
                        title: 'Notifications & Alerts',
                        subtitle: 'Important updates & reminders',
                        badge: count > 0 ? '$count' : null,
                        iconColor: const Color(0xFFF59E0B),
                        onTap: () => _navigateToScreen(context, const NotificationsScreen()),
                        isDark: isDark,
                      );
                    },
                  ),

                  /*
                  // DUMMY / COMING SOON LEARNING ITEMS COMMENTED OUT:
                  _buildDrawerTile(
                    icon: Icons.insights_rounded,
                    title: 'Performance & Analytics',
                    subtitle: 'Accuracy, speed & rank analysis',
                    iconColor: const Color(0xFFEC4899),
                    onTap: () => _navigateToScreen(context, const AnalyticsScreen()),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.contact_support_rounded,
                    title: 'Ask Doubts',
                    subtitle: 'Get answers from mentors',
                    badge: '24x7',
                    iconColor: const Color(0xFFF97316),
                    onTap: () => _navigateToScreen(context, const DoubtsScreen()),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Saved Bookmarks',
                    subtitle: 'Important questions & topics',
                    iconColor: const Color(0xFF6366F1),
                    onTap: () => _navigateToScreen(context, const BookmarksScreen()),
                    isDark: isDark,
                  ),

                  Divider(color: dividerColor, height: 20),

                  // --- SECTION 3: PREPARATION TOOLS ---
                  _buildSectionHeader('PREP TOOLS & ALERTS', secondaryTextColor),
                  _buildDrawerTile(
                    icon: Icons.newspaper_rounded,
                    title: 'Current Affairs',
                    subtitle: 'Daily updates & monthly digest',
                    badge: 'NEW',
                    iconColor: const Color(0xFF0EA5E9),
                    onTap: () => _navigateToScreen(context, const CurrentAffairsScreen()),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.campaign_rounded,
                    title: 'Job & Exam Alerts',
                    subtitle: 'Notifications & official updates',
                    iconColor: const Color(0xFFEAB308),
                    onTap: () => _navigateToScreen(context, const JobAlertsScreen()),
                    isDark: isDark,
                  ),
                  */

                  Divider(color: dividerColor, height: 20),

                  // --- SECTION 3: PREFERENCES & SUPPORT ---
                  _buildSectionHeader('SETTINGS & SUPPORT', secondaryTextColor),
                  
                  // Interactive Theme Switcher Tile
                  _buildThemeToggleTile(
                    context: context,
                    isDark: isDark,
                    themeProvider: themeProvider,
                  ),

                  _buildDrawerTile(
                    icon: Icons.headset_mic_rounded,
                    title: 'Help & Support',
                    subtitle: 'FAQs, live chat & assistance',
                    iconColor: const Color(0xFF38BDF8),
                    onTap: () => _navigateToScreen(context, const HelpSupportScreen()),
                    isDark: isDark,
                  ),

                  /*
                  // DUMMY / EXTRA SETTINGS COMMENTED OUT:
                  _buildDrawerTile(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Account Settings',
                    subtitle: 'Target exam, profile & boards',
                    iconColor: const Color(0xFF64748B),
                    onTap: () => _navigateToScreen(context, const AccountSettingsScreen()),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.tune_rounded,
                    title: 'App Preferences',
                    subtitle: 'Language, notifications & sounds',
                    iconColor: const Color(0xFF0284C7),
                    onTap: () => _navigateToScreen(context, const PreferencesScreen()),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.verified_user_rounded,
                    title: 'Verify Certificate',
                    subtitle: 'Check certificate authenticity',
                    iconColor: const Color(0xFF10B981),
                    onTap: () => _navigateToScreen(context, const CertificateVerificationScreen()),
                    isDark: isDark,
                  ),
                  _buildDrawerTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Examinantt',
                    subtitle: 'Vision, founders & policies',
                    iconColor: const Color(0xFF94A3B8),
                    onTap: () => _navigateToScreen(context, const AboutExaminanttScreen()),
                    isDark: isDark,
                  ),
                  */

                  const SizedBox(height: 12),
                ],
              ),
            ),

            // ================================================================
            // 3. BOTTOM FOOTER WITH LOGOUT & VERSION
            // ================================================================
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: dividerColor)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    onTap: () => _showLogoutDialog(context),
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    title: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Examinantt App • v1.2.7 • Education Redefined',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER WIDGET
  // ===========================================================================
  Widget _buildDrawerHeader({
    required BuildContext context,
    required bool isDark,
    required String name,
    required String email,
    required String initial,
    required String selectedExam,
    required UserProvider userProvider,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 14, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1E38) : AppColors.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar: App Logo + Title + Close Button
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/app_icon.png',
                  height: 26,
                  width: 26,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EXAMINANTT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Education Redefined',
                      style: TextStyle(
                        color: Color(0xFFFFA000),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                tooltip: 'Close menu',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // User Profile Row (Native app drawer style - no inner container box!)
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              if (onSelectTab != null) {
                onSelectTab!(4); // Switch to Profile tab
              } else {
                AppNavigator.push(context, const ProfileScreen());
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFFFA000),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFFFFA000),
                            size: 14,
                          ),
                        ],
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (selectedExam.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '🎯 $selectedExam',
                          style: const TextStyle(
                            color: Color(0xFFFFD54F),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white60,
                  size: 13,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTION HEADER
  // ===========================================================================
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 8, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
        ),
      ),
    );
  }

  // ===========================================================================
  // REUSABLE MENU TILE
  // ===========================================================================
  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
    bool isSelected = false,
    String? badge,
  }) {
    final activeBg = isDark ? const Color(0xFF14243F) : const Color(0xFFEFF6FF);

    return ListTile(
      onTap: onTap,
      dense: true,
      selected: isSelected,
      selectedTileColor: activeBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? AppColors.textDark : AppColors.text,
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? AppColors.textDarkSecondary : AppColors.textLight,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Icon(
            Icons.chevron_right_rounded,
            size: 17,
            color: isDark ? Colors.white30 : Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // THEME TOGGLE TILE
  // ===========================================================================
  Widget _buildThemeToggleTile({
    required BuildContext context,
    required bool isDark,
    required ThemeProvider themeProvider,
  }) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(
        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        color: isDark ? const Color(0xFFFFA000) : const Color(0xFFF59E0B),
        size: 22,
      ),
      title: Text(
        'Dark Mode',
        style: TextStyle(
          color: isDark ? AppColors.textDark : AppColors.text,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        isDark ? 'Dark theme enabled' : 'Light theme enabled',
        style: TextStyle(
          color: isDark ? AppColors.textDarkSecondary : AppColors.textLight,
          fontSize: 13,
        ),
      ),
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch.adaptive(
          value: isDark,
          activeTrackColor: AppColors.accent,
          activeThumbColor: Colors.white,
          onChanged: (val) {
            themeProvider.toggleTheme(val);
          },
        ),
      ),
      onTap: () {
        themeProvider.toggleTheme(!isDark);
      },
    );
  }
}
