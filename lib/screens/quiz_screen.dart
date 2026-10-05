import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/app_theme.dart';
import 'quiz_result_screen.dart';
import '../models/test_model.dart';
import '../services/test_service.dart';
import '../services/firestore_service.dart';
import '../constants/app_colors.dart';

class QuizScreen extends StatefulWidget {
  final String testName;
  final String testId;

  const QuizScreen({super.key, required this.testName, this.testId = ''});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  static const int totalDurationSeconds = 15 * 60; // 15 minutes
  int secondsRemaining = totalDurationSeconds;
  Timer? _timer;

  List<Question> questions = [];
  bool isLoading = true;
  bool isSubmitting = false;

  Map<int, int> selectedOptions = {};
  Set<String> bookmarkedQuestionIds = {};
  Map<int, String> questionStatuses = {};

  void _initializeStatuses() {
    for (int i = 0; i < questions.length; i++) {
      questionStatuses[i] = 'unvisited';
    }
    if (questions.isNotEmpty) {
      questionStatuses[0] = 'not_answered';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    bookmarkedQuestionIds = {};

    if (widget.testId.isNotEmpty) {
      try {
        final fetchedQuestions = await TestService().getQuestionsForTest(
          widget.testId,
        );
        if (fetchedQuestions.isNotEmpty) {
          questions = fetchedQuestions;
        } else {
          questions = [];
        }
      } catch (e) {
        questions = [];
      }
    } else {
      questions = [];
    }

    if (mounted) {
      _initializeStatuses();
      setState(() {
        isLoading = false;
      });
      if (questions.isNotEmpty) {
        startTimer();
      }
    }
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        setState(() {
          secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _submitQuiz();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get formattedTime {
    int minutes = secondsRemaining ~/ 60;
    int seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitQuiz() async {
    if (isSubmitting) return;
    setState(() {
      isSubmitting = true;
    });
    _timer?.cancel();

    int correct = 0;
    int incorrect = 0;

    for (int i = 0; i < questions.length; i++) {
      if (selectedOptions.containsKey(i)) {
        if (selectedOptions[i] == questions[i].correctOptionIndex) {
          correct++;
        } else {
          incorrect++;
        }
      }
    }

    int unattempted = questions.length - (correct + incorrect);
    int score = (correct * 2) - incorrect; // +2 for correct, -1 for incorrect
    double accuracy = (correct + incorrect) > 0
        ? (correct / (correct + incorrect)) * 100
        : 0.0;

    int timeTakenSeconds = totalDurationSeconds - secondsRemaining;
    int minutes = timeTakenSeconds ~/ 60;
    int seconds = timeTakenSeconds % 60;
    String timeTaken =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Map<String, dynamic> subjectBreakdown = {};
    for (int i = 0; i < questions.length; i++) {
      String subject = questions[i].subject;
      if (!subjectBreakdown.containsKey(subject)) {
        subjectBreakdown[subject] = {'correct': 0, 'total': 0, 'accuracy': 0.0};
      }
      subjectBreakdown[subject]['total'] =
          subjectBreakdown[subject]['total'] + 1;

      if (selectedOptions.containsKey(i)) {
        if (selectedOptions[i] == questions[i].correctOptionIndex) {
          subjectBreakdown[subject]['correct'] =
              subjectBreakdown[subject]['correct'] + 1;
        }
      }
    }

    subjectBreakdown.forEach((key, value) {
      if (value['total'] > 0) {
        value['accuracy'] = (value['correct'] / value['total']) * 100.0;
      }
    });

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final currentUserName = Provider.of<UserProvider>(context, listen: false).user?.name ?? 'Student';

    if (widget.testId.isNotEmpty) {
      final result = TestResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUid,
        testId: widget.testId,
        testTitle: widget.testName,
        score: score,
        totalMarks: questions.length * 2, // Assuming 2 marks each
        correctAnswers: correct,
        wrongAnswers: incorrect,
        skippedAnswers: unattempted,
        accuracy: accuracy,
        attemptedAt: DateTime.now(),
        subjectBreakdown: subjectBreakdown,
        userAnswers: selectedOptions,
        timeTakenSeconds: timeTakenSeconds,
      );
      try {
        await TestService().submitTestResult(result);
        await FirestoreService().addNotification(
          title: 'Test Completed: ${widget.testName}',
          subtitle: 'You scored $score/${questions.length * 2} with ${accuracy.toStringAsFixed(1)}% accuracy!',
        );
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            userName: currentUserName,
            testName: widget.testName,
            score: score,
            totalQuestions: questions.length,
            correctAnswers: correct,
            incorrectAnswers: incorrect,
            unattempted: unattempted,
            timeTaken: timeTaken,
            questions: questions,
            userAnswers: selectedOptions,
          ),
        ),
      );
    }
  }

  void _showSubmitConfirmationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textDark : AppColors.text;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 28),
            const SizedBox(width: 10),
            Text(
              'Submit Test',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to submit your test? Please verify your answers.',
                style: TextStyle(
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.accent : AppColors.primary).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${selectedOptions.length}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.accent : AppColors.primary,
                        ),
                      ),
                      Text(
                        'Attempted',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLight),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: isDark ? AppColors.greyDark : Colors.grey.shade300,
                  ),
                  Column(
                    children: [
                      Text(
                        '${questions.length - selectedOptions.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      Text(
                        'Unattempted',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.textDarkSecondary : AppColors.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Review',
              style: TextStyle(
                color: isDark ? AppColors.textDarkSecondary : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitQuiz();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String getSectionName(int index) {
    if (questions.isEmpty) return 'General';
    int qPerPart = (questions.length / 4).ceil();
    if (qPerPart == 0) qPerPart = 1;
    
    if (index < qPerPart) return 'General Intelligence & Reasoning';
    if (index < qPerPart * 2) return 'General Awareness';
    if (index < qPerPart * 3) return 'Quantitative Aptitude';
    return 'English Comprehension';
  }

  String getPartLabel(int index) {
    if (questions.isEmpty) return 'PART-A';
    int qPerPart = (questions.length / 4).ceil();
    if (qPerPart == 0) qPerPart = 1;
    
    if (index < qPerPart) return 'PART-A';
    if (index < qPerPart * 2) return 'PART-B';
    if (index < qPerPart * 3) return 'PART-C';
    return 'PART-D';
  }

  void _jumpToPart(String part) {
    int qPerPart = (questions.length / 4).ceil();
    if (qPerPart == 0) qPerPart = 1;
    
    int targetIndex = 0;
    if (part == 'PART-A') {
      targetIndex = 0;
    } else if (part == 'PART-B') {
      targetIndex = qPerPart;
    } else if (part == 'PART-C') {
      targetIndex = qPerPart * 2;
    } else if (part == 'PART-D') {
      targetIndex = qPerPart * 3;
    }
    
    if (targetIndex < questions.length) {
      setState(() {
        if (questionStatuses[currentQuestionIndex] == 'unvisited') {
          questionStatuses[currentQuestionIndex] = 'not_answered';
        }
        currentQuestionIndex = targetIndex;
        if (questionStatuses[currentQuestionIndex] == 'unvisited') {
          questionStatuses[currentQuestionIndex] = 'not_answered';
        }
      });
    }
  }

  void _clearResponse() {
    setState(() {
      selectedOptions.remove(currentQuestionIndex);
      questionStatuses[currentQuestionIndex] = 'not_answered';
    });
  }

  void _markForReviewAndNext() {
    setState(() {
      questionStatuses[currentQuestionIndex] = 'marked_for_review';
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        if (questionStatuses[currentQuestionIndex] == 'unvisited') {
          questionStatuses[currentQuestionIndex] = 'not_answered';
        }
      } else {
        _showSubmitConfirmationDialog();
      }
    });
  }

  void _saveAndNext() {
    if (selectedOptions[currentQuestionIndex] == null) {
      setState(() {
        questionStatuses[currentQuestionIndex] = 'not_answered';
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please select an option before saving.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      questionStatuses[currentQuestionIndex] = 'answered';
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        if (questionStatuses[currentQuestionIndex] == 'unvisited') {
          questionStatuses[currentQuestionIndex] = 'not_answered';
        }
      } else {
        _showSubmitConfirmationDialog();
      }
    });
  }

  Widget _buildPaletteLegend(bool isDark, Color textColor, Color secondaryTextColor) {
    int answered = questionStatuses.values.where((v) => v == 'answered').length;
    int notAnswered = questionStatuses.values.where((v) => v == 'not_answered').length;
    int marked = questionStatuses.values.where((v) => v == 'marked_for_review').length;
    int unvisited = questionStatuses.values.where((v) => v == 'unvisited').length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.greyDark : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legend',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.primary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem('Answered', answered, Colors.green, textColor),
              _buildLegendItem('Not Answered', notAnswered, Colors.redAccent, textColor),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegendItem('For Review', marked, Colors.amber.shade700, textColor),
              _buildLegendItem('Not Visited', unvisited, isDark ? Colors.blue.shade900 : Colors.blue.shade100, textColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color, Color textColor) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $count',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
        ),
      ],
    );
  }

  Widget _buildQuestionNumberButton(int index, bool isDark) {
    String status = questionStatuses[index] ?? 'unvisited';
    bool isCurrent = currentQuestionIndex == index;
    
    Color bgColor;
    Color textColor = Colors.white;
    
    switch (status) {
      case 'answered':
        bgColor = Colors.green;
        break;
      case 'marked_for_review':
        bgColor = Colors.amber.shade700;
        break;
      case 'not_answered':
        bgColor = Colors.redAccent;
        break;
      case 'unvisited':
      default:
        bgColor = isDark ? Colors.blue.shade900.withOpacity(0.4) : Colors.blue.shade100;
        textColor = isDark ? Colors.blue.shade200 : Colors.blue.shade800;
        break;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (questionStatuses[currentQuestionIndex] == 'unvisited') {
            questionStatuses[currentQuestionIndex] = 'not_answered';
          }
          currentQuestionIndex = index;
          if (questionStatuses[currentQuestionIndex] == 'unvisited') {
            questionStatuses[currentQuestionIndex] = 'not_answered';
          }
        });
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: isCurrent
              ? Border.all(color: isDark ? AppColors.accent : Colors.blue.shade900, width: 2.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionPaletteContent(bool isDark, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          getSectionName(currentQuestionIndex),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
        ),
        const SizedBox(height: 12),
        _buildPaletteLegend(isDark, textColor, secondaryTextColor),
        const SizedBox(height: 16),
        Text(
          'Question Palette:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: secondaryTextColor),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemCount: questions.length,
            itemBuilder: (context, idx) => _buildQuestionNumberButton(idx, isDark),
          ),
        ),
        Divider(color: isDark ? AppColors.greyDark : Colors.grey.shade300),
        ElevatedButton(
          onPressed: _showSubmitConfirmationDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('SUBMIT TEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
        ),
      ],
    );
  }

  Widget _buildInstructionsBanner(bool isDark, Color bannerBgColor, Color bannerBorderColor, Color bannerTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bannerBgColor,
        border: Border(
          bottom: BorderSide(color: bannerBorderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              side: BorderSide(color: isDark ? AppColors.accent : Colors.blue, width: 1),
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            child: Text('Zoom (+)', style: TextStyle(fontSize: 10, color: isDark ? AppColors.accent : Colors.blue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              minimumSize: Size.zero,
              side: BorderSide(color: isDark ? AppColors.accent : Colors.blue, width: 1),
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
            ),
            child: Text('Zoom (-)', style: TextStyle(fontSize: 10, color: isDark ? AppColors.accent : Colors.blue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'INSTRUCTIONS: Please note that this is a mock test for practice purposes.',
              style: TextStyle(fontSize: 10, color: bannerTextColor, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartTabs(bool isDark, Color tabBgColor) {
    return Container(
      color: tabBgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['PART-A', 'PART-B', 'PART-C', 'PART-D'].map((part) {
            bool isPartSelected = getPartLabel(currentQuestionIndex) == part;
            final selectedColor = isDark ? AppColors.accent : Colors.blue.shade800;
            final unselectedColor = isDark ? Colors.white : Colors.blue.shade800;
            final btnBgColor = isPartSelected ? selectedColor : (isDark ? AppColors.surfaceDark : Colors.white);
            final btnFgColor = isPartSelected ? Colors.white : unselectedColor;

            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: ElevatedButton(
                onPressed: () => _jumpToPart(part),
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnBgColor,
                  foregroundColor: btnFgColor,
                  side: BorderSide(color: selectedColor, width: 1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                child: Text(
                  part,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuestionArea(bool isDark, Color textColor, Color secondaryTextColor, Color borderColor) {
    final question = questions[currentQuestionIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.accent : Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Question : ${currentQuestionIndex + 1}',
                style: TextStyle(
                  color: isDark ? AppColors.accent : Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            Row(
              children: [
                Text(
                  'Marks: +${question.marks} / -0.25',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondaryTextColor),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    try {
                      final added = await FirestoreService().toggleBookmark(
                        questionId: question.id,
                        questionText: question.text,
                        subject: question.subject,
                        testName: widget.testName,
                        correctAnswer: question.options[question.correctOptionIndex],
                      );
                      if (!mounted) return;
                      setState(() {
                        if (added) {
                          bookmarkedQuestionIds.add(question.id);
                        } else {
                          bookmarkedQuestionIds.remove(question.id);
                        }
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(added ? 'Added to Bookmarks' : 'Removed from Bookmarks'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  child: Icon(
                    bookmarkedQuestionIds.contains(question.id) ? Icons.bookmark : Icons.bookmark_border,
                    color: isDark ? AppColors.accent : Colors.blue,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          question.text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(
          question.options.length,
          (idx) => _buildCbtOption(idx, isDark, textColor, secondaryTextColor, borderColor),
        ),
      ],
    );
  }

  Widget _buildCbtOption(int index, bool isDark, Color textColor, Color secondaryTextColor, Color borderColor) {
    bool isSelected = selectedOptions[currentQuestionIndex] == index;
    String optionText = questions[currentQuestionIndex].options[index];
    String optionLetter = ['A', 'B', 'C', 'D', 'E', 'F'][index % 6];
    
    final selectedBgColor = isDark 
        ? AppColors.accent.withOpacity(0.15) 
        : Colors.blue.shade50.withOpacity(0.3);
    final selectedBorderColor = isDark ? AppColors.accent : Colors.blue;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOptions[currentQuestionIndex] = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? selectedBgColor : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? selectedBorderColor : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? selectedBorderColor : secondaryTextColor,
                  width: 2,
                ),
                color: isSelected ? selectedBorderColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.circle, size: 7, color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              '$optionLetter. ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? selectedBorderColor : secondaryTextColor,
              ),
            ),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationButtons(bool isDark, Color borderColor) {
    final primaryBtnColor = isDark ? AppColors.accent : Colors.blue.shade800;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(top: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: OutlinedButton(
              onPressed: _markForReviewAndNext,
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBtnColor,
                side: BorderSide(color: primaryBtnColor, width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Mark for Review & Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          if (MediaQuery.of(context).orientation == Orientation.portrait) ...[
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _clearResponse,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Clear', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
            
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: _saveAndNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBtnColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Save & Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF000F29) : AppTheme.backgroundLight,
        body: const Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF000F29) : AppTheme.backgroundLight;
    final cardColor = isDark ? const Color(0xFF0A1E3F) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700;
    final borderColor = isDark ? const Color(0xFF1E3A8A) : Colors.grey.shade300;
    final bannerBgColor = isDark ? const Color(0xFF00122C) : Colors.white;
    final bannerBorderColor = isDark ? const Color(0xFF1E3A8A) : Colors.grey.shade300;
    final bannerTextColor = isDark ? Colors.white70 : Colors.black87;
    final tabBgColor = isDark ? const Color(0xFF00122C) : Colors.white;

    if (!isLoading && questions.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(widget.testName),
          backgroundColor: tabBgColor,
          foregroundColor: textColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_late_outlined, size: 64, color: AppColors.accent),
                const SizedBox(height: 16),
                Text(
                  'No Questions Currently Available',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'This test has no published questions in the database at the moment.',
                  style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.testName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: tabBgColor,
        foregroundColor: textColor,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Row(
                children: [
                  Text(
                    'Time Left: ',
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.grid_view_rounded, color: isDark ? AppColors.accent : Colors.blue),
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            }
          ),
        ],
      ),
      endDrawer: Drawer(
        backgroundColor: cardColor,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildQuestionPaletteContent(isDark, textColor, secondaryTextColor),
          ),
        ),
      ),
      body: SafeArea(
        child: isSubmitting
            ? const Center(child: CircularProgressIndicator())
            : OrientationBuilder(
                builder: (context, orientation) {
                  if (orientation == Orientation.landscape) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 280,
                          decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: borderColor, width: 1)),
                            color: cardColor,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(12),
                                  child: _buildQuestionPaletteContent(isDark, textColor, secondaryTextColor),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(12),
                                color: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _clearResponse,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    ),
                                    child: const Text('Clear Response', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildInstructionsBanner(isDark, bannerBgColor, bannerBorderColor, bannerTextColor),
                              _buildPartTabs(isDark, tabBgColor),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: _buildQuestionArea(isDark, textColor, secondaryTextColor, borderColor),
                                ),
                              ),
                              _buildBottomNavigationButtons(isDark, borderColor),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInstructionsBanner(isDark, bannerBgColor, bannerBorderColor, bannerTextColor),
                        _buildPartTabs(isDark, tabBgColor),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: _buildQuestionArea(isDark, textColor, secondaryTextColor, borderColor),
                          ),
                        ),
                        _buildBottomNavigationButtons(isDark, borderColor),
                      ],
                    );
                  }
                },
              ),
      ),
    );
  }
}
