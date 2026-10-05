import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class ProfileAvatarWidget extends StatefulWidget {
  final double size;
  final String? initial;
  final String? imageString;
  final bool showCameraIcon;
  final bool isEditable;
  final Color borderColor;
  final double borderWidth;
  final VoidCallback? onImageChanged;

  const ProfileAvatarWidget({
    super.key,
    this.size = 80,
    this.initial,
    this.imageString,
    this.showCameraIcon = true,
    this.isEditable = true,
    this.borderColor = const Color(0xFFFFA000),
    this.borderWidth = 2.0,
    this.onImageChanged,
  });

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isLoading = true);

      final bytes = await pickedFile.readAsBytes();
      
      // Check 2MB size limit
      if (bytes.lengthInBytes > 2 * 1024 * 1024) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Selected image exceeds 2MB limit. Please choose a smaller image.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final base64String = base64Encode(bytes);

      await userProvider.updateProfileImage(base64String);
      widget.onImageChanged?.call();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeImage() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateProfileImage(null);
      widget.onImageChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing image: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showImagePickerSheet(BuildContext context, bool hasImage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload a photo (JPG, PNG, WebP • Max 2MB)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildOptionButton(
                      context: bottomSheetContext,
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: const Color(0xFF3B82F6),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildOptionButton(
                      context: bottomSheetContext,
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFFFFA000),
                      onTap: () {
                        Navigator.pop(bottomSheetContext);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    if (hasImage)
                      _buildOptionButton(
                        context: bottomSheetContext,
                        icon: Icons.delete_outline_rounded,
                        label: 'Remove',
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          _removeImage();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(String? imgStr, String initialText) {
    if (imgStr != null && imgStr.trim().isNotEmpty) {
      final clean = imgStr.trim();

      // Check if Base64
      if (!clean.startsWith('http') && !clean.startsWith('/')) {
        try {
          final rawBase64 = clean.contains(',') ? clean.split(',').last : clean;
          final Uint8List imageBytes = base64Decode(rawBase64);
          return Image.memory(
            imageBytes,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(initialText),
          );
        } catch (_) {}
      }

      // Check if local file
      if (clean.startsWith('/') || clean.contains(':\\') || clean.contains(':/')) {
        try {
          final file = File(clean);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(initialText),
            );
          }
        } catch (_) {}
      }

      // Check if Network URL
      if (clean.startsWith('http')) {
        return Image.network(
          clean,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackInitial(initialText),
        );
      }
    }

    return _buildFallbackInitial(initialText);
  }

  Widget _buildFallbackInitial(String initialText) {
    return Center(
      child: Text(
        initialText,
        style: TextStyle(
          color: widget.borderColor,
          fontSize: widget.size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final effectiveImage = widget.imageString ?? userProvider.profileImage;
    final userName = userProvider.user?.name ?? '';
    final defaultInitial = userName.trim().isNotEmpty ? userName.trim()[0].toUpperCase() : 'A';
    final effectiveInitial = widget.initial ?? defaultInitial;
    final hasImage = effectiveImage != null && effectiveImage.trim().isNotEmpty;

    final badgeSize = (widget.size * 0.32).clamp(24.0, 32.0);
    final iconSize = (badgeSize * 0.55).clamp(12.0, 16.0);

    return GestureDetector(
      onTap: widget.isEditable ? () => _showImagePickerSheet(context, hasImage) : null,
      child: Stack(
        alignment: Alignment.bottomRight,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.borderColor.withValues(alpha: 0.1),
              border: Border.all(color: widget.borderColor, width: widget.borderWidth),
            ),
            child: ClipOval(
              child: _isLoading
                  ? Center(
                      child: SizedBox(
                        width: widget.size * 0.35,
                        height: widget.size * 0.35,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(widget.borderColor),
                        ),
                      ),
                    )
                  : _buildImageContent(effectiveImage, effectiveInitial),
            ),
          ),
          if (widget.showCameraIcon && widget.isEditable)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  color: widget.borderColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
