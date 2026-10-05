import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';

class DoubtsScreen extends StatefulWidget {
  const DoubtsScreen({super.key});

  @override
  State<DoubtsScreen> createState() => _DoubtsScreenState();
}

class _DoubtsScreenState extends State<DoubtsScreen> {
  final TextEditingController _doubtController = TextEditingController();
  String _selectedSubject = 'Maths';
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  


  void _askDoubt() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
        final textColor = isDark ? AppColors.textDark : AppTheme.darkSlate;
        final secondaryTextColor = isDark ? AppColors.textDarkSecondary : Colors.grey;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: cardColor,
              title: Text('Ask a Doubt', style: TextStyle(color: textColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      dropdownColor: cardColor,
                      initialValue: _selectedSubject,
                      style: TextStyle(color: textColor),
                      items: ['Maths', 'Reasoning', 'English', 'General Awareness']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: textColor))))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          _selectedSubject = val!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        labelStyle: TextStyle(color: secondaryTextColor),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: secondaryTextColor.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _doubtController,
                      maxLines: 4,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Type your question here...',
                        hintStyle: TextStyle(color: secondaryTextColor),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: secondaryTextColor.withValues(alpha: 0.5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: isDark ? AppColors.accent : AppTheme.primaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: isDark ? AppColors.accent : AppTheme.primaryColor)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_doubtController.text.trim().isNotEmpty) {
                      final userProvider = Provider.of<UserProvider>(context, listen: false);
                      final studentName = userProvider.user?.name ?? 'Student';
                      final text = _doubtController.text.trim();
                      final now = DateTime.now();
                      final timeFormatted = DateFormat('dd MMM, hh:mm a').format(now);
                      final docData = {
                        'studentName': studentName,
                        'subject': _selectedSubject,
                        'question': text,
                        'isAnswered': false,
                        'answersCount': 0,
                        'time': timeFormatted,
                        'answers': <Map<String, dynamic>>[],
                        'createdAt': FieldValue.serverTimestamp(),
                      };

                      try {
                        await _db.collection('doubts').add(docData);
                      } catch (e) {
                        debugPrint("Error saving doubt to Firestore: $e");
                      }

                      _doubtController.clear();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Doubt posted successfully!'),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                  ),
                  child: const Text('Post', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textDark : AppTheme.darkSlate;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Doubt Forum', style: TextStyle(fontSize: 18, color: textColor)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Ask a doubt CTA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.greyDark : AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.accent : AppTheme.primaryColor).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.psychology_alt,
                      color: isDark ? AppColors.accent : AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stuck on a question?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ask our experts and get solutions quickly.',
                          style: TextStyle(color: secondaryTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _askDoubt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Ask',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideY(begin: 0.1),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('doubts').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> doubtsList = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  doubtsList = snapshot.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return {'id': doc.id, ...d};
                  }).toList();
                } else {
                  doubtsList = [];
                }

                if (doubtsList.isEmpty) {
                  return Center(
                    child: Text(
                      'No doubts posted yet. Be the first to ask!',
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: doubtsList.length,
                  itemBuilder: (context, index) {
                    final doubt = doubtsList[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildDoubtCard(
                        doubt: doubt,
                        isDark: isDark,
                        cardColor: cardColor,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    );
                  },
                ).animate().fade().slideY(begin: 0.1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoubtCard({
    required Map<String, dynamic> doubt,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final String studentName = doubt['studentName'] ?? 'Student';
    DateTime? doubtDate;
    if (doubt['createdAt'] is Timestamp) {
      doubtDate = (doubt['createdAt'] as Timestamp).toDate();
    } else if (doubt['createdAt'] is String) {
      doubtDate = DateTime.tryParse(doubt['createdAt'] as String);
    }
    String time = doubt['time'] ?? '';
    if (doubtDate != null) {
      time = DateFormat('dd MMM, hh:mm a').format(doubtDate);
    } else if (time.isEmpty || time == 'Just now') {
      time = DateFormat('dd MMM, hh:mm a').format(DateTime.now());
    }
    final String subject = doubt['subject'] ?? '';
    final String question = doubt['question'] ?? '';
    final bool isAnswered = doubt['isAnswered'] ?? false;
    final int answersCount = doubt['answersCount'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoubtDetailScreen(
              doubt: doubt,
              onAnswerAdded: (newAnswer) {
                setState(() {
                  doubt['answers'].add(newAnswer);
                  doubt['answersCount'] = doubt['answers'].length;
                  doubt['isAnswered'] = true;
                });
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: isDark ? Border.all(color: AppColors.greyDark.withValues(alpha: 0.5)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isDark ? AppColors.backgroundDark : Colors.grey[200],
                        child: Text(
                          studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              time,
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    subject,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? AppColors.greyDark : Colors.grey[200]),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isAnswered ? Icons.check_circle : Icons.help_outline,
                      color: isAnswered ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAnswered ? '$answersCount Answers' : 'Unanswered',
                      style: TextStyle(
                        color: isAnswered ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoubtDetailScreen(
                          doubt: doubt,
                          onAnswerAdded: (newAnswer) {
                            setState(() {
                              doubt['answers'].add(newAnswer);
                              doubt['answersCount'] = doubt['answers'].length;
                              doubt['isAnswered'] = true;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    isAnswered ? 'View Answers' : 'Write Answer',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DoubtDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doubt;
  final Function(Map<String, dynamic>) onAnswerAdded;

  const DoubtDetailScreen({
    super.key,
    required this.doubt,
    required this.onAnswerAdded,
  });

  @override
  State<DoubtDetailScreen> createState() => _DoubtDetailScreenState();
}

class _DoubtDetailScreenState extends State<DoubtDetailScreen> {
  final TextEditingController _answerController = TextEditingController();

  Future<void> _postAnswer() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.user?.name ?? 'Expert';
    final now = DateTime.now();
    final timeFormatted = DateFormat('dd MMM, hh:mm a').format(now);

    final newAnswer = {
      'authorName': userName,
      'answer': text,
      'createdAt': timeFormatted,
    };

    widget.onAnswerAdded(newAnswer);

    final doubtId = widget.doubt['id'];
    if (doubtId != null && doubtId.toString().length > 5) {
      try {
        await FirebaseFirestore.instance.collection('doubts').doc(doubtId.toString()).update({
          'answers': FieldValue.arrayUnion([newAnswer]),
          'answersCount': FieldValue.increment(1),
          'isAnswered': true,
        });
      } catch (e) {
        debugPrint("Error updating doubt answer in Firestore: $e");
      }
    }

    setState(() {
      _answerController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer posted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textDark : AppTheme.darkSlate;
    final secondaryTextColor = isDark ? AppColors.textDarkSecondary : Colors.grey;
    final borderColor = isDark ? AppColors.greyDark : Colors.grey.withValues(alpha: 0.15);

    final studentName = widget.doubt['studentName'] ?? 'Student';
    final subject = widget.doubt['subject'] ?? '';
    final question = widget.doubt['question'] ?? '';
    final answers = widget.doubt['answers'] as List;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Doubt Discussion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Original Doubt Question Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: (isDark ? AppColors.accent : AppTheme.primaryColor).withValues(alpha: 0.1),
                      child: Text(
                        studentName.isNotEmpty ? studentName[0].toUpperCase() : 'S',
                        style: TextStyle(color: isDark ? AppColors.accent : AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        studentName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        subject,
                        style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question,
                  style: TextStyle(fontSize: 15, color: textColor, height: 1.4),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ANSWERS / SOLUTIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: secondaryTextColor, letterSpacing: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Answers List
          Expanded(
            child: answers.isEmpty
                ? Center(
                    child: Text('No solutions yet. Provide yours below!', style: TextStyle(color: secondaryTextColor, fontSize: 13)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: answers.length,
                    itemBuilder: (context, index) {
                      final answerData = answers[index] as Map<String, dynamic>;
                      final author = answerData['authorName'] ?? 'Expert';
                      final answerText = answerData['answer'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor.withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 10,
                                  backgroundColor: (isDark ? AppColors.accent : AppTheme.primaryColor).withValues(alpha: 0.1),
                                  child: Text(
                                    author.isNotEmpty ? author[0].toUpperCase() : 'E',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? AppColors.accent : AppTheme.primaryColor),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    author,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (answerData['createdAt'] != null)
                                  Text(
                                    answerData['createdAt'].toString(),
                                    style: TextStyle(fontSize: 10, color: secondaryTextColor),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(answerText, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textDark : Colors.black87)),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Answer Composer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _answerController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Write a solution...',
                        hintStyle: TextStyle(color: secondaryTextColor.withValues(alpha: 0.8), fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: isDark ? AppColors.accent : AppTheme.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 16),
                      onPressed: _postAnswer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
