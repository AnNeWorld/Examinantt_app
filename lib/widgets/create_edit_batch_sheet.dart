import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../models/test_model.dart';
import '../services/firestore_service.dart';
import '../services/test_service.dart';
import '../utils/app_theme.dart';

/// Modal Sheet / Dialog to Create or Edit a Batch with Test Series & Resources attachment
class CreateEditBatchSheet extends StatefulWidget {
  final CourseModel? existingBatch;

  const CreateEditBatchSheet({super.key, this.existingBatch});

  static Future<void> show(BuildContext context, {CourseModel? existingBatch}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateEditBatchSheet(existingBatch: existingBatch),
    );
  }

  @override
  State<CreateEditBatchSheet> createState() => _CreateEditBatchSheetState();
}

class _CreateEditBatchSheetState extends State<CreateEditBatchSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _shortDescController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _originalPriceController;
  late TextEditingController _instructorNameController;
  late TextEditingController _instructorTitleController;
  late TextEditingController _validityController;
  late TextEditingController _bannerUrlController;

  String _selectedExamCategory = 'JEE Main 2027';
  final List<String> _examOptions = [
    'JEE Main 2027',
    'NEET UG 2027',
    'SSC CGL 2027',
    'CUET UG (Science)',
    'CUET UG (General)',
    'UPSC CSE',
    'CBSE Class 12',
    'CBSE Class 11',
    'General',
  ];

  late Set<String> _selectedTestSeriesIds;
  late Set<String> _selectedResourceIds;

  bool _isSaving = false;
  String _testSeriesSearch = '';
  String _resourceSearch = '';

  @override
  void initState() {
    super.initState();
    final b = widget.existingBatch;
    _titleController = TextEditingController(text: b?.title ?? '');
    _shortDescController = TextEditingController(text: b?.shortDescription ?? '');
    _descController = TextEditingController(text: b?.description ?? '');
    _priceController = TextEditingController(text: b != null ? b.price.toStringAsFixed(0) : '1999');
    _originalPriceController = TextEditingController(text: b != null ? b.originalPrice.toStringAsFixed(0) : '4999');
    _instructorNameController = TextEditingController(text: b?.instructorName ?? 'Examinant Master Faculty');
    _instructorTitleController = TextEditingController(text: b?.instructorTitle ?? 'Senior Educator & Mentor');
    _validityController = TextEditingController(text: b?.validity ?? 'Till Exam Day');
    _bannerUrlController = TextEditingController(text: b?.bannerUrl ?? '');

    if (b != null && b.examCategory.isNotEmpty) {
      if (_examOptions.contains(b.examCategory)) {
        _selectedExamCategory = b.examCategory;
      } else {
        _examOptions.insert(0, b.examCategory);
        _selectedExamCategory = b.examCategory;
      }
    }

    _selectedTestSeriesIds = Set.from(b?.testSeriesIds ?? []);
    _selectedResourceIds = Set.from(b?.resourceIds ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _instructorNameController.dispose();
    _instructorTitleController.dispose();
    _validityController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final isEditing = widget.existingBatch != null;
      final batchId = isEditing
          ? widget.existingBatch!.id
          : 'batch_${DateTime.now().millisecondsSinceEpoch}';

      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final originalPrice = double.tryParse(_originalPriceController.text.trim()) ?? (price * 2.5);

      final newBatch = CourseModel(
        id: batchId,
        title: _titleController.text.trim(),
        shortDescription: _shortDescController.text.trim(),
        description: _descController.text.trim(),
        examCategory: _selectedExamCategory,
        price: price,
        originalPrice: originalPrice,
        instructorName: _instructorNameController.text.trim(),
        instructorTitle: _instructorTitleController.text.trim(),
        validity: _validityController.text.trim(),
        bannerUrl: _bannerUrlController.text.trim(),
        thumbnailUrl: _bannerUrlController.text.trim(),
        status: 'published',
        testSeriesIds: _selectedTestSeriesIds.toList(),
        resourceIds: _selectedResourceIds.toList(),
        totalModules: 12,
        totalLessons: 48,
        features: [
          'Full Syllabus Coverage',
          'Interactive Live Classes',
          '${_selectedResourceIds.length} Study Resources & Notes',
          '${_selectedTestSeriesIds.length} Mock Test Series Included',
          '24/7 Doubt Resolution',
        ],
      );

      await FirestoreService().saveBatch(
        newBatch,
        isEditing: isEditing,
        previousResourceIds: widget.existingBatch?.resourceIds,
      );

      if (!mounted) return;
      Navigator.pop(context);
      AppTheme.showSuccessSnackBar(
        context,
        isEditing ? 'Batch "${newBatch.title}" updated successfully!' : 'Batch "${newBatch.title}" created successfully!',
      );
    } catch (e) {
      if (!mounted) return;
      AppTheme.showErrorSnackBar(context, 'Failed to save batch: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingBatch != null;

    final bgColor = isDark ? const Color(0xFF071428) : Colors.white;
    final cardBg = isDark ? const Color(0xFF0C2040) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final subTextColor = isDark ? Colors.white60 : Colors.grey.shade600;
    final borderColor = isDark ? const Color(0xFF1E3A68) : Colors.grey.shade300;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0070F3).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                    color: const Color(0xFF0070F3),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Batch' : 'Create New Batch',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'Update batch details, test series, and resources'
                            : 'Fill details and attach Test Series & Resources',
                        style: TextStyle(color: subTextColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: textColor),
                ),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1),

          // Scrollable Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: BATCH BASIC INFO ---
                    _buildSectionHeader('1. Batch Details', Icons.info_outline_rounded, isDark),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _titleController,
                      label: 'Batch Title *',
                      hint: 'e.g. Selection Batch 2027 • Complete Prep',
                      isDark: isDark,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter batch title' : null,
                    ),
                    const SizedBox(height: 12),

                    _buildDropdown(
                      label: 'Target Exam Category *',
                      value: _selectedExamCategory,
                      items: _examOptions,
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedExamCategory = val);
                      },
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price (₹) *',
                            hint: '1999',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _originalPriceController,
                            label: 'Original Price (₹)',
                            hint: '4999',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _instructorNameController,
                            label: 'Lead Faculty / Educator',
                            hint: 'e.g. Raj Sir & Team',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _validityController,
                            label: 'Batch Validity',
                            hint: 'e.g. Till Exam Day',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _shortDescController,
                      label: 'Short Summary / Subtitle',
                      hint: 'Complete preparation with live classes, mock tests & formula guides.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _descController,
                      label: 'Detailed Description',
                      hint: 'Describe syllabus, schedule, mentorship, target rank goals...',
                      maxLines: 3,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION 2: ATTACH TEST SERIES ---
                    _buildSectionHeader(
                      '2. Attach Test Series (${_selectedTestSeriesIds.length} Selected)',
                      Icons.assignment_outlined,
                      isDark,
                      trailingBadge: '${_selectedTestSeriesIds.length} attached',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select one or multiple Test Series to include inside this Batch:',
                      style: TextStyle(color: subTextColor, fontSize: 11),
                    ),
                    const SizedBox(height: 10),

                    // Search box for Test Series
                    _buildSearchInput(
                      hint: 'Search test series by name or exam...',
                      isDark: isDark,
                      onChanged: (val) => setState(() => _testSeriesSearch = val.toLowerCase()),
                    ),
                    const SizedBox(height: 10),

                    // Test Series Picker from Firebase
                    StreamBuilder<List<TestCategory>>(
                      stream: TestService().getCategoriesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                        }

                        var seriesList = snapshot.data ?? [];
                        if (_testSeriesSearch.isNotEmpty) {
                          seriesList = seriesList.where((s) =>
                              s.title.toLowerCase().contains(_testSeriesSearch) ||
                              s.examCategory.toLowerCase().contains(_testSeriesSearch)).toList();
                        }

                        if (seriesList.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Center(
                              child: Text(
                                _testSeriesSearch.isEmpty ? 'No Test Series found in database' : 'No matching Test Series',
                                style: TextStyle(color: subTextColor, fontSize: 12),
                              ),
                            ),
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: seriesList.length,
                            separatorBuilder: (_, index) => Divider(color: borderColor, height: 1),
                            itemBuilder: (context, idx) {
                              final item = seriesList[idx];
                              final isSelected = _selectedTestSeriesIds.contains(item.id);

                              return CheckboxListTile(
                                value: isSelected,
                                dense: true,
                                activeColor: const Color(0xFF0070F3),
                                checkColor: Colors.white,
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${item.examCategory} • ${item.testsCount}',
                                  style: TextStyle(color: subTextColor, fontSize: 10.5),
                                ),
                                secondary: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0070F3).withValues(alpha: 0.2)
                                        : Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.badge,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF38BDF8) : subTextColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedTestSeriesIds.add(item.id);
                                    } else {
                                      _selectedTestSeriesIds.remove(item.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION 3: ATTACH RESOURCES ---
                    _buildSectionHeader(
                      '3. Attach Resources (${_selectedResourceIds.length} Selected)',
                      Icons.folder_special_outlined,
                      isDark,
                      trailingBadge: '${_selectedResourceIds.length} attached',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select one or multiple Study Resources, Notes, or PDFs for this Batch:',
                      style: TextStyle(color: subTextColor, fontSize: 11),
                    ),
                    const SizedBox(height: 10),

                    // Search box for Resources
                    _buildSearchInput(
                      hint: 'Search resources by title, subject or chapter...',
                      isDark: isDark,
                      onChanged: (val) => setState(() => _resourceSearch = val.toLowerCase()),
                    ),
                    const SizedBox(height: 10),

                    // Resources Picker from Firebase
                    StreamBuilder<List<ResourceItem>>(
                      stream: FirestoreService().getResourcesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                        }

                        var resourcesList = snapshot.data ?? [];
                        if (_resourceSearch.isNotEmpty) {
                          resourcesList = resourcesList.where((r) =>
                              r.title.toLowerCase().contains(_resourceSearch) ||
                              r.subject.toLowerCase().contains(_resourceSearch) ||
                              r.category.toLowerCase().contains(_resourceSearch)).toList();
                        }

                        if (resourcesList.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Center(
                              child: Text(
                                _resourceSearch.isEmpty ? 'No Resources found in database' : 'No matching Resources',
                                style: TextStyle(color: subTextColor, fontSize: 12),
                              ),
                            ),
                          );
                        }

                        return Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: resourcesList.length,
                            separatorBuilder: (_, index) => Divider(color: borderColor, height: 1),
                            itemBuilder: (context, idx) {
                              final res = resourcesList[idx];
                              final isSelected = _selectedResourceIds.contains(res.id);

                              return CheckboxListTile(
                                value: isSelected,
                                dense: true,
                                activeColor: const Color(0xFF10B981),
                                checkColor: Colors.white,
                                title: Text(
                                  res.title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${res.subject} • ${res.type} • ${res.fileSize}',
                                  style: TextStyle(color: subTextColor, fontSize: 10.5),
                                ),
                                secondary: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                        : Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    res.fileType,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF10B981) : subTextColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedResourceIds.add(res.id);
                                    } else {
                                      _selectedResourceIds.remove(res.id);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // --- SAVE BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: Text(
                          _isSaving
                              ? 'Saving Batch...'
                              : (isEditing ? 'Save Changes' : 'Create & Publish Batch'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0070F3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark, {String? trailingBadge}) {
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0070F3), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ),
        if (trailingBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0070F3).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF0070F3).withValues(alpha: 0.3)),
            ),
            child: Text(
              trailingBadge,
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 9.5, fontWeight: FontWeight.w800),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final fillColor = isDark ? const Color(0xFF0B1E38) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF1E3A68) : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: textColor, fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: hintColor, fontSize: 12),
            filled: true,
            fillColor: fillColor,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF0070F3), width: 1.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final fillColor = isDark ? const Color(0xFF0B1E38) : Colors.grey.shade50;
    final borderColor = isDark ? const Color(0xFF1E3A68) : Colors.grey.shade300;
    final dropDownBg = isDark ? const Color(0xFF071428) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: textColor, fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              dropdownColor: dropDownBg,
              icon: Icon(Icons.arrow_drop_down, color: textColor),
              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
              onChanged: onChanged,
              items: items.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt, style: TextStyle(color: textColor, fontSize: 13)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInput({
    required String hint,
    required bool isDark,
    required ValueChanged<String> onChanged,
  }) {
    final textColor = isDark ? Colors.white : AppTheme.darkSlate;
    final hintColor = isDark ? Colors.white38 : Colors.grey.shade400;
    final fillColor = isDark ? const Color(0xFF081932) : Colors.grey.shade100;
    final borderColor = isDark ? const Color(0xFF1E3A68) : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: textColor, fontSize: 12),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: hintColor, fontSize: 11.5),
          prefixIcon: Icon(Icons.search, size: 18, color: hintColor),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
      ),
    );
  }
}
