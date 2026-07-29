import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String testName;

  const QuizScreen({super.key, required this.testName});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int secondsRemaining = 3600; // 60 minutes
  Timer? _timer;
  
  // Dummy Questions
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is the capital of Australia?',
      'options': ['Sydney', 'Melbourne', 'Canberra', 'Perth'],
      'answer': 2,
    },
    {
      'question': 'If x + 1/x = 5, then find the value of x^2 + 1/x^2',
      'options': ['25', '23', '27', '21'],
      'answer': 1,
    },
    {
      'question': 'Who is known as the Missile Man of India?',
      'options': ['Homi J. Bhabha', 'Vikram Sarabhai', 'Dr. A.P.J. Abdul Kalam', 'Satish Dhawan'],
      'answer': 2,
    },
    {
      'question': 'A train running at the speed of 60 km/hr crosses a pole in 9 seconds. What is the length of the train?',
      'options': ['120 metres', '180 metres', '324 metres', '150 metres'],
      'answer': 3,
    },
  ];

  Map<int, int> selectedOptions = {};

  @override
  void initState() {
    super.initState();
    startTimer();
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

  void _submitQuiz() {
    int correct = 0;
    int incorrect = 0;
    
    for (int i = 0; i < questions.length; i++) {
      if (selectedOptions.containsKey(i)) {
        if (selectedOptions[i] == questions[i]['answer']) {
          correct++;
        } else {
          incorrect++;
        }
      }
    }
    
    int unattempted = questions.length - (correct + incorrect);
    int score = (correct * 2) - incorrect; // +2 for correct, -1 for incorrect
    
    int timeTakenSeconds = 3600 - secondsRemaining;
    int minutes = timeTakenSeconds ~/ 60;
    int seconds = timeTakenSeconds % 60;
    String timeTaken = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          userName: 'Student',
          testName: widget.testName,
          score: score,
          totalQuestions: questions.length,
          correctAnswers: correct,
          incorrectAnswers: incorrect,
          unattempted: unattempted,
          timeTaken: timeTaken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(widget.testName, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 4,
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${currentQuestionIndex + 1} of ${questions.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[100],
                          ),
                          child: const Icon(Icons.bookmark_border, size: 20, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Question Text
                    Text(
                      questions[currentQuestionIndex]['question'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkSlate,
                        height: 1.5,
                      ),
                    ).animate(key: ValueKey(currentQuestionIndex)).fade().slideX(begin: 0.05),
                    const SizedBox(height: 32),
                    
                    // Options
                    ...List.generate(
                      (questions[currentQuestionIndex]['options'] as List).length,
                      (index) => _buildOption(index),
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: currentQuestionIndex > 0
                        ? () {
                            setState(() {
                              currentQuestionIndex--;
                            });
                          }
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Previous'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (currentQuestionIndex < questions.length - 1) {
                        setState(() {
                          currentQuestionIndex++;
                        });
                      } else {
                        _submitQuiz();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      currentQuestionIndex < questions.length - 1 ? 'Next' : 'Submit Test',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildOption(int index) {
    bool isSelected = selectedOptions[currentQuestionIndex] == index;
    String optionText = questions[currentQuestionIndex]['options'][index];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedOptions[currentQuestionIndex] = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                optionText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryDark : AppTheme.darkSlate,
                ),
              ),
            ),
          ],
        ),
      ).animate(key: ValueKey('opt_${currentQuestionIndex}_$index')).fade(delay: (50 * index).ms).slideX(begin: 0.1),
    );
  }
}
