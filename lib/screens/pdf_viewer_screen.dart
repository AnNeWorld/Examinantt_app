import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content_models.dart';
import '../utils/app_theme.dart';
import '../constants/app_colors.dart';

class PdfViewerScreen extends StatefulWidget {
  final ResourceItem pdfData;

  const PdfViewerScreen({super.key, required this.pdfData});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  int _reloadKey = 0;

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        if (mounted) {
          AppTheme.showErrorSnackBar(context, 'Unable to open link: $url');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppTheme.backgroundLight;
    final appBarColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? AppColors.textDark : Colors.black;
    final subColor = isDark ? Colors.white60 : Colors.grey.shade600;

    String url = widget.pdfData.url.trim();
    if (url.startsWith('/')) {
      url = 'https://www.examinantt.com$url';
    }

    final lower = url.toLowerCase();
    final bool isVideo = widget.pdfData.type.toLowerCase() == 'video' ||
        lower.contains('youtu.be') ||
        lower.contains('youtube.com');
    final bool isLink = widget.pdfData.type.toLowerCase() == 'link';
    final bool hasValidUrl = url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'));

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leadingWidth: 42,
        titleSpacing: 6,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          widget.pdfData.title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (hasValidUrl)
            IconButton(
              icon: Icon(Icons.open_in_browser_rounded, color: textColor),
              tooltip: 'Open in Browser',
              onPressed: () => _openExternal(url),
            ),
        ],
        backgroundColor: appBarColor,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: !hasValidUrl
          ? _buildUnavailableView(context, isDark, textColor, subColor, url)
          : (isVideo || isLink)
              ? _buildMediaView(context, isDark, textColor, subColor, url, isVideo)
              : KeyedSubtree(
                  key: ValueKey(_reloadKey),
                  child: const PDF(
                    enableSwipe: true,
                    swipeHorizontal: false,
                    autoSpacing: false,
                    pageFling: false,
                  ).cachedFromUrl(
                    url,
                    placeholder: (progress) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Loading PDF... $progress%',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    errorWidget: (error) => _buildUnavailableView(context, isDark, textColor, subColor, url),
                  ),
                ),
    );
  }

  Widget _buildMediaView(BuildContext context, bool isDark, Color textColor, Color subColor, String url, bool isVideo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isVideo ? Colors.red.withValues(alpha: 0.15) : const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo ? Icons.play_circle_fill_rounded : Icons.link_rounded,
                size: 64,
                color: isVideo ? Colors.redAccent : const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.pdfData.title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.pdfData.description.isNotEmpty
                  ? widget.pdfData.description
                  : (isVideo ? 'Watch online video class & revision lecture' : 'External study resource & link'),
              style: TextStyle(
                fontSize: 13.5,
                color: subColor,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openExternal(url),
              icon: Icon(isVideo ? Icons.play_arrow_rounded : Icons.open_in_new_rounded, size: 20),
              label: Text(isVideo ? 'Watch Video' : 'Open Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isVideo ? Colors.redAccent : const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableView(BuildContext context, bool isDark, Color textColor, Color subColor, String url) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0C1D3B) : const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 54,
                color: isDark ? const Color(0xFF38BDF8) : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PDF Not Available',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This document preview could not be loaded directly.\nYou can retry or open it in your browser.',
              style: TextStyle(
                fontSize: 13.5,
                color: subColor,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _reloadKey++),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://')))
                  ElevatedButton.icon(
                    onPressed: () => _openExternal(url),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: const Text('Browser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
