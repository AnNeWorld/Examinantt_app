import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class LiveClassesScreen extends StatefulWidget {
  const LiveClassesScreen({super.key});

  @override
  State<LiveClassesScreen> createState() => _LiveClassesScreenState();
}

class _LiveClassesScreenState extends State<LiveClassesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Live Classes & Videos', style: TextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Live Now'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Recorded'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveNowTab(),
          _buildUpcomingTab(),
          _buildRecordedTab(),
        ],
      ),
    );
  }

  Widget _buildLiveNowTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildVideoCard(
          title: 'SSC CGL Tier 1: Advanced Maths Marathon',
          instructor: 'Abhinay Sharma',
          time: 'Started 10 mins ago',
          isLive: true,
          thumbnailUrl: 'https://images.unsplash.com/photo-1524178232363-1fb2b075b655?w=500&auto=format&fit=crop&q=60',
        ),
      ].animate(interval: 50.ms).fade().slideY(begin: 0.1),
    );
  }

  Widget _buildUpcomingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildVideoCard(
          title: 'Banking Reasoning: Puzzles & Seating',
          instructor: 'Radha Krishna',
          time: 'Today, 4:00 PM',
          isLive: false,
          thumbnailUrl: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=500&auto=format&fit=crop&q=60',
        ),
        const SizedBox(height: 16),
        _buildVideoCard(
          title: 'Daily Current Affairs Analysis',
          instructor: 'Pratik Sir',
          time: 'Tomorrow, 7:00 AM',
          isLive: false,
          thumbnailUrl: 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?w=500&auto=format&fit=crop&q=60',
        ),
      ].animate(interval: 50.ms).fade().slideY(begin: 0.1),
    );
  }

  Widget _buildRecordedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildVideoCard(
          title: 'Complete English Grammar Rule 1-50',
          instructor: 'Neetu Singh',
          time: 'Duration: 2h 15m',
          isLive: false,
          isRecorded: true,
          thumbnailUrl: 'https://images.unsplash.com/photo-1513258496099-48166314a708?w=500&auto=format&fit=crop&q=60',
        ),
      ].animate(interval: 50.ms).fade().slideY(begin: 0.1),
    );
  }

  Widget _buildVideoCard({
    required String title,
    required String instructor,
    required String time,
    required String thumbnailUrl,
    bool isLive = false,
    bool isRecorded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Image.network(
                  thumbnailUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.blueGrey[100],
                    child: const Icon(Icons.video_library, size: 50, color: Colors.blueGrey),
                  ),
                ),
              ),
              // Overlay dark gradient
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                  ),
                ),
              ),
              if (isLive)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              if (isRecorded)
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('2:15:00', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              // Play button overlay
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                  ),
                ),
              ),
            ],
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkSlate,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primaryColor,
                      child: Icon(Icons.person, size: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      instructor,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isLive ? Icons.timer : Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    if (!isLive && !isRecorded)
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                          minimumSize: const Size(80, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Remind Me', style: TextStyle(fontSize: 12)),
                      )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
