import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A robust image widget that seamlessly displays:
/// 1. Remote HTTP/HTTPS URLs (via CachedNetworkImage)
/// 2. Data URIs with Base64 ('data:image/jpeg;base64,...' commonly uploaded from examinantt.com admin web)
/// 3. Raw Base64 strings
/// 4. Local asset paths ('assets/...')
/// 5. Graceful fallback placeholder when image is missing or invalid
class SafeAppImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? fallbackColor;
  final IconData fallbackIcon;

  const SafeAppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackColor,
    this.fallbackIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final clean = imageUrl.trim();

    Widget imageContent;

    if (clean.isEmpty) {
      imageContent = _buildFallback(context);
    } else if (clean.startsWith('data:image') || clean.contains(';base64,')) {
      imageContent = _buildBase64Image(clean, context);
    } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
      imageContent = CachedNetworkImage(
        imageUrl: clean,
        width: width,
        height: height,
        fit: fit,
        placeholder: (ctx, url) => placeholder ?? _buildPlaceholder(context),
        errorWidget: (ctx, url, error) => errorWidget ?? _buildFallback(context),
      );
    } else if (clean.startsWith('assets/')) {
      imageContent = Image.asset(
        clean,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, error, stackTrace) => errorWidget ?? _buildFallback(context),
      );
    } else if (clean.length > 80 && !clean.contains(' ') && !clean.contains('/')) {
      // Possible raw base64 string
      imageContent = _buildBase64Image(clean, context);
    } else {
      imageContent = _buildFallback(context);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildBase64Image(String raw, BuildContext context) {
    try {
      final base64Part = raw.contains(',') ? raw.split(',').last.trim() : raw.trim();
      final Uint8List bytes = base64Decode(base64Part);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, error, stackTrace) => errorWidget ?? _buildFallback(context),
      );
    } catch (_) {
      return errorWidget ?? _buildFallback(context);
    }
  }

  Widget _buildPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: isDark ? const Color(0xFF0F1E36) : Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    if (errorWidget != null) return errorWidget!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      color: fallbackColor ?? (isDark ? const Color(0xFF0F1E36) : Colors.grey.shade100),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: (height != null && height! < 50) ? 20 : 32,
          color: isDark ? Colors.white24 : Colors.grey.shade400,
        ),
      ),
    );
  }
}
