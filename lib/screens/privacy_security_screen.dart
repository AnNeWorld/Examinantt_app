import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool twoFactorAuth = false;
  String profileVisibility = 'Friends Only';
  List<String> activeDevices = ['OnePlus 11', 'HP Laptop (Windows 11)'];

  @override
  void initState() {
    super.initState();
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
                  onTap: () {
                    onSelected(opt);
                    Navigator.pop(context);
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

  void _showLoginActivitySheet() {
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
              Text(
                'Recent Login Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.android_rounded, color: Colors.green),
                title: Text('Android App - New Delhi, India'),
                subtitle: Text('Active now • OnePlus 11'),
              ),
              const ListTile(
                leading: Icon(Icons.laptop_chromebook_rounded, color: Colors.blue),
                title: Text('Chrome Browser - Delhi, India'),
                subtitle: Text('2 hours ago • Windows PC'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    },
  );
  }

  void _showManageDevicesSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                  Text(
                    'Manage Active Devices',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                  const Divider(),
                  if (activeDevices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No active devices listed.'),
                    )
                  else
                    ...List.generate(activeDevices.length, (idx) {
                      final dev = activeDevices[idx];
                      return ListTile(
                        leading: Icon(dev.contains('OnePlus') ? Icons.phone_android_rounded : Icons.computer_rounded),
                        title: Text(dev),
                        subtitle: Text(idx == 0 ? 'Primary Device' : 'Authorized Device'),
                        trailing: idx == 0
                            ? null
                            : TextButton(
                                onPressed: () {
                                  setState(() {
                                    activeDevices.removeAt(idx);
                                  });
                                  setSheetState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Logged out of $dev')),
                                  );
                                },
                                child: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
                              ),
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
  },
);
  }

  void _showDataPrivacySheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text('Data & Privacy Info', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: Text(
            'We value your privacy. We process personal details strictly to personalize your learnings, improve practice recommendations, and manage mock test scores. Your information is never sold to third parties.',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _downloadDataSimulation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && dialogCtx.mounted) {
            Navigator.pop(dialogCtx);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your data report is generated. Download started!')),
            );
          }
        });
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFFFFA000)),
              SizedBox(width: 20),
              Text('Generating report...'),
            ],
          ),
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
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account permanently deleted.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _learnMoreDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text('Security Tips', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Use a complex password containing numbers & special characters.'),
                SizedBox(height: 6),
                Text('• Avoid sharing your account with others.'),
                SizedBox(height: 6),
                Text('• Enable two-factor authentication for extra protection.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done', style: TextStyle(color: Color(0xFFFFA000))),
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
          'Privacy & Security',
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
                            const Icon(Icons.verified_user_outlined, color: Color(0xFFFFA000), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Privacy & Security',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Manage your account security and control your data & privacy.',
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
                    child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF3B82F6), size: 28),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            // Section 1: Account Security
            _buildSectionHeader('Account Security', Icons.security_rounded, const Color(0xFF3B82F6)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSecurityRow(
                    context,
                    title: 'Change Password',
                    desc: 'Update your password regularly',
                    icon: Icons.lock_outline_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: _changePasswordDialog,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSecurityRow(
                    context,
                    title: 'Login Activity',
                    desc: 'See recent logins and account activity',
                    icon: Icons.history_toggle_off_rounded,
                    color: const Color(0xFF3B82F6),
                    onTap: _showLoginActivitySheet,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSecurityRow(
                    context,
                    title: 'Manage Devices',
                    desc: 'Manage devices where you\'re logged in',
                    icon: Icons.important_devices_rounded,
                    color: const Color(0xFF3B82F6),
                    badge: '${activeDevices.length} Active',
                    badgeColor: const Color(0xFF3B82F6),
                    onTap: _showManageDevicesSheet,
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    value: twoFactorAuth,
                    onChanged: (val) {
                      setState(() {
                        twoFactorAuth = val;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(val ? '2FA Enabled!' : '2FA Disabled.')),
                      );
                    },
                    activeThumbColor: const Color(0xFFFFA000),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 18),
                    ),
                    title: Row(
                      children: [
                        Text(
                          'Two-Factor Authentication',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Recommended',
                            style: TextStyle(fontSize: 8, color: Color(0xFFFFA000), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      'Add an extra layer of security to your account',
                      style: TextStyle(fontSize: 10, color: subColor),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Section 2: Privacy & Data Card
            _buildSectionHeader('Privacy & Data', Icons.privacy_tip_outlined, const Color(0xFF10B981)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildSecurityRow(
                    context,
                    title: 'Profile Visibility',
                    desc: 'Choose who can see your profile information',
                    icon: Icons.visibility_outlined,
                    color: const Color(0xFF10B981),
                    badge: profileVisibility,
                    badgeColor: const Color(0xFF10B981),
                    onTap: () {
                      _showOptionsBottomSheet(
                        title: 'Profile Visibility',
                        options: ['Public', 'Friends Only', 'Private'],
                        currentValue: profileVisibility,
                        onSelected: (val) {
                          setState(() => profileVisibility = val);
                        },
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSecurityRow(
                    context,
                    title: 'Data & Privacy',
                    desc: 'Manage how your data is used and protected',
                    icon: Icons.key_outlined,
                    color: const Color(0xFF10B981),
                    onTap: _showDataPrivacySheet,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSecurityRow(
                    context,
                    title: 'Download My Data',
                    desc: 'Download a copy of your account data',
                    icon: Icons.file_download_outlined,
                    color: const Color(0xFF10B981),
                    onTap: _downloadDataSimulation,
                  ),
                  const Divider(height: 1, indent: 56),
                  _buildSecurityRow(
                    context,
                    title: 'Delete Account',
                    desc: 'Permanently delete your account and all data',
                    icon: Icons.delete_forever_rounded,
                    color: Colors.red,
                    isDanger: true,
                    onTap: _deleteAccountDialog,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
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
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF3B82F6), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your security is our priority',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'We use industry-standard encryption and security practices to keep your data safe.',
                          style: TextStyle(fontSize: 10, color: subColor, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check, color: Color(0xFF10B981), size: 10),
                        SizedBox(width: 4),
                        Text(
                          'Secure',
                          style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 16),

            // Bottom tip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFA000), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Security Tip: Never share your password with anyone. Examinantt will never ask for your password.',
                      style: TextStyle(fontSize: 10, color: textColor, height: 1.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _learnMoreDialog,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Row(
                      children: [
                        Text('Learn more', style: TextStyle(color: Color(0xFFFFA000), fontSize: 10, fontWeight: FontWeight.bold)),
                        Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFA000), size: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String label, IconData icon, Color color) {
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

  Widget _buildSecurityRow(
    BuildContext context, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    String badge = '',
    Color badgeColor = Colors.grey,
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDanger ? Colors.red : (isDark ? Colors.white : Colors.black87);
    final subColor = isDanger ? Colors.red.withValues(alpha: 0.7) : (isDark ? Colors.white54 : Colors.black54);

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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.chevron_right_rounded, color: subColor, size: 18),
        ],
      ),
      onTap: onTap,
    );
  }
}
