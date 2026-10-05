import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/profile_avatar_widget.dart';

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

  String className = '12th';
  String boardName = 'CBSE';
  String streamName = 'PCM';
  String targetYear = '2027';

  bool isMobileVerified = true;
  bool isEmailVerified = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user != null) {
      setState(() {
        fullName = user.name.isNotEmpty ? user.name : 'Student User';
        emailAddress = user.email;
        phoneNumber = user.phone;
      });
    }
  }

  void _showOptionsBottomSheet({
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...options.map((opt) {
                    final isSelected = opt == currentValue;
                    return ListTile(
                      title: Text(
                        opt,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFFA000)
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFFFFA000))
                          : null,
                      onTap: () async {
                        onSelected(opt);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$title updated successfully!')),
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _editProfile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: fullName);
    final dobController = TextEditingController(text: dob);
    final genderController = TextEditingController(text: gender);
    final phoneController = TextEditingController(text: phoneNumber);
    final emailController = TextEditingController(text: emailAddress);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text(
            'Edit Profile Info',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                TextField(
                  controller: dobController,
                  decoration: const InputDecoration(labelText: 'Date of Birth'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                TextField(
                  controller: genderController,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text;
                final newEmail = emailController.text;
                final newPhone = phoneController.text;
                final newDob = dobController.text;
                final newGender = genderController.text;

                setState(() {
                  fullName = newName;
                  dob = newDob;
                  gender = newGender;
                  phoneNumber = newPhone;
                  emailAddress = newEmail;
                });
                Navigator.pop(context);

                Provider.of<UserProvider>(context, listen: false).updateProfile(newName, newEmail, newPhone);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile details updated successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _changePasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text(
            'Change Password',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current Password'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                TextField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New Password'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newController.text != confirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match!')),
                  );
                  return;
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000),
              ),
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showOTPVerificationSimulation(String contactType, String destination, VoidCallback onVerified) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final otpController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text(
            'Verify $contactType',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We\'ve sent a 4-digit code to $destination. Enter it below to verify.',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                maxLength: 4,
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '0000',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (otpController.text.length == 4) {
                  onVerified();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$contactType verified successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid 4-digit code.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA000),
              ),
              child: const Text('Verify', style: TextStyle(color: Colors.white)),
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
          'Account Settings',
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
                            const Icon(Icons.manage_accounts_outlined, color: Color(0xFFFFA000), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Account Settings',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your personal information and account preferences.',
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
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 28),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            // Section 1: Edit Profile Card
            _buildSectionHeader(context, 'Edit Profile', Icons.person_outline_rounded, onAction: _editProfile),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Section
                  Column(
                    children: [
                      ProfileAvatarWidget(
                        size: 80,
                        initial: fullName.trim().isNotEmpty ? fullName.trim()[0].toUpperCase() : 'A',
                      ),
                      const SizedBox(height: 12),
                      Text('JPG, PNG or WebP', style: TextStyle(fontSize: 9, color: subColor)),
                      Text('Max size 2MB', style: TextStyle(fontSize: 9, color: subColor)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // User details column
                  Expanded(
                    child: InkWell(
                      onTap: _editProfile,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
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
                            _buildProfileField('Phone Number', phoneNumber, textColor, subColor),
                            const SizedBox(height: 12),
                            _buildProfileField('Email Address', emailAddress, textColor, subColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Section 2: Academic Information Card
            _buildSectionHeader(
              context,
              'Academic Information',
              Icons.school_outlined,
              onAction: () {
                _showOptionsBottomSheet(
                  title: 'Select Class',
                  options: ['9th', '10th', '11th', '12th', 'Dropper'],
                  currentValue: className,
                  onSelected: (val) => setState(() => className = val),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAcademicItem(
                    context,
                    'Class',
                    className,
                    Icons.article_outlined,
                    const Color(0xFFFFA000),
                    onTap: () {
                      _showOptionsBottomSheet(
                        title: 'Select Class',
                        options: ['9th', '10th', '11th', '12th', 'Dropper'],
                        currentValue: className,
                        onSelected: (val) => setState(() => className = val),
                      );
                    },
                  ),
                  _buildAcademicItem(
                    context,
                    'Board',
                    boardName,
                    Icons.corporate_fare_rounded,
                    const Color(0xFF8B5CF6),
                    onTap: () {
                      _showOptionsBottomSheet(
                        title: 'Select Board',
                        options: ['CBSE', 'ICSE', 'State Board', 'IB'],
                        currentValue: boardName,
                        onSelected: (val) => setState(() => boardName = val),
                      );
                    },
                  ),
                  _buildAcademicItem(
                    context,
                    'Stream',
                    streamName,
                    Icons.category_outlined,
                    const Color(0xFF00C6FF),
                    onTap: () {
                      _showOptionsBottomSheet(
                        title: 'Select Stream',
                        options: ['PCM', 'PCB', 'Commerce', 'Arts'],
                        currentValue: streamName,
                        onSelected: (val) => setState(() => streamName = val),
                      );
                    },
                  ),
                  _buildAcademicItem(
                    context,
                    'Target Year',
                    targetYear,
                    Icons.calendar_month_outlined,
                    const Color(0xFFEC4899),
                    onTap: () {
                      _showOptionsBottomSheet(
                        title: 'Select Target Year',
                        options: ['2025', '2026', '2027', '2028', '2029', '2030'],
                        currentValue: targetYear,
                        onSelected: (val) => setState(() => targetYear = val),
                      );
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Section 3: Change Password Card
            _buildSectionHeader(context, 'Change Password', Icons.lock_outline_rounded, actionLabel: 'Change', onAction: _changePasswordDialog),
            const SizedBox(height: 12),
            InkWell(
              onTap: _changePasswordDialog,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildPasswordStep(context, 'Current Password', '••••••••', Icons.key_outlined, const Color(0xFF3B82F6))),
                    _buildStepDivider(),
                    Expanded(child: _buildPasswordStep(context, 'New Password', '••••••••', Icons.shield_outlined, const Color(0xFF10B981))),
                    _buildStepDivider(),
                    Expanded(child: _buildPasswordStep(context, 'Confirm Password', '••••••••', Icons.shield_outlined, const Color(0xFFFFA000))),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Section 4: Mobile & Email Verification
            _buildSectionHeader(context, 'Mobile & Email', Icons.mark_chat_read_outlined),
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
                  _buildVerificationRow(
                    context,
                    title: 'Mobile Number',
                    value: phoneNumber,
                    icon: Icons.phone_android_rounded,
                    color: isMobileVerified ? const Color(0xFF10B981) : Colors.redAccent,
                    isVerified: isMobileVerified,
                    onUpdate: () {
                      _showOTPVerificationSimulation('Mobile Number', phoneNumber, () async {
                        setState(() {
                          isMobileVerified = true;
                        });
                      });
                    },
                  ),
                  const Divider(height: 24),
                  _buildVerificationRow(
                    context,
                    title: 'Email Address',
                    value: emailAddress,
                    icon: Icons.mail_outline_rounded,
                    color: isEmailVerified ? const Color(0xFF10B981) : Colors.redAccent,
                    isVerified: isEmailVerified,
                    onUpdate: () {
                      _showOTPVerificationSimulation('Email Address', emailAddress, () async {
                        setState(() {
                          isEmailVerified = true;
                        });
                      });
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 24),


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
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(actionLabel, style: const TextStyle(color: Color(0xFFFFA000), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFA000), size: 14),
              ],
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
          style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
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

  Widget _buildAcademicItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: subColor),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
      ),
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
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: subColor, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
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

  Widget _buildVerificationRow(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isVerified,
    required VoidCallback onUpdate,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: subColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 10, color: subColor)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(isVerified ? Icons.check : Icons.close, color: color, size: 10),
              const SizedBox(width: 4),
              Text(
                isVerified ? 'Verified' : 'Unverified',
                style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: onUpdate,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Row(
            children: [
              Text('Update', style: TextStyle(color: Color(0xFFFFA000), fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFFFA000), size: 12),
            ],
          ),
        ),
      ],
    );
  }
}
