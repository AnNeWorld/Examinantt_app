import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../auth_screen/sign_up_login.dart';
import 'edit_profile_screen.dart';
import 'my_purchases_screen.dart';
import 'bookmarks_screen.dart';
import 'notifications_screen.dart';
import 'change_password_screen.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';
import 'privacy_policy_screen.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Row(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  'S',
                  style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Name',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'student@examinantt.com',
                    style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Free User',
                      style: TextStyle(color: AppTheme.secondaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Dashboard Stats
          const Text(
            'My Dashboard',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('Tests Attempted', '12', Icons.assignment_turned_in, Colors.green),
              const SizedBox(width: 16),
              _buildStatCard('Avg. Accuracy', '78%', Icons.pie_chart, AppTheme.secondaryColor),
            ],
          ),
          const SizedBox(height: 32),

          // Settings Options
          const Text(
            'Account & Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(context, Icons.person_outline, 'Edit Profile', const EditProfileScreen()),
          _buildSettingsTile(context, Icons.shopping_bag_outlined, 'My Purchases', const MyPurchasesScreen()),
          _buildSettingsTile(context, Icons.bookmark_border, 'Bookmarks', const BookmarksScreen()),
          _buildSettingsTile(context, Icons.notifications_outlined, 'Notifications', const NotificationsScreen()),
          _buildSettingsTile(context, Icons.lock_outline, 'Change Password', const ChangePasswordScreen()),
          
          const SizedBox(height: 24),
          const Text(
            'About & Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
          ),
          const SizedBox(height: 16),
          _buildSettingsTile(context, Icons.info_outline, 'About Us', const AboutUsScreen()),
          _buildSettingsTile(context, Icons.contact_support_outlined, 'Contact Us', const ContactUsScreen()),
          _buildSettingsTile(context, Icons.privacy_tip_outlined, 'Privacy Policy', const PrivacyPolicyScreen()),
          _buildSettingsTile(context, Icons.description_outlined, 'Terms & Conditions', const PlaceholderScreen(title: 'Terms & Conditions')),
          
          const SizedBox(height: 24),
          ListTile(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ].animate(interval: 50.ms).fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, Widget destination) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Center(
        child: Text('$title content will appear here.', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.5))),
      ),
    );
  }
}
