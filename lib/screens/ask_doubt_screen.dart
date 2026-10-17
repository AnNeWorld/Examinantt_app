import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';

class AskDoubtScreen extends StatefulWidget {
  final String? initialSubject;

  const AskDoubtScreen({
    super.key,
    this.initialSubject,
  });

  @override
  State<AskDoubtScreen> createState() => _AskDoubtScreenState();
}

class _AskDoubtScreenState extends State<AskDoubtScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  late String _selectedSubject;
  bool _isPosting = false;

  final List<String> _subjects = [
    'Maths',
    'Physics',
    'Chemistry',
    'Biology',
    'Reasoning',
    'English',
    'General Awareness',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSubject = widget.initialSubject ?? _subjects.first;
    if (!_subjects.contains(_selectedSubject)) {
      _selectedSubject = _subjects.first;
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _submitDoubt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final question = _questionController.text.trim();
    final topic = _topicController.text.trim();

    setState(() => _isPosting = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final studentName = userProvider.user?.name ?? 'Student';
      final now = DateTime.now();
      final timeFormatted = DateFormat('dd MMM, hh:mm a').format(now);

      final docData = {
        'studentName': studentName,
        'subject': _selectedSubject,
        'topic': topic.isNotEmpty ? topic : _selectedSubject,
        'question': question,
        'isAnswered': false,
        'answersCount': 0,
        'time': timeFormatted,
        'answers': <Map<String, dynamic>>[],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('doubts').add(docData);

      if (mounted) {
        setState(() => _isPosting = false);
        Navigator.pop(context);
        AppTheme.showSuccessSnackBar(context, 'Doubt posted to forum successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        AppTheme.showWarningSnackBar(context, 'Failed to post doubt: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF071026) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final accentColor = const Color(0xFFFFA000);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Ask a Doubt',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderColor, height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F1E36) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school_rounded, color: Color(0xFF3B82F6), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Instant Faculty & Peer Guidance',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ask your question with step details to receive verified step-by-step solutions.',
                              style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Select Subject section
                Text(
                  'Select Subject',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _subjects.map((subject) {
                    final isSelected = _selectedSubject == subject;
                    return InkWell(
                      onTap: () {
                        setState(() => _selectedSubject = subject);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.15)
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? accentColor : borderColor,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(Icons.check_circle_rounded, color: accentColor, size: 14),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              subject,
                              style: TextStyle(
                                color: isSelected ? accentColor : textColor,
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Topic / Chapter Name
                Text(
                  'Topic / Chapter (Optional)',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _topicController,
                  style: TextStyle(color: textColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Thermodynamics, Trigonometry, Current Electricity',
                    hintStyle: TextStyle(color: subtitleColor, fontSize: 12.5),
                    fillColor: cardBg,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Question Details Input
                Text(
                  'Your Question / Doubt *',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _questionController,
                  minLines: 5,
                  maxLines: 10,
                  style: TextStyle(color: textColor, fontSize: 14, height: 1.4),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please write down your question or doubt';
                    }
                    if (value.trim().length < 5) {
                      return 'Please provide more details about your doubt (at least 5 characters)';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Type your question clearly...\n\nMention:\n• The specific step where you got stuck\n• Given values, formulas, or assumptions\n• Options if it is a multiple-choice question',
                    hintStyle: TextStyle(color: subtitleColor, fontSize: 12.5, height: 1.4),
                    fillColor: cardBg,
                    filled: true,
                    contentPadding: const EdgeInsets.all(16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Guidelines Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111D33) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: accentColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Tips for Faster Answers',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. State what topic the problem belongs to.\n2. Keep your question concise and easy to read.\n3. Be respectful and thank peers or teachers who answer.',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isPosting ? null : _submitDoubt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.black,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isPosting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 18, color: Colors.black),
                              SizedBox(width: 8),
                              Text(
                                'Post Doubt to Forum',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
