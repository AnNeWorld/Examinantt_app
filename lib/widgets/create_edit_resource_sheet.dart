import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';

/// Modal Sheet / Dialog to Create or Edit a Study Resource with multi-batch assignment
class CreateEditResourceSheet extends StatefulWidget {
  final ResourceItem? existingResource;
  final String? preselectedBatchId;

  const CreateEditResourceSheet({
    super.key,
    this.existingResource,
    this.preselectedBatchId,
  });

  static Future<void> show(
    BuildContext context, {
    ResourceItem? existingResource,
    String? preselectedBatchId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateEditResourceSheet(
        existingResource: existingResource,
        preselectedBatchId: preselectedBatchId,
      ),
    );
  }

  @override
  State<CreateEditResourceSheet> createState() => _CreateEditResourceSheetState();
}

class _CreateEditResourceSheetState extends State<CreateEditResourceSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _priceController;
  late TextEditingController _fileSizeController;

  String _selectedSubject = 'Physics';
  final List<String> _subjects = [
    'Physics',
    'Chemistry',
    'Mathematics',
    'Biology',
    'General Awareness',
    'English',
    'Logical Reasoning',
  ];

  String _selectedType = 'Notes';
  final List<String> _types = [
    'Notes',
    'Formula Sheet',
    'Mind Map',
    'PYQ',
    'Curriculum',
    'Practice',
    'Reference Guide',
  ];

  String _selectedBadge = 'INCLUDED';
  final List<String> _badges = ['INCLUDED', 'FREE', 'PREMIUM'];

  late Set<String> _selectedBatchIds;
  bool _isSaving = false;
  String _batchSearch = '';

  @override
  void initState() {
    super.initState();
    final r = widget.existingResource;
    _titleController = TextEditingController(text: r?.title ?? '');
    _subtitleController = TextEditingController(text: r?.subtitle ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _urlController = TextEditingController(
      text: r?.url ?? 'https://ncert.nic.in/textbook/pdf/keph101.pdf',
    );
    _priceController = TextEditingController(text: r != null ? r.price.toStringAsFixed(0) : '0');
    _fileSizeController = TextEditingController(text: r?.fileSize ?? '3.2 MB');

    if (r != null && r.subject.isNotEmpty) {
      if (_subjects.contains(r.subject)) {
        _selectedSubject = r.subject;
      } else {
        _subjects.insert(0, r.subject);
        _selectedSubject = r.subject;
      }
    }

    if (r != null && r.type.isNotEmpty && _types.contains(r.type)) {
      _selectedType = r.type;
    }

    if (r != null && r.badge.isNotEmpty && _badges.contains(r.badge.toUpperCase())) {
      _selectedBadge = r.badge.toUpperCase();
    }

    _selectedBatchIds = Set.from(r?.batchIds ?? []);
    if (widget.preselectedBatchId != null && widget.preselectedBatchId!.isNotEmpty) {
      _selectedBatchIds.add(widget.preselectedBatchId!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _priceController.dispose();
    _fileSizeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final isEditing = widget.existingResource != null;
      final resId = isEditing
          ? widget.existingResource!.id
          : 'res_${DateTime.now().millisecondsSinceEpoch}';

      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final badgeColor = _selectedBadge == 'INCLUDED'
          ? '#34D399'
          : (_selectedBadge == 'FREE' ? '#38BDF8' : '#FFA000');

      final newResource = ResourceItem(
        id: resId,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isNotEmpty
            ? _subtitleController.text.trim()
            : '$_selectedSubject • $_selectedType',
        description: _descriptionController.text.trim(),
        category: _selectedSubject,
        subject: _selectedSubject,
        type: _selectedType,
        url: _urlController.text.trim(),
        price: price,
        isPublic: price == 0.0 || _selectedBadge != 'PREMIUM',
        badge: _selectedBadge,
        badgeColorHex: badgeColor,
        fileType: 'PDF',
        fileSize: _fileSizeController.text.trim().isNotEmpty ? _fileSizeController.text.trim() : '2.8 MB',
        downloads: widget.existingResource?.downloads ?? '12.4k',
        rating: widget.existingResource?.rating ?? 4.8,
        batchIds: _selectedBatchIds.toList(),
      );

      await FirestoreService().saveResource(
        newResource,
        isEditing: isEditing,
        previousBatchIds: widget.existingResource?.batchIds,
      );

      if (!mounted) return;
      Navigator.pop(context);
      AppTheme.showSuccessSnackBar(
        context,
        isEditing
            ? 'Resource "${newResource.title}" updated!'
            : 'Resource "${newResource.title}" added to ${_selectedBatchIds.length} batch(es)!',
      );
    } catch (e) {
      if (!mounted) return;
      AppTheme.showErrorSnackBar(context, 'Failed to save resource: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.existingResource != null;

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
          // Drag Handle
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_document : Icons.note_add_rounded,
                    color: const Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Resource' : 'Add New Resource',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Set details and assign to one or multiple batches',
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

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('1. Resource Details', Icons.description_outlined, isDark),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _titleController,
                      label: 'Resource Title *',
                      hint: 'e.g. Current Electricity Master Notes & Derivations',
                      isDark: isDark,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter resource title' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Subject *',
                            value: _selectedSubject,
                            items: _subjects,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedSubject = val);
                            },
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Resource Type',
                            value: _selectedType,
                            items: _types,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedType = val);
                            },
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            label: 'Access Badge',
                            value: _selectedBadge,
                            items: _badges,
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedBadge = val);
                            },
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price (₹) (0 = Free/Included)',
                            hint: '0',
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _urlController,
                      label: 'Document / PDF URL *',
                      hint: 'https://ncert.nic.in/textbook/pdf/keph101.pdf',
                      isDark: isDark,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter PDF/Resource URL' : null,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _fileSizeController,
                            label: 'File Size',
                            hint: '3.2 MB',
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _subtitleController,
                            label: 'Subtitle / Tagline',
                            hint: 'Quick Revision Guide',
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Topics covered, formulas, memory maps, chapter breakdown...',
                      maxLines: 2,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),

                    // --- SECTION 2: ASSIGN TO BATCHES ---
                    _buildSectionHeader(
                      '2. Assign to Batch(es) (${_selectedBatchIds.length} Selected)',
                      Icons.school_outlined,
                      isDark,
                      trailingBadge: '${_selectedBatchIds.length} batches',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select the Batch(es) in which this Resource will appear:',
                      style: TextStyle(color: subTextColor, fontSize: 11),
                    ),
                    const SizedBox(height: 10),

                    // Search box for batches
                    _buildSearchInput(
                      hint: 'Search batches by name or category...',
                      isDark: isDark,
                      onChanged: (val) => setState(() => _batchSearch = val.toLowerCase()),
                    ),
                    const SizedBox(height: 10),

                    // Batches Multi-Select List
                    StreamBuilder<List<CourseModel>>(
                      stream: FirestoreService().getBatchesStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                        }

                        var batchesList = snapshot.data ?? [];
                        if (_batchSearch.isNotEmpty) {
                          batchesList = batchesList.where((b) =>
                              b.title.toLowerCase().contains(_batchSearch) ||
                              b.examCategory.toLowerCase().contains(_batchSearch)).toList();
                        }

                        if (batchesList.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Center(
                              child: Text(
                                _batchSearch.isEmpty
                                    ? 'No batches found in database'
                                    : 'No matching batches found',
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
                            itemCount: batchesList.length,
                            separatorBuilder: (context, index) => Divider(color: borderColor, height: 1),
                            itemBuilder: (context, idx) {
                              final batch = batchesList[idx];
                              final isSelected = _selectedBatchIds.contains(batch.id);

                              return CheckboxListTile(
                                value: isSelected,
                                dense: true,
                                activeColor: const Color(0xFF0070F3),
                                checkColor: Colors.white,
                                title: Text(
                                  batch.title,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${batch.examCategory} • ₹${batch.price.toStringAsFixed(0)}',
                                  style: TextStyle(color: subTextColor, fontSize: 10.5),
                                ),
                                secondary: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0070F3).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.school, color: Color(0xFF38BDF8), size: 14),
                                ),
                                onChanged: (bool? checked) {
                                  setState(() {
                                    if (checked == true) {
                                      _selectedBatchIds.add(batch.id);
                                    } else {
                                      _selectedBatchIds.remove(batch.id);
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
                              ? 'Saving Resource...'
                              : (isEditing ? 'Save Changes' : 'Create & Assign Resource'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
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
        Icon(icon, color: const Color(0xFF10B981), size: 18),
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
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Text(
              trailingBadge,
              style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.5, fontWeight: FontWeight.w800),
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
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
