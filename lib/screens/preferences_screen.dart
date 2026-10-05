import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  // Local state representing preferences values
  bool liveClassReminders = true;
  bool testSeriesReminders = true;
  bool dailyGoalReminders = true;
  bool doubtReplies = true;

  String appLanguage = 'English';
  String studyGoal = 'Concept Mastery';
  String testMode = 'Standard Timed';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() {
    setState(() => isLoading = false);
  }

  void _savePreference(String key, dynamic value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${key.replaceAll(RegExp(r'(?=[A-Z])'), ' ')} updated successfully!'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFFFFA000),
      ),
    );
  }

  void _showOptionsBottomSheet({
    required String title,
    required String fieldKey,
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
                        _savePreference(fieldKey, opt);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Preferences',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFA000)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTIFICATIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.blueAccent[100]! : Colors.blueAccent,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: 'Live Class Alerts',
                          subtitle: 'Get notified when your classes go live',
                          value: liveClassReminders,
                          icon: Icons.live_tv_rounded,
                          color: Colors.green,
                          onChanged: (val) {
                            setState(() => liveClassReminders = val);
                            _savePreference('liveClassReminders', val);
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          title: 'Test Series Reminders',
                          subtitle: 'Reminders for upcoming test series schedules',
                          value: testSeriesReminders,
                          icon: Icons.quiz_outlined,
                          color: Colors.blue,
                          onChanged: (val) {
                            setState(() => testSeriesReminders = val);
                            _savePreference('testSeriesReminders', val);
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          title: 'Daily Goal Notifications',
                          subtitle: 'Stay on track with daily learning challenges',
                          value: dailyGoalReminders,
                          icon: Icons.ads_click_rounded,
                          color: Colors.orange,
                          onChanged: (val) {
                            setState(() => dailyGoalReminders = val);
                            _savePreference('dailyGoalReminders', val);
                          },
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          title: 'Doubt Forum Updates',
                          subtitle: 'Notifications when your doubts are answered',
                          value: doubtReplies,
                          icon: Icons.question_answer_outlined,
                          color: Colors.purple,
                          onChanged: (val) {
                            setState(() => doubtReplies = val);
                            _savePreference('doubtReplies', val);
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  
                  const SizedBox(height: 24),

                  Text(
                    'APPEARANCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.blueAccent[100]! : Colors.blueAccent,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                    ),
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, _) {
                        return _buildSwitchTile(
                          title: 'White / Light Mode',
                          subtitle: themeProvider.isDarkMode
                              ? 'Currently Dark Mode. Turn ON for White Mode'
                              : 'White Mode is active. Turn OFF for Dark Mode',
                          value: !themeProvider.isDarkMode,
                          icon: !themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: const Color(0xFFFFA000),
                          onChanged: (val) {
                            themeProvider.toggleTheme(!val);
                          },
                        );
                      },
                    ),
                  ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'LEARNING PREFERENCES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.blueAccent[100]! : Colors.blueAccent,
                      letterSpacing: 1.2,
                    ),
                  ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildPreferenceTile(
                          title: 'Study Language',
                          value: appLanguage,
                          icon: Icons.translate_rounded,
                          color: Colors.teal,
                          onTap: () {
                            _showOptionsBottomSheet(
                              title: 'Choose Study Language',
                              fieldKey: 'appLanguage',
                              options: ['English', 'Hindi', 'Hinglish'],
                              currentValue: appLanguage,
                              onSelected: (val) => setState(() => appLanguage = val),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildPreferenceTile(
                          title: 'Learning Goal priority',
                          value: studyGoal,
                          icon: Icons.military_tech_outlined,
                          color: Colors.amber,
                          onTap: () {
                            _showOptionsBottomSheet(
                              title: 'Set Goal Priority',
                              fieldKey: 'studyGoal',
                              options: ['Concept Mastery', 'Rank Improvement', 'Board Exam Prep', 'Speed Practice'],
                              currentValue: studyGoal,
                              onSelected: (val) => setState(() => studyGoal = val),
                            );
                          },
                        ),
                        const Divider(height: 1),
                        _buildPreferenceTile(
                          title: 'Preferred Test Mode',
                          value: testMode,
                          icon: Icons.timer_outlined,
                          color: Colors.red,
                          onTap: () {
                            _showOptionsBottomSheet(
                              title: 'Select Preferred Test Mode',
                              fieldKey: 'testMode',
                              options: ['Standard Timed', 'Practice Untimed', 'Section Wise Timer'],
                              currentValue: testMode,
                              onSelected: (val) => setState(() => testMode = val),
                            );
                          },
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          liveClassReminders = true;
                          testSeriesReminders = true;
                          dailyGoalReminders = true;
                          doubtReplies = true;
                          appLanguage = 'English';
                          studyGoal = 'Concept Mastery';
                          testMode = 'Standard Timed';
                        });
                        AppTheme.showSuccessSnackBar(context, 'Preferences reset to defaults.');
                      },
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text(
                        'RESET PREFERENCES',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 450.ms),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFFFFA000),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: subColor)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildPreferenceTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return ListTile(
      onTap: onTap,
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFA000),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, color: subColor, size: 20),
        ],
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}