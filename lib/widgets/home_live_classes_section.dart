import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content_models.dart';
import '../services/content_service.dart';
import '../screens/amazon_live_player_screen.dart';
import '../screens/jitsi_live_meeting_screen.dart';
import '../screens/live_classes_screen.dart';
import '../utils/app_navigator.dart';
import 'safe_app_image.dart';

/// Authentic Live Interactive Classroom Section
/// Matching https://www.examinantt.com/dashboard exactly
class HomeLiveClassesSection extends StatefulWidget {
  final String selectedExam;
  final bool isDark;

  const HomeLiveClassesSection({
    super.key,
    required this.selectedExam,
    required this.isDark,
  });

  @override
  State<HomeLiveClassesSection> createState() => _HomeLiveClassesSectionState();
}

class _HomeLiveClassesSectionState extends State<HomeLiveClassesSection> {
  int _activeFilterIndex = 0; // 0: All Classes, 1: Live, 2: Upcoming, 3: Past Replays
  final List<String> _filters = ['All Classes', '🔴 Live', 'Upcoming', 'Past Replays'];

  Color _getSubjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('physic')) return const Color(0xFF0070F3);
    if (s.contains('chem')) return const Color(0xFF10B981);
    if (s.contains('math') || s.contains('quant')) return const Color(0xFFF59E0B);
    if (s.contains('bio')) return const Color(0xFFEC4899);
    if (s.contains('english')) return const Color(0xFFA855F7);
    if (s.contains('general') || s.contains('gs') || s.contains('gk')) return const Color(0xFF06B6D4);
    return const Color(0xFFFF7A00);
  }

  void _openClassVideo(BuildContext context, LiveClass c) async {
    // If it's a direct Google Meet or Zoom link, offer direct launch or player
    if (c.isGoogleMeet || c.isZoom) {
      final uri = Uri.tryParse(c.videoUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!context.mounted) return;

    if (c.isJitsi) {
      AppNavigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JitsiLiveMeetingScreen(
            liveClass: c,
            sessionId: c.id,
            roomName: c.roomName,
          ),
        ),
      );
      return;
    }

    AppNavigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AmazonLivePlayerScreen(liveClass: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF0A1526) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E2D4A) : Colors.grey.shade200;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return StreamBuilder<List<LiveClass>>(
      stream: ContentService().getLiveClasses(),
      builder: (context, snapshot) {
        final allClasses = snapshot.data ?? [];

        // On examinantt.com/dashboard, all available classes are shown by default.
        // If user wants to filter by tabs (All, Live, Upcoming, Past Replays):
        List<LiveClass> displayedClasses = allClasses;
        if (_activeFilterIndex == 1) {
          displayedClasses = allClasses.where((c) => c.isLive).toList();
        } else if (_activeFilterIndex == 2) {
          displayedClasses = allClasses.where((c) => c.isUpcoming).toList();
        } else if (_activeFilterIndex == 3) {
          displayedClasses = allClasses.where((c) => c.isRecorded).toList();
        }

        final liveCount = allClasses.where((c) => c.isLive).length;
        final hasLiveActive = liveCount > 0;
        final LiveClass? heroLiveClass = hasLiveActive ? allClasses.firstWhere((c) => c.isLive) : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================================
            // 1. HEADER (Matches Live Interactive Classroom on examinantt.com)
            // =================================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: hasLiveActive
                                ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (hasLiveActive ? const Color(0xFFEF4444) : const Color(0xFF2563EB)).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          hasLiveActive ? Icons.sensors_rounded : Icons.live_tv_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Live Interactive Classroom',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      color: titleColor,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    hasLiveActive ? '$liveCount LIVE' : '${allClasses.length} Scheduled',
                                    style: TextStyle(
                                      color: hasLiveActive ? const Color(0xFFEF4444) : (isDark ? Colors.cyanAccent : const Color(0xFF0284C7)),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Real-time lectures, live doubt clearing, and expert marathon sessions',
                              style: TextStyle(color: subtitleColor, fontSize: 10, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    AppNavigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LiveClassesScreen(initialTab: 0),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(left: 8, right: 0, top: 4, bottom: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Full Timetable',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // =================================================================
            // 2. HERO LIVE NOW CARD (Displayed only when active)
            // =================================================================
            if (heroLiveClass != null) ...[
              _buildHeroLiveCard(context, heroLiveClass, isDark),
              const SizedBox(height: 12),
            ],

            // =================================================================
            // 3. FILTER TABS (All Classes, Live, Upcoming, Past Replays)
            // =================================================================
            SizedBox(
              height: 28,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _activeFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      onTap: () => setState(() => _activeFilterIndex = index),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark ? const Color(0xFF0F1E36) : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF3B82F6)
                                : (isDark ? const Color(0xFF1E3355) : Colors.grey.shade300),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _filters[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // =================================================================
            // 4. HORIZONTAL VIDEO CARDS CAROUSEL (Matches Website Grid)
            // =================================================================
            if (displayedClasses.isEmpty)
              _buildEmptyState(context, isDark, cardBg, cardBorder, subtitleColor)
            else
              SizedBox(
                height: 295,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayedClasses.length,
                  itemBuilder: (context, index) {
                    final c = displayedClasses[index];
                    return _buildWebsiteStyleCard(context, c, isDark, cardBg, cardBorder);
                  },
                ),
              ),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // HERO LIVE CARD (When an active broadcast is in progress)
  // ===========================================================================
  Widget _buildHeroLiveCard(BuildContext context, LiveClass liveClass, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A080C), const Color(0xFF0F1A30)]
              : [const Color(0xFFFFF1F2), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: AspectRatio(
                  aspectRatio: 2.3,
                  child: SafeAppImage(
                    imageUrl: liveClass.thumbnailUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 6),
                      SizedBox(width: 4),
                      Text(
                        'LIVE BROADCAST',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liveClass.title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${liveClass.instructor} • ${liveClass.subject}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openClassVideo(context, liveClass),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'JOIN LIVE STREAM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WEBSITE-STYLE CARD (Matching examinantt.com/dashboard 1:1)
  // ===========================================================================
  Widget _buildWebsiteStyleCard(
    BuildContext context,
    LiveClass c,
    bool isDark,
    Color cardBg,
    Color cardBorder,
  ) {
    final subColor = _getSubjectColor(c.subject);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: c.isLive ? const Color(0xFFEF4444).withValues(alpha: 0.7) : cardBorder,
          width: c.isLive ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openClassVideo(context, c),
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. THUMBNAIL (16:9 with Badges)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: AspectRatio(
                      aspectRatio: 1.82,
                      child: SafeAppImage(
                        imageUrl: c.thumbnailUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Dark gradient shade
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  // Center Play Overlay
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.55),
                          border: Border.all(color: Colors.white70, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),

                  // Top Badges: Status & Subject
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status Badge (RECORDED / LIVE NOW / UPCOMING)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: c.isLive
                                ? const Color(0xFFEF4444)
                                : (c.isUpcoming
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF1E293B).withValues(alpha: 0.85)),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: c.isLive ? const Color(0xFFEF4444) : Colors.white24,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: c.isLive ? Colors.white : const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                c.isLive ? 'LIVE NOW' : (c.isUpcoming ? 'UPCOMING' : 'RECORDED'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Subject Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: subColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.subject.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Row: Date/Time (Left) & Duration (Right)
                  Positioned(
                    bottom: 6,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 10, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(
                              c.time,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 10, color: Colors.white70),
                            const SizedBox(width: 3),
                            Text(
                              '${c.durationMinutes}m',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. CARD BODY & METADATA
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Batch Pill if available
                          if (c.batchName.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                '🎓 ${c.batchName}',
                                style: const TextStyle(
                                  color: Color(0xFF818CF8),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],

                          // Title
                          Text(
                            c.title,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // Instructor & Exam Line (Matches Website)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'By ${c.instructor}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                c.examCategory,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFFF7A00),
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),

                      // 3. ACTION BUTTON (Outlined / Filled)
                      SizedBox(
                        width: double.infinity,
                        height: 34,
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.isLive
                                ? const Color(0xFFEF4444)
                                : (isDark ? const Color(0xFF13233C) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: c.isLive ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF1E3557) : Colors.grey.shade300),
                            ),
                            boxShadow: c.isLive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                c.isLive
                                    ? Icons.sensors_rounded
                                    : (c.isGoogleMeet || c.isZoom ? Icons.groups_rounded : Icons.play_arrow_rounded),
                                size: 14,
                                color: c.isLive ? Colors.white : const Color(0xFF38BDF8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                c.isLive
                                    ? 'JOIN LIVE STREAM'
                                    : (c.isGoogleMeet || c.isZoom
                                        ? 'JOIN LIVE CLASS'
                                        : (c.isUpcoming ? 'SET REMINDER' : 'WATCH PAST RECORDING')),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  color: c.isLive ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================
  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color subtitleColor,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.video_camera_front_outlined, color: Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No sessions in this tab',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Switch to "All Classes" or "Past Replays" to view recorded video lectures.',
                  style: TextStyle(color: subtitleColor, fontSize: 10.5),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _activeFilterIndex = 0),
            child: const Text('Show All', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
