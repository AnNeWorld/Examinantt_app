import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/test_service.dart';
import '../services/firestore_service.dart';
import '../models/test_model.dart';
import 'quiz_screen.dart';
import '../services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants/app_colors.dart';

class TestSeriesDetailScreen extends StatefulWidget {
  final String categoryId;
  final String title;
  final String badge;
  final String price;
  final String originalPrice;
  final List<String> features;
  final Color badgeColor;
  final String imageUrl;
  final bool isPurchased;

  const TestSeriesDetailScreen({
    super.key,
    required this.categoryId,
    required this.title,
    required this.badge,
    required this.price,
    required this.originalPrice,
    required this.features,
    required this.badgeColor,
    required this.imageUrl,
    this.isPurchased = false,
  });

  @override
  State<TestSeriesDetailScreen> createState() => _TestSeriesDetailScreenState();
}

class _TestSeriesDetailScreenState extends State<TestSeriesDetailScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isPurchased = false;
  bool _isCourse = false;

  // Active filters and tab indexes
  int _activeSubTabIndex = 0; // 0: Chapter, 1: Unit, 2: Subject, 3: Full Length
  String _selectedSubject = 'All Subjects';
  String _selectedStatus = 'All Status';
  String _selectedDifficulty = 'All Difficulty';
  String _selectedSort = 'Sort by: Newest';

  final List<String> _subTabs = [
    'All Tests',
    'Chapter Tests',
    'Unit Tests',
    'Subject Tests',
    'Full Length Tests'
  ];

  List<TestResult> _userResults = [];
  bool _loadingResults = true;

  @override
  void initState() {
    super.initState();
    _isPurchased = widget.isPurchased || widget.price == '0' || widget.price == '0.0';
    _checkIfCourse();
    _fetchUserResults();

    _paymentService.initialize(
      onSuccess: (PaymentSuccessResponse response) async {
        final price = double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 499.0;
        try {
          await FirestoreService().addPurchase(
            id: widget.categoryId.isNotEmpty ? widget.categoryId : 'series_${DateTime.now().millisecondsSinceEpoch}',
            title: widget.title,
            type: 'Test Series',
            price: price,
          );
          await FirestoreService().addNotification(
            title: 'Test Series Unlocked 🎉',
            subtitle: 'Successfully purchased ${widget.title} via Razorpay!',
          );
        } catch (e) {
          debugPrint('[TestSeriesDetailScreen] Error recording purchase: $e');
        }
        setState(() {
          _isPurchased = true;
        });
        if (!mounted) return;
        AppTheme.showSuccessSnackBar(context, 'Payment Successful! Series Unlocked.');
      },
      onFailure: (PaymentFailureResponse response) {
        FirestoreService().addNotification(
          title: 'Payment Cancelled/Failed ❌',
          subtitle: 'Attempt to unlock ${widget.title} was cancelled or failed.',
        );
        AppTheme.showErrorSnackBar(
          context,
          'Payment Failed: ${response.message ?? "User cancelled or transaction failed"}',
        );
      },
      onExternalWallet: (ExternalWalletResponse response) {
        AppTheme.showSuccessSnackBar(context, 'External Wallet: ${response.walletName ?? ""}');
      },
    );
  }

  void _checkIfCourse() async {
    try {
      final modules = await TestService().getCourseModules(widget.categoryId);
      if (mounted && modules.isNotEmpty) {
        setState(() {
          _isCourse = true;
        });
      }
    } catch (_) {}
  }

  void _fetchUserResults() async {
    TestService().getRecentTestResults('local_user', limit: null).listen((results) {
      if (mounted) {
        setState(() {
          _userResults = results;
          _loadingResults = false;
        });
      }
    }, onError: (err) {
      if (mounted) {
        setState(() {
          _loadingResults = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final appBarBg = isDark ? const Color(0xFF00122C) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? null : AppTheme.backgroundLight,
        gradient: isDark
            ? const LinearGradient(
                colors: [Color(0xFF001638), Color(0xFF000F29)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold),
          ),
          iconTheme: IconThemeData(color: textColor),
          backgroundColor: appBarBg,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // Promo banner
                    SliverToBoxAdapter(
                      child: _buildBannerCard(),
                    ),

                    // Navigation Tabs inside Syllabus
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Text(
                              'Syllabus & Course Content',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          _buildSubTabs(),
                          _buildFilterRow(),
                        ],
                      ),
                    ),

                    // Test list or modules accordion
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      sliver: _isCourse
                          ? _buildCourseModulesList()
                          : _buildTestsList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFree = widget.price == '0' || widget.price == '0.0';
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.badgeColor),
                ),
                child: Text(
                  widget.badge,
                  style: TextStyle(color: widget.badgeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              if (_isPurchased)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check, color: Colors.green, size: 12),
                      SizedBox(width: 4),
                      Text('Unlocked', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isFree ? 'FREE' : '₹${widget.price}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.accent),
              ),
              if (!isFree) ...[
                const SizedBox(width: 8),
                Text(
                  '₹${widget.originalPrice}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textDarkSecondary, decoration: TextDecoration.lineThrough),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ...widget.features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(f, style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_isPurchased)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                  PaymentService().payAndUnlock(
                    context: context,
                    title: widget.title,
                    price: amount,
                    itemType: 'Test Series',
                    subtitle: 'Full access to all chapter tests, part mocks and All-India level test series',
                    onSuccess: () {
                      if (mounted) {
                        setState(() {
                          _isPurchased = true;
                        });
                      }
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Unlock Series Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _subTabs.length,
        itemBuilder: (context, index) {
          final isSelected = _activeSubTabIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeSubTabIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.accent : Colors.white12),
                ),
                child: Text(
                  _subTabs[index],
                  style: TextStyle(
                    color: isSelected ? AppColors.accent : AppColors.textDarkSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterDropdown(
              value: _selectedSubject,
              items: ['All Subjects', 'Physics', 'Chemistry', 'Mathematics'],
              onChanged: (val) => setState(() => _selectedSubject = val!),
            ),
            const SizedBox(width: 8),
            _buildFilterDropdown(
              value: _selectedStatus,
              items: ['All Status', 'Completed', 'Attempted', 'Not Attempted', 'Locked'],
              onChanged: (val) => setState(() => _selectedStatus = val!),
            ),
            const SizedBox(width: 8),
            _buildFilterDropdown(
              value: _selectedDifficulty,
              items: ['All Difficulty', 'Easy', 'Medium', 'Hard'],
              onChanged: (val) => setState(() => _selectedDifficulty = val!),
            ),
            const SizedBox(width: 8),
            _buildFilterDropdown(
              value: _selectedSort,
              items: ['Sort by: Newest', 'Sort by: Oldest', 'Sort by: Title'],
              onChanged: (val) => setState(() => _selectedSort = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButton<String>(
        value: value,
        dropdownColor: cardBg,
        underline: const SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white54 : Colors.grey, size: 18),
        style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
        items: items.map<DropdownMenuItem<String>>((String val) {
          return DropdownMenuItem<String>(value: val, child: Text(val, style: TextStyle(color: textColor)));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCourseModulesList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: TestService().getCourseModules(widget.categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        final modules = snapshot.data ?? [];
        if (modules.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'No course modules uploaded yet.',
                style: TextStyle(color: AppColors.textDarkSecondary),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, idx) {
              final item = modules[idx];
              return ModuleAccordionWidget(
                courseId: widget.categoryId,
                moduleId: item['id'] as String? ?? 'm_${idx + 1}',
                title: item['title'] as String? ?? 'Module ${idx + 1}',
                index: idx + 1,
                totalLessons: item['totalLessons'] as int? ?? 0,
                isPurchased: _isPurchased,
              );
            },
            childCount: modules.length,
          ),
        );
      },
    );
  }

  Widget _buildTestsList() {
    return StreamBuilder<List<MockTest>>(
      stream: TestService().getTestsByCategoryStream(widget.categoryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _loadingResults) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'No tests available in this category yet.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        final originalTests = snapshot.data!;
        final List<MockTest> processedTests = [];

        final double packagePrice = double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

        for (int i = 0; i < originalTests.length; i++) {
          final test = originalTests[i];
          final bool isPremiumTest = (packagePrice > 0) ? (i >= 2) : false;

          String testTitle = test.title;
          

          processedTests.add(
            MockTest(
              id: test.id,
              categoryId: test.categoryId,
              title: testTitle,
              description: test.description,
              durationMinutes: test.durationMinutes,
              totalMarks: test.totalMarks,
              totalQuestions: test.totalQuestions,
              isPremium: isPremiumTest,
            ),
          );
        }

        // DYNAMIC CLASSIFICATION & SUBJECT INFERENCE
        final filteredTests = processedTests.where((test) {
          // Tab navigation filter
          if (_activeSubTabIndex > 0) {
            String testType = "Chapter Tests";
            final titleLower = test.title.toLowerCase();
            final descLower = test.description.toLowerCase();
            if (titleLower.contains("unit") || descLower.contains("unit")) {
              testType = "Unit Tests";
            } else if (titleLower.contains("subject") || descLower.contains("subject")) {
              testType = "Subject Tests";
            } else if (titleLower.contains("full") || titleLower.contains("mock") || descLower.contains("mock") || descLower.contains("full")) {
              testType = "Full Length Tests";
            } else if (titleLower.contains("chapter") || descLower.contains("chapter")) {
              testType = "Chapter Tests";
            } else {
              testType = "Chapter Tests";
            }
            if (_subTabs[_activeSubTabIndex] != testType) return false;
          }

          // Subject filter
          if (_selectedSubject != 'All Subjects') {
            final subLower = _selectedSubject.length >= 4 
                ? _selectedSubject.substring(0, 4).toLowerCase() 
                : _selectedSubject.toLowerCase();
            if (!test.title.toLowerCase().contains(subLower) && !test.description.toLowerCase().contains(subLower)) return false;
          }

          // Difficulty filter
          if (_selectedDifficulty != 'All Difficulty') {
            final descDiff = test.description.toLowerCase();
            final matchesDiff = descDiff.contains(_selectedDifficulty.toLowerCase());
            if (!matchesDiff && _selectedDifficulty != 'Medium') return false;
          }

          // Status filter
          final hasResult = _userResults.any((r) => r.testId == test.id);
          final isLocked = !_isPurchased && test.isPremium;
          String status = 'Not Attempted';
          if (isLocked) {
            status = 'Locked';
          } else if (hasResult) {
            status = 'Completed';
          }

          if (_selectedStatus != 'All Status') {
            if (_selectedStatus == 'Completed' && status != 'Completed') return false;
            if (_selectedStatus == 'Attempted' && status != 'Completed') return false;
            if (_selectedStatus == 'Not Attempted' && status != 'Not Attempted') return false;
            if (_selectedStatus == 'Locked' && status != 'Locked') return false;
          }

          return true;
        }).toList();

        // Sort items
        if (_selectedSort == 'Sort by: Title') {
          filteredTests.sort((a, b) => a.title.compareTo(b.title));
        } else if (_selectedSort == 'Sort by: Oldest') {
          // Keep original order
        } else {
          // Newest / default order (reverse of list)
          filteredTests.sort((a, b) => b.id.compareTo(a.id));
        }

        if (filteredTests.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_outlined, size: 48, color: Colors.white38),
                    const SizedBox(height: 12),
                    Text(
                      'No tests match the "${_subTabs[_activeSubTabIndex]}" filter.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    if (processedTests.isNotEmpty && _activeSubTabIndex > 0) ...[
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => setState(() => _activeSubTabIndex = 0),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                        child: Text('View All (${processedTests.length}) Tests', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, idx) {
              final test = filteredTests[idx];
              final testIndex = processedTests.indexOf(test);

              // Determine final status
              final hasResult = _userResults.any((r) => r.testId == test.id);
              final isPremiumLocked = !_isPurchased && test.isPremium;

              String statusLabel = 'Not Attempted';
              Color statusColor = Colors.white54;
              Widget actionButton;

              if (isPremiumLocked) {
                statusLabel = 'Premium Locked';
                statusColor = Colors.amber;
                actionButton = _buildDisabledLockedButton('Locked');
              } else if (hasResult) {
                final res = _userResults.firstWhere((r) => r.testId == test.id);
                final totalQs = res.correctAnswers + res.wrongAnswers + res.skippedAnswers;
                final scorePerc = totalQs > 0 
                    ? (res.score / (totalQs * 4) * 100).toStringAsFixed(0)
                    : '0';
                if (testIndex % 2 == 0) {
                  statusLabel = 'Completed • Score: ${res.score}/${totalQs * 4} ($scorePerc%)';
                  statusColor = Colors.green;
                  actionButton = _buildOutlineActionButton('View Result >', Colors.green, () {
                    // Navigate to results if implemented, else view summary dialog
                    _showResultDialog(context, test.title, res);
                  });
                } else {
                  statusLabel = 'Attempted • Score: ${res.score}/${totalQs * 4} ($scorePerc%)';
                  statusColor = Colors.blue;
                  actionButton = _buildOutlineActionButton('Reattempt >', Colors.blue, () {
                    _startTest(test);
                  });
                }
              } else {
                statusLabel = 'Not Attempted';
                statusColor = Colors.white54;
                actionButton = _buildOutlineActionButton('Start Test >', AppColors.accent, () {
                  _startTest(test);
                });
              }

              final diff = testIndex % 3 == 0 ? 'Easy' : (testIndex % 3 == 1 ? 'Medium' : 'Hard');
              final diffColor = diff == 'Easy' ? Colors.green : (diff == 'Medium' ? Colors.orange : Colors.red);

              final isDark = Theme.of(context).brightness == Brightness.dark;
              final String categoryBadgeLabel = test.description.isNotEmpty 
                  ? test.description 
                  : (_activeSubTabIndex == 0 ? 'Mock Test' : _subTabs[_activeSubTabIndex].replaceAll(' Tests', ' Test'));

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Badges
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                categoryBadgeLabel,
                                style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: diffColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                diff,
                                style: TextStyle(color: diffColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        // Status Text
                        Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      test.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${test.totalQuestions} Questions • ${test.durationMinutes} Minutes',
                      style: const TextStyle(color: AppColors.textDarkSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: actionButton),
                  ],
                ),
              );
            },
            childCount: filteredTests.length,
          ),
        );
      },
    );
  }

  Widget _buildOutlineActionButton(String label, Color color, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildDisabledLockedButton(String label) {
    return OutlinedButton.icon(
      onPressed: () {
        if (!_isPurchased) {
          AppTheme.showErrorSnackBar(context, 'Unlock the premium test series first!');
        } else {
          AppTheme.showErrorSnackBar(context, 'Complete previous tests in sequence to unlock!');
        }
      },
      icon: const Icon(Icons.lock, size: 14, color: Colors.white30),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        foregroundColor: Colors.white30,
      ),
    );
  }



  void _startTest(MockTest test) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(testId: test.id, testName: test.title),
      ),
    ).then((_) {
      _fetchUserResults(); // Refresh completion indicators when returning
    });
  }

  void _showResultDialog(BuildContext context, String testName, TestResult res) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accuracyStr = res.accuracy.toStringAsFixed(1);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF141C2F) : Colors.white,
        title: Text(testName, style: TextStyle(color: isDark ? Colors.white : AppTheme.darkSlate, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultDialogRow(isDark, 'Marks Obtained', '${res.score} / ${(res.correctAnswers + res.wrongAnswers + res.skippedAnswers) * 4}'),
              const SizedBox(height: 8),
              _buildResultDialogRow(isDark, 'Accuracy', '$accuracyStr%'),
              const SizedBox(height: 8),
              _buildResultDialogRow(isDark, 'Time Spent', '${res.timeTakenSeconds ~/ 60}m ${res.timeTakenSeconds % 60}s'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultDialogRow(bool isDark, String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: isDark ? AppColors.textDarkSecondary : AppColors.textLight, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(val, style: TextStyle(color: isDark ? Colors.white : AppTheme.darkSlate, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

class ModuleAccordionWidget extends StatefulWidget {
  final String courseId;
  final String moduleId;
  final String title;
  final int index;
  final int totalLessons;
  final bool isPurchased;

  const ModuleAccordionWidget({
    super.key,
    required this.courseId,
    required this.moduleId,
    required this.title,
    required this.index,
    required this.totalLessons,
    required this.isPurchased,
  });

  @override
  State<ModuleAccordionWidget> createState() => _ModuleAccordionWidgetState();
}

class _ModuleAccordionWidgetState extends State<ModuleAccordionWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0A1E3F) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          leading: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${widget.index}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          title: Text(
            widget.title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            '${widget.totalLessons} Practice Tests',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white70,
          ),
          children: [
            Builder(
              builder: (context) {
                final mockTests = [
                  {'title': 'Mock Test 1: Chapter Practice & Quiz', 'durationMinutes': 30, 'totalQuestions': 25, 'isFree': true},
                  {'title': 'Mock Test 2: Core Concepts & Speed Test', 'durationMinutes': 45, 'totalQuestions': 40, 'isFree': false},
                  {'title': 'Mock Test 3: Full Length Comprehensive Mock', 'durationMinutes': 60, 'totalQuestions': 50, 'isFree': false},
                ];

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: mockTests.length,
                  itemBuilder: (context, index) {
                    final testData = mockTests[index];
                    final testTitle = testData['title'] as String;
                    final durationVal = testData['durationMinutes'] as int;
                    final totalQ = testData['totalQuestions'] as int;
                    final isTestFree = testData['isFree'] == true;
                    final isLocked = !widget.isPurchased && !isTestFree;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: Icon(
                        isLocked ? Icons.lock : Icons.assignment_turned_in_rounded,
                        color: isLocked ? Colors.grey : AppColors.accent,
                        size: 24,
                      ),
                      title: Text(
                        testTitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '$totalQ Questions • $durationVal Mins',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      trailing: isLocked
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.play_arrow_rounded, size: 20, color: AppColors.accent),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizScreen(
                                      testId: 'mod_test_${widget.courseId}_$index',
                                      testName: testTitle,
                                    ),
                                  ),
                                );
                              },
                            ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


