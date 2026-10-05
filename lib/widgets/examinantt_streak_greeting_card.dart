// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';

class ExaminanttStreakGreetingCard extends StatefulWidget {
  final String studentName;
  final Function(String examName)? onExamChanged;

  const ExaminanttStreakGreetingCard({
    super.key,
    required this.studentName,
    this.onExamChanged,
  });

  @override
  State<ExaminanttStreakGreetingCard> createState() => _ExaminanttStreakGreetingCardState();
}

class _ExaminanttStreakGreetingCardState extends State<ExaminanttStreakGreetingCard> {
  String _selectedExam = 'JEE Main 2027';

  final List<Map<String, dynamic>> _examsList = [
    {
      'name': 'JEE Main 2027',
      'icon': Icons.school_rounded,
      'color': const Color(0xFF0070F3),
      'date': '01 Feb 2027',
      'days': 187,
    },
    {
      'name': 'NEET UG 2027',
      'icon': Icons.medical_services_rounded,
      'color': const Color(0xFF06B6D4),
      'date': '04 May 2027',
      'days': 279,
    },
    {
      'name': 'JEE Advanced',
      'icon': Icons.rocket_launch_rounded,
      'color': const Color(0xFF3B82F6),
      'date': '25 May 2027',
      'days': 300,
    },
    {
      'name': 'CUET UG',
      'icon': Icons.auto_stories_rounded,
      'color': const Color(0xFFA855F7),
      'date': '15 May 2027',
      'days': 290,
    },
    {
      'name': 'SSC CGL',
      'icon': Icons.emoji_events_rounded,
      'color': const Color(0xFFF59E0B),
      'date': '12 Oct 2026',
      'days': 75,
    },
    {
      'name': 'Banking',
      'icon': Icons.account_balance_rounded,
      'color': const Color(0xFF10B981),
      'date': '20 Nov 2026',
      'days': 114,
    },
    {
      'name': 'GATE 2027',
      'icon': Icons.settings_suggest_rounded,
      'color': const Color(0xFF6366F1),
      'date': '07 Feb 2027',
      'days': 193,
    },
    {
      'name': 'Defence',
      'icon': Icons.shield_rounded,
      'color': const Color(0xFF22C55E),
      'date': '18 Apr 2027',
      'days': 263,
    },
    {
      'name': 'State Exams',
      'icon': Icons.public_rounded,
      'color': const Color(0xFFEC4899),
      'date': '15 Dec 2026',
      'days': 139,
    },
    {
      'name': 'Boards',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFFE11D48),
      'date': '15 Feb 2027',
      'days': 201,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null && user.targetExam.isNotEmpty && user.targetExam != 'General') {
        final match = _examsList.any((e) => e['name'] == user.targetExam);
        if (match) {
          setState(() {
            _selectedExam = user.targetExam;
          });
        }
      }
    });
  }

  Map<String, dynamic> _getCurrentExamData() {
    return _examsList.firstWhere(
      (e) => e['name'] == _selectedExam,
      orElse: () => _examsList.first,
    );
  }

  void _selectExam(String examName) {
    if (_selectedExam == examName) return;
    setState(() {
      _selectedExam = examName;
    });
    Provider.of<UserProvider>(context, listen: false).updateTargetExam(examName);
    FirestoreService().updateTargetExam(examName);
    widget.onExamChanged?.call(examName);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Target exam updated to $examName!',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0070F3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showExamSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF071326),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.track_changes_rounded, color: Color(0xFF38BDF8), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Select Target Exam',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _examsList.length,
                  separatorBuilder: (context, index) => const Divider(color: Color(0xFF142B4D), height: 1),
                  itemBuilder: (context, index) {
                    final exam = _examsList[index];
                    final isSel = exam['name'] == _selectedExam;
                    final Color examColor = exam['color'] as Color;

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: examColor.withValues(alpha: 0.18),
                        child: Icon(exam['icon'] as IconData, color: examColor, size: 17),
                      ),
                      title: Text(
                        exam['name'] as String,
                        style: TextStyle(
                          color: isSel ? const Color(0xFF38BDF8) : Colors.white,
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      subtitle: Text(
                        '${exam['date']} • ${exam['days']} Days Left',
                        style: const TextStyle(color: Colors.white54, fontSize: 10.5),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 20)
                          : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 13),
                      onTap: () {
                        Navigator.pop(context);
                        _selectExam(exam['name'] as String);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentExam = _getCurrentExamData();
    final Color examColor = currentExam['color'] as Color;
    final int daysLeft = currentExam['days'] as int;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF071836), Color(0xFF091F44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A68), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0070F3).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Brand/Goal tag + Streak & Days Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0070F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'Examinantt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0070F3).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0070F3).withValues(alpha: 0.4)),
                    ),
                    child: const Text(
                      'PREP HUB',
                      style: TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Streak badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF152A4A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF28487A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 12),
                        SizedBox(width: 3),
                        Text(
                          '12d Streak',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  // Countdown pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFFFB923C), size: 11),
                        const SizedBox(width: 3),
                        Text(
                          '${daysLeft}d Left',
                          style: const TextStyle(
                            color: Color(0xFFFB923C),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Target Exam Hero Bar (Sleek Dark Glassmorphism, NO harsh white)
          GestureDetector(
            onTap: _showExamSelectionModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2244),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E3F75)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: examColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(currentExam['icon'] as IconData, color: examColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedExam,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF38BDF8), size: 16),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            const Icon(Icons.event_available_rounded, color: Colors.white54, size: 10),
                            const SizedBox(width: 3),
                            Text(
                              currentExam['date'] as String,
                              style: const TextStyle(color: Colors.white60, fontSize: 9.5, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: Colors.white30, fontSize: 9)),
                            const SizedBox(width: 6),
                            const Text(
                              'Target: Top 100 Rank',
                              style: TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0070F3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swap_vert_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 3),
                        Text(
                          'Switch',
                          style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Row 3: Today's Focus Bar (Tight, Motivational)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF061327).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF162D50)),
            ),
            child: const Row(
              children: [
                Icon(Icons.track_changes_rounded, color: Colors.amber, size: 13),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Focus: Consistency over intensity. Keep learning! 🚀',
                    style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 4: Quick Exam Selector Chips (Horizontal 1-tap pills)
          SizedBox(
            height: 28,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _examsList.length,
              itemBuilder: (context, index) {
                final exam = _examsList[index];
                final isSel = exam['name'] == _selectedExam;
                final Color chipColor = exam['color'] as Color;

                return GestureDetector(
                  onTap: () => _selectExam(exam['name'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: isSel
                          ? const LinearGradient(
                              colors: [Color(0xFF0070F3), Color(0xFF0052CC)],
                            )
                          : null,
                      color: isSel ? null : const Color(0xFF0D2244),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSel ? const Color(0xFF38BDF8) : const Color(0xFF1B3864),
                        width: isSel ? 1.2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSel) ...[
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 11),
                          const SizedBox(width: 4),
                        ] else ...[
                          Icon(exam['icon'] as IconData, color: chipColor, size: 11),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          exam['name'] as String,
                          style: TextStyle(
                            color: isSel ? Colors.white : Colors.white70,
                            fontSize: 10,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
