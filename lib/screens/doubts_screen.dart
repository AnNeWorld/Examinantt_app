import 'dart:async';
import 'package:examinantt_app/utils/app_navigator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import 'ask_doubt_screen.dart';
import '../widgets/notification_bell_action.dart';

class DoubtsScreen extends StatefulWidget {
  const DoubtsScreen({super.key});

  @override
  State<DoubtsScreen> createState() => _DoubtsScreenState();
}

class _DoubtsScreenState extends State<DoubtsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final Stream<QuerySnapshot> _doubtsStream;

  @override
  void initState() {
    super.initState();
    _doubtsStream = _db.collection('doubts').snapshots();
  }

  void _askDoubt() {
    AppNavigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AskDoubtScreen(),
      ),
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
        leadingWidth: 42,
        titleSpacing: 6,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Doubt Forum', style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          NotificationBellAction(color: textColor),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _askDoubt,
        backgroundColor: const Color(0xFFFFA000),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.black),
        label: const Text(
          'Ask a Doubt',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      body: Column(
        children: [
          // Ask a doubt CTA
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: _askDoubt,
              borderRadius: BorderRadius.circular(16),
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
              ),
            ).animate().fade().slideY(begin: 0.1),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _doubtsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFFFA000)));
                }

                List<Map<String, dynamic>> doubtsList = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  doubtsList = snapshot.data!.docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return {'id': doc.id, ...d};
                  }).toList();

                  doubtsList.sort((a, b) {
                    final aTime = a['createdAt'];
                    final bTime = b['createdAt'];
                    if (aTime is Timestamp && bTime is Timestamp) {
                      return bTime.compareTo(aTime);
                    }
                    return 0;
                  });
                }

                return RefreshIndicator(
                  color: const Color(0xFFFFA000),
                  backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 650));
                    if (mounted) setState(() {});
                  },
                  child: doubtsList.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          child: Container(
                            height: 350,
                            alignment: Alignment.center,
                            child: Text(
                              'No doubts posted yet. Be the first to ask!',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openDoubtDetail(Map<String, dynamic> doubt) {
    AppNavigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoubtDetailScreen(
          doubt: doubt,
          onAnswerAdded: (newAnswer) {
            setState(() {
              if (doubt['answers'] is List) {
                (doubt['answers'] as List).add(newAnswer);
              } else {
                doubt['answers'] = [newAnswer];
              }
              doubt['answersCount'] = (doubt['answers'] as List).length;
              doubt['isAnswered'] = true;
            });
          },
        ),
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
    final String studentName = doubt['studentName']?.toString() ?? 'Student';
    DateTime? doubtDate;
    if (doubt['createdAt'] is Timestamp) {
      doubtDate = (doubt['createdAt'] as Timestamp).toDate();
    } else if (doubt['createdAt'] is String) {
      doubtDate = DateTime.tryParse(doubt['createdAt'] as String);
    }
    String time = doubt['time']?.toString() ?? '';
    if (doubtDate != null) {
      time = DateFormat('dd MMM, hh:mm a').format(doubtDate);
    } else if (time.isEmpty || time == 'Just now') {
      time = DateFormat('dd MMM, hh:mm a').format(DateTime.now());
    }
    final String subject = doubt['subject']?.toString() ?? 'General';
    final String question = doubt['question']?.toString() ?? '';
    final bool isAnswered = doubt['isAnswered'] == true;
    final rawAnswers = doubt['answers'];
    final int answersCount = (rawAnswers is List)
        ? rawAnswers.length
        : (doubt['answersCount'] is int ? doubt['answersCount'] as int : 0);
    final bool hasAnswers = answersCount > 0 || isAnswered;

    return GestureDetector(
      onTap: () => _openDoubtDetail(doubt),
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
                          style: AppTextStyles.titleSmall.withColor(textColor).bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              studentName,
                              style: AppTextStyles.titleSmall.withColor(textColor).bold,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              time,
                              style: AppTextStyles.caption.withColor(secondaryTextColor).size(11),
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
                    style: AppTextStyles.captionBold.withColor(Colors.blue).size(11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              question,
              style: AppTextStyles.bodyMedium.withColor(textColor).size(15).lineHeight(1.4),
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
                      hasAnswers ? Icons.check_circle : Icons.help_outline,
                      color: hasAnswers ? Colors.green : Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasAnswers ? '$answersCount Answers' : 'Unanswered',
                      style: AppTextStyles.captionBold.withColor(hasAnswers ? Colors.green : Colors.orange).size(13),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => _openDoubtDetail(doubt),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? AppColors.accent : AppTheme.primaryColor,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    hasAnswers ? 'View Answers' : 'Write Answer',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
  List<Map<String, dynamic>> _answers = [];
  StreamSubscription<DocumentSnapshot>? _docSubscription;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final rawAnswers = widget.doubt['answers'];
    if (rawAnswers is List) {
      _answers = rawAnswers.map((a) {
        if (a is Map) return Map<String, dynamic>.from(a);
        return <String, dynamic>{'answer': a.toString()};
      }).toList();
    }

    final doubtId = widget.doubt['id']?.toString();
    if (doubtId != null && doubtId.isNotEmpty) {
      _docSubscription = FirebaseFirestore.instance
          .collection('doubts')
          .doc(doubtId)
          .snapshots()
          .listen((snap) {
        if (snap.exists && mounted) {
          final data = snap.data();
          if (data != null && data['answers'] is List) {
            setState(() {
              _answers = (data['answers'] as List).map((a) {
                if (a is Map) return Map<String, dynamic>.from(a);
                return <String, dynamic>{'answer': a.toString()};
              }).toList();
            });
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _docSubscription?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _postAnswer() async {
    final text = _answerController.text.trim();
    if (text.isEmpty || _isSending) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userName = userProvider.user?.name ?? 'Expert';
    final now = DateTime.now();
    final timeFormatted = DateFormat('dd MMM, hh:mm a').format(now);

    final newAnswer = {
      'authorName': userName,
      'answer': text,
      'createdAt': timeFormatted,
    };

    setState(() {
      _answers.add(newAnswer);
      _answerController.clear();
      _isSending = true;
    });

    widget.onAnswerAdded(newAnswer);

    final doubtId = widget.doubt['id']?.toString();
    if (doubtId != null && doubtId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('doubts').doc(doubtId).set({
          'answers': FieldValue.arrayUnion([newAnswer]),
          'answersCount': FieldValue.increment(1),
          'isAnswered': true,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating doubt answer in Firestore: $e");
      }
    }

    if (mounted) {
      setState(() => _isSending = false);
      AppTheme.showSuccessSnackBar(context, 'Answer posted successfully!');
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

    final studentName = widget.doubt['studentName']?.toString() ?? 'Student';
    final subject = widget.doubt['subject']?.toString() ?? 'General';
    final question = widget.doubt['question']?.toString() ?? '';
    final answers = _answers;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leadingWidth: 42,
        titleSpacing: 6,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.maybePop(context),
        ),
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
                        style: TextStyle(color: isDark ? AppColors.accent : AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        studentName,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor),
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
                        style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold),
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
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: secondaryTextColor, letterSpacing: 0.8),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Answers List
          Expanded(
            child: answers.isEmpty
                ? Center(
                    child: Text('No solutions yet. Provide yours below!', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: answers.length,
                    itemBuilder: (context, index) {
                      final answerData = answers[index];
                      final author = answerData['authorName']?.toString() ?? 'Expert';
                      final answerText = answerData['answer']?.toString() ?? '';
                      final createdAt = answerData['createdAt']?.toString();

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
                                  radius: 12,
                                  backgroundColor: (isDark ? AppColors.accent : AppTheme.primaryColor).withValues(alpha: 0.1),
                                  child: Text(
                                    author.isNotEmpty ? author[0].toUpperCase() : 'E',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? AppColors.accent : AppTheme.primaryColor),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    author,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: textColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (createdAt != null)
                                  Text(
                                    createdAt,
                                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(answerText, style: TextStyle(fontSize: 14, color: isDark ? AppColors.textDark : Colors.black87)),
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
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
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
