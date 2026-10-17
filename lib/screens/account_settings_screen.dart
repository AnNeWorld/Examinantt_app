import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../widgets/profile_avatar_widget.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../widgets/notification_bell_action.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  String fullName = '';
  String dob = '21 May 2005';
  String gender = 'Male';
  String phoneNumber = '';
  String emailAddress = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    final prefs = await SharedPreferences.getInstance();
    final savedDob = prefs.getString('user_dob');
    final savedGender = prefs.getString('user_gender');

    if (mounted) {
      setState(() {
        if (user != null) {
          fullName = user.name.isNotEmpty ? user.name : 'Student User';
          emailAddress = user.email;
          phoneNumber = user.phone;
        }
        if (savedDob != null && savedDob.isNotEmpty) {
          dob = savedDob;
        }
        if (savedGender != null && savedGender.isNotEmpty) {
          gender = savedGender;
        }
      });
    }
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialName: fullName,
          initialDob: dob,
          initialGender: gender,
          initialPhone: phoneNumber,
          initialEmail: emailAddress,
        ),
      ),
    );

    if (result != null && mounted) {
      await _loadUserData();
    }
  }

  void _openChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 18,
          ),
        ),
        actions: [
          NotificationBellAction(color: textColor),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Edit Profile Card
            _buildSectionHeader(
              context,
              'Edit Profile',
              Icons.person_outline_rounded,
              actionLabel: 'Edit',
              onAction: _openEditProfile,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _openEditProfile,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Column(
                      children: [
                        ProfileAvatarWidget(
                          size: 78,
                          initial: fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'A',
                          onImageChanged: _loadUserData,
                        ),
                        const SizedBox(height: 8),
                        Text('JPG, PNG or WebP', style: TextStyle(fontSize: 12, color: subColor)),
                        Text('Max size 2MB', style: TextStyle(fontSize: 12, color: subColor)),
                      ],
                    ),
                    const SizedBox(width: 18),
                    // User details column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileField('Full Name', fullName, textColor, subColor, isVerified: true),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _buildProfileField('Date of Birth', dob, textColor, subColor)),
                              Expanded(child: _buildProfileField('Gender', gender, textColor, subColor)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildProfileField('Phone Number', phoneNumber.isNotEmpty ? phoneNumber : 'Not Set', textColor, subColor),
                          const SizedBox(height: 12),
                          _buildProfileField('Email Address', emailAddress.isNotEmpty ? emailAddress : 'Not Set', textColor, subColor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 50.ms, duration: 350.ms),
            const SizedBox(height: 24),

            // Section 2: Change Password Card
            _buildSectionHeader(
              context,
              'Change Password',
              Icons.lock_outline_rounded,
              actionLabel: 'Change',
              onAction: _openChangePassword,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _openChangePassword,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPasswordStep(
                        context,
                        'Current Password',
                        '••••••••',
                        Icons.key_outlined,
                        const Color(0xFF3B82F6),
                      ),
                    ),
                    _buildStepDivider(),
                    Expanded(
                      child: _buildPasswordStep(
                        context,
                        'New Password',
                        '••••••••',
                        Icons.shield_outlined,
                        const Color(0xFF10B981),
                      ),
                    ),
                    _buildStepDivider(),
                    Expanded(
                      child: _buildPasswordStep(
                        context,
                        'Confirm Password',
                        '••••••••',
                        Icons.shield_outlined,
                        const Color(0xFFFFA000),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String label,
    IconData icon, {
    String actionLabel = 'Edit',
    VoidCallback? onAction,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFFFFA000), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        if (onAction != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Color(0xFFFFA000),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFA000), size: 18),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileField(
    String label,
    String value,
    Color textColor,
    Color subColor, {
    bool isVerified = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.5, color: subColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(Icons.verified_rounded, color: Color(0xFFFFA000), size: 14),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordStep(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 16,
      height: 1,
      color: Colors.grey.shade400.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 24),
    );
  }
}
