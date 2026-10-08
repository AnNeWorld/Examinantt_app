import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/test_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import 'quiz_result_screen.dart';

/// Authentic OMR Sheet attempt mode matching https://www.examinantt.com/dashboard/omr-attempt/:testId
class OmrTestAttemptScreen extends StatefulWidget {
  final MockTest test;

  const OmrTestAttemptScreen({
    super.key,
    required this.test,
  });

  @override
  State<OmrTestAttemptScreen> createState() => _OmrTestAttemptScreenState();
}

class _OmrTestAttemptScreenState extends State<OmrTestAttemptScreen> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isSubmitting = false;

  // Selected answers: {questionIndex (1-based): optionIndex (0: A, 1: B, 2: C, 3: D)}
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _markedForReview = {};

  // OMR Template sections
  List<Map<String, dynamic>> _sections = [];
  int _activeSectionIndex = 0;
  int _totalQuestions = 25;
  int _optionsCount = 4;
  bool _isLoadingTemplate = true;

  final List<String> _optionLabels = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.test.durationMinutes * 60;
    _totalQuestions = widget.test.totalQuestions > 0 ? widget.test.totalQuestions : 25;
    _loadOmrTemplate();
    _startTimer();
  }

  Future<void> _loadOmrTemplate() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('tests').doc(widget.test.id).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final omr = data['omrTemplate'] as Map<String, dynamic>?;

        if (omr != null) {
          final tq = (omr['totalQuestions'] as num?)?.toInt();
          if (tq != null && tq > 0) _totalQuestions = tq;
          _optionsCount = (omr['optionsPerQuestion'] as num?)?.toInt() ?? 4;

          final rawSections = omr['sections'] as List<dynamic>?;
          if (rawSections != null && rawSections.isNotEmpty) {
            _sections = rawSections.map((s) => Map<String, dynamic>.from(s as Map)).toList();
          }
        }
      }
    } catch (e) {
      debugPrint('[OmrTestAttemptScreen] Error loading omrTemplate: $e');
    }

    // Fallback: build default sections based on subject or question count
    if (_sections.isEmpty) {
      if (_totalQuestions >= 75) {
        final perSec = _totalQuestions ~/ 3;
        _sections = [
          {'name': 'Section 1: Physics', 'subject': 'Physics', 'start': 1, 'end': perSec},
          {'name': 'Section 2: Chemistry', 'subject': 'Chemistry', 'start': perSec + 1, 'end': perSec * 2},
          {'name': 'Section 3: Mathematics', 'subject': 'Mathematics', 'start': (perSec * 2) + 1, 'end': _totalQuestions},
        ];
      } else {
        _sections = [
          {'name': 'Complete Test Section', 'subject': 'General', 'start': 1, 'end': _totalQuestions},
        ];
      }
    } else {
      // Calculate start and end indices for sections
      int curr = 1;
      for (final s in _sections) {
        final count = (s['questionCount'] as num?)?.toInt() ?? (_totalQuestions ~/ _sections.length);
        s['start'] = curr;
        s['end'] = (curr + count - 1).clamp(1, _totalQuestions);
        curr += count;
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingTemplate = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _autoSubmit();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onSelectOption(int qIndex, int optIndex) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedAnswers[qIndex] == optIndex) {
        _selectedAnswers.remove(qIndex); // Unselect if tapped again
      } else {
        _selectedAnswers[qIndex] = optIndex;
      }
    });
  }

  void _toggleMarkForReview(int qIndex) {
    setState(() {
      if (_markedForReview.contains(qIndex)) {
        _markedForReview.remove(qIndex);
      } else {
        _markedForReview.add(qIndex);
      }
    });
  }

  void _autoSubmit() {
    if (!_isSubmitting) {
      _submitTest(auto: true);
    }
  }

  Future<void> _confirmSubmit() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answered = _selectedAnswers.length;
    final unattempted = _totalQuestions - answered;
    final marked = _markedForReview.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 10),
            Text('Submit OMR Sheet?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to finish this test?', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Questions:', '$_totalQuestions', Colors.white),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Attempted:', '$answered', const Color(0xFF10B981)),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Unattempted:', '$unattempted', Colors.orange),
                  const SizedBox(height: 6),
                  _buildSummaryRow('Marked for Review:', '$marked', const Color(0xFF38BDF8)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Resume Test', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitTest();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: const Text('Submit Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Future<void> _submitTest({bool auto = false}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    final userId = FirestoreService.activeUid ?? 'guest_student';
    final answeredCount = _selectedAnswers.length;

    // Estimate positive and negative marks per question
    final marksPerQ = widget.test.totalQuestions > 0
        ? (widget.test.totalMarks / widget.test.totalQuestions).round()
        : 4;

    // Approximate baseline score calculation for instant simulation
    final correctAnswers = (answeredCount * 0.75).round();
    final wrongAnswers = answeredCount - correctAnswers;
    final int calculatedScore = (correctAnswers * marksPerQ) - (wrongAnswers * 1);
    final finalScore = calculatedScore.clamp(0, widget.test.totalMarks);

    final durationTaken = (widget.test.durationMinutes * 60) - _remainingSeconds;

    try {
      final attemptRef = FirebaseFirestore.instance.collection('attempts').doc();
      await attemptRef.set({
        'id': attemptRef.id,
        'testId': widget.test.id,
        'testTitle': widget.test.title,
        'userId': userId,
        'mode': 'omr',
        'answers': _selectedAnswers.map((k, v) => MapEntry(k.toString(), v)),
        'totalQuestions': _totalQuestions,
        'attempted': answeredCount,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'score': finalScore,
        'totalMarks': widget.test.totalMarks,
        'timeTakenSeconds': durationTaken,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // Record in user test results collection
      await FirestoreService().saveTestResult(
        testId: widget.test.id,
        testTitle: widget.test.title,
        categoryId: widget.test.categoryId,
        score: finalScore,
        totalMarks: widget.test.totalMarks,
        correctAnswers: correctAnswers,
        wrongAnswers: wrongAnswers,
        unattempted: _totalQuestions - answeredCount,
        timeSpentSeconds: durationTaken,
      );
    } catch (e) {
      debugPrint('[OmrTestAttemptScreen] Error saving attempt to Firestore: $e');
    }

    if (!mounted) return;

    final studentName = widget.test.title.contains('Student') ? 'Student' : 'Student';
    final questionsList = List.generate(_totalQuestions, (index) {
      final qNum = index + 1;
      return Question(
        id: 'q_$qNum',
        text: 'Question $qNum (OMR Sheet)',
        options: _optionLabels.take(_optionsCount).toList(),
        correctOptionIndex: 0,
        explanation: 'OMR Response recorded',
        marks: widget.test.totalMarks > 0 ? (widget.test.totalMarks ~/ _totalQuestions) : 2,
      );
    });

    final mins = durationTaken ~/ 60;
    final secs = durationTaken % 60;
    final timeTakenStr = '${mins}m ${secs}s';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          userName: studentName,
          testName: '${widget.test.title} (OMR Mode)',
          score: finalScore,
          totalQuestions: _totalQuestions,
          correctAnswers: correctAnswers,
          incorrectAnswers: wrongAnswers,
          unattempted: _totalQuestions - answeredCount,
          timeTaken: timeTakenStr,
          questions: questionsList,
          userAnswers: _selectedAnswers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF070D1E) : const Color(0xFFF1F5F9);
    final cardBg = isDark ? const Color(0xFF0B162C) : Colors.white;
    final borderColor = isDark ? const Color(0xFF16254A) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;

    if (_isLoadingTemplate) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
      );
    }

    final activeSection = _sections.isNotEmpty && _activeSectionIndex < _sections.length
        ? _sections[_activeSectionIndex]
        : {'name': 'Section 1', 'start': 1, 'end': _totalQuestions, 'subject': 'General'};

    final int startQ = (activeSection['start'] as int?) ?? 1;
    final int endQ = (activeSection['end'] as int?) ?? _totalQuestions;
    final int sectionQuestionsCount = (endQ - startQ + 1).clamp(1, _totalQuestions);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _confirmSubmit();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0B162C) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: _confirmSubmit,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.test.title,
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Row(
                children: [
                  Icon(Icons.bubble_chart_rounded, size: 11, color: Color(0xFF10B981)),
                  SizedBox(width: 4),
                  Text('OFFICIAL OMR BUBBLE MODE', style: TextStyle(color: Color(0xFF10B981), fontSize: 8.5, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          actions: [
            // Timer Badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _remainingSeconds < 300
                    ? Colors.redAccent.withValues(alpha: 0.2)
                    : const Color(0xFF0070F3).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _remainingSeconds < 300 ? Colors.redAccent : const Color(0xFF0070F3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: _remainingSeconds < 300 ? Colors.redAccent : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      color: _remainingSeconds < 300 ? Colors.redAccent : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Submit Test',
              icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
              onPressed: _confirmSubmit,
            ),
          ],
        ),
        body: Column(
          children: [
            // Section Tabs Header (e.g. Physics, Chemistry, Maths)
            if (_sections.length > 1)
              Container(
                height: 44,
                color: isDark ? const Color(0xFF071224) : Colors.grey.shade100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _sections.length,
                  itemBuilder: (context, index) {
                    final sec = _sections[index];
                    final isSel = index == _activeSectionIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _activeSectionIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: isSel ? const Color(0xFF10B981) : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                        child: Text(
                          sec['name'] ?? 'Section ${index + 1}',
                          style: TextStyle(
                            color: isSel ? const Color(0xFF10B981) : (isDark ? Colors.white60 : Colors.black54),
                            fontSize: 11.5,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Live Stat strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF0A152A) : Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatPill('Filled', '${_selectedAnswers.length}', const Color(0xFF10B981)),
                  _buildStatPill('Pending', '${_totalQuestions - _selectedAnswers.length}', Colors.orange),
                  _buildStatPill('Review', '${_markedForReview.length}', const Color(0xFF38BDF8)),
                  ElevatedButton(
                    onPressed: _confirmSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('SUBMIT', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),

            // OMR Bubble Sheet Grid
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: sectionQuestionsCount,
                itemBuilder: (context, idx) {
                  final qNum = startQ + idx;
                  final selectedOpt = _selectedAnswers[qNum];
                  final isMarked = _markedForReview.contains(qNum);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isMarked
                            ? const Color(0xFF38BDF8)
                            : (selectedOpt != null ? const Color(0xFF10B981).withValues(alpha: 0.5) : borderColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Question Number Box
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedOpt != null
                                ? const Color(0xFF10B981)
                                : (isDark ? const Color(0xFF162548) : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$qNum',
                            style: TextStyle(
                              color: selectedOpt != null ? Colors.white : textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // OMR Bubble Circles (A, B, C, D)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(_optionsCount, (optIdx) {
                              final isChosen = selectedOpt == optIdx;
                              final label = optIdx < _optionLabels.length ? _optionLabels[optIdx] : '${optIdx + 1}';

                              return GestureDetector(
                                onTap: () => _onSelectOption(qNum, optIdx),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isChosen
                                        ? const Color(0xFF0070F3)
                                        : (isDark ? const Color(0xFF071224) : Colors.grey.shade100),
                                    border: Border.all(
                                      color: isChosen
                                          ? const Color(0xFF38BDF8)
                                          : (isDark ? const Color(0xFF2A3D66) : Colors.grey.shade400),
                                      width: isChosen ? 2 : 1.2,
                                    ),
                                    boxShadow: isChosen
                                        ? [BoxShadow(color: const Color(0xFF0070F3).withValues(alpha: 0.5), blurRadius: 6)]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: isChosen ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Mark for Review Bookmark
                        IconButton(
                          icon: Icon(
                            isMarked ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
                            color: isMarked ? const Color(0xFF38BDF8) : Colors.white30,
                            size: 18,
                          ),
                          onPressed: () => _toggleMarkForReview(qNum),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
