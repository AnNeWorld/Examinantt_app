// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/community_message_model.dart';
import '../services/firestore_service.dart';

class CommunityChatView extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;

  const CommunityChatView({
    super.key,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  State<CommunityChatView> createState() => _CommunityChatViewState();
}

class _CommunityChatViewState extends State<CommunityChatView> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _selectedChannel = 'general';
  bool _filterTeacherOnly = false;
  bool _isPostingAsTeacher = false; // Toggle to reply as Teacher/Faculty

  // Threaded reply state
  CommunityMessage? _replyingToMessage;

  final List<Map<String, dynamic>> _channels = [
    {'id': 'general', 'label': 'General Discussion', 'icon': Icons.public_rounded},
    {'id': 'physics', 'label': 'Physics Doubts', 'icon': Icons.flash_on_rounded},
    {'id': 'chemistry', 'label': 'Chemistry Doubts', 'icon': Icons.science_rounded},
    {'id': 'maths', 'label': 'Maths Doubts', 'icon': Icons.calculate_rounded},
  ];

  final List<String> _quickPrompts = [
    'Can someone explain Lenz’s Law with examples?',
    'What are the high-weightage chapters in Chemistry?',
    'Shortest distance between skew lines formula?',
    'When should I start attempting full mock tests?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final senderId = user?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
    final senderName = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : user?.displayName ?? (_isPostingAsTeacher ? 'Faculty' : 'Student');

    final newMessage = CommunityMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      channel: _selectedChannel,
      senderId: senderId,
      senderName: senderName,
      senderRole: _isPostingAsTeacher ? 'teacher' : 'student',
      senderTag: _isPostingAsTeacher
          ? 'Verified Faculty • Senior Academic Mentor'
          : 'Class 12 • JEE Aspirant',
      text: text,
      timestamp: DateTime.now(),
      replyToId: _replyingToMessage?.id,
      replyToName: _replyingToMessage?.senderName,
      replyToText: _replyingToMessage?.text != null
          ? (_replyingToMessage!.text.length > 50
              ? '${_replyingToMessage!.text.substring(0, 50)}...'
              : _replyingToMessage!.text)
          : null,
      isTeacherReply: _isPostingAsTeacher,
      reactions: {},
    );

    _messageController.clear();
    setState(() {
      _replyingToMessage = null;
    });

    await _firestoreService.sendCommunityMessage(newMessage);
    _scrollToBottom();
  }

  void _toggleReaction(CommunityMessage message, String emoji) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
    _firestoreService.toggleCommunityReaction(
      messageId: message.id,
      emoji: emoji,
      userId: uid,
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat('h:mm a').format(dt);
    }
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _isDark ? const Color(0xFF070F1E) : Colors.white,
      child: Column(
        children: [
          // Header / Info banner (if not embedded, show top app bar)
          if (!widget.isEmbedded) _buildStandaloneHeader(),

          // Channel and Topic Selector Bar
          _buildChannelSelector(),

          // Filter bar: All Messages vs Teacher Answers Only
          _buildFilterBar(),

          // Chat messages list
          Expanded(
            child: StreamBuilder<List<CommunityMessage>>(
              stream: _firestoreService.streamCommunityMessages(channel: _selectedChannel),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFA000)),
                  );
                }

                List<CommunityMessage> messages = snapshot.data ?? [];

                if (_filterTeacherOnly) {
                  messages = messages.where((m) => m.isFaculty).toList();
                }

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final currentUid = FirebaseAuth.instance.currentUser?.uid;
                    final isMe = currentUid != null && message.senderId == currentUid;

                    return _buildMessageCard(message, isMe: isMe);
                  },
                );
              },
            ),
          ),

          // Replying preview banner
          if (_replyingToMessage != null) _buildReplyingBanner(),

          // Quick Prompt suggestions
          _buildQuickPrompts(),

          // Input Bar with Teacher toggle & send button
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildStandaloneHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: _isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: Icon(Icons.arrow_back, color: _isDark ? Colors.white : const Color(0xFF1E293B)),
              onPressed: widget.onBack,
            ),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFFFA000),
            child: Icon(Icons.forum_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examinantt Student Community',
                  style: TextStyle(color: _isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Text(
                  '🟢 140+ Students & Teachers Active',
                  style: TextStyle(color: Color(0xFF34D399), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelSelector() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0B1729) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: _isDark ? Colors.white10 : Colors.grey.shade200)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemCount: _channels.length,
        itemBuilder: (context, index) {
          final channel = _channels[index];
          final isSelected = _selectedChannel == channel['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedChannel = channel['id'];
                  _replyingToMessage = null;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFA000), Color(0xFFFF8F00)],
                        )
                      : null,
                  color: isSelected ? null : (_isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFD54F)
                        : (_isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      channel['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.black : (_isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      channel['label'] as String,
                      style: TextStyle(
                        color: isSelected ? Colors.black : (_isDark ? Colors.white70 : const Color(0xFF475569)),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: _isDark ? const Color(0xFF081220) : const Color(0xFFF1F5F9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildFilterChip(
                label: 'All Discussions',
                isSelected: !_filterTeacherOnly,
                onTap: () => setState(() => _filterTeacherOnly = false),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Teacher Answers 🎓',
                isSelected: _filterTeacherOnly,
                badgeColor: const Color(0xFFFFA000),
                onTap: () => setState(() => _filterTeacherOnly = true),
              ),
            ],
          ),
          // Live faculty indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Color(0xFF10B981), size: 12),
                SizedBox(width: 4),
                Text(
                  'Faculty Verified',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (badgeColor ?? const Color(0xFF2563EB))
              : (_isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (_isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (_isDark ? Colors.white60 : const Color(0xFF475569)),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(CommunityMessage message, {required bool isMe}) {
    final isTeacher = message.isFaculty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Quoted message if threaded
          if (message.replyToName != null && message.replyToText != null)
            Container(
              margin: EdgeInsets.only(
                left: isMe ? 40 : 12,
                right: isMe ? 12 : 40,
                bottom: 4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: Color(0xFFFFA000), width: 3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.reply_rounded, size: 12, color: Color(0xFFFFA000)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Replying to ${message.replyToName}: ${message.replyToText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                    ),
                  ),
                ],
              ),
            ),

          // Main Card Container
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.88,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: isTeacher
                  ? const LinearGradient(
                      colors: [Color(0xFF1E2638), Color(0xFF121B2A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : isMe
                      ? const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
              color: (!isTeacher && !isMe)
                  ? (_isDark ? const Color(0xFF152238) : const Color(0xFFF8FAFC))
                  : null,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: Border.all(
                color: isTeacher
                    ? const Color(0xFFFFA000).withValues(alpha: 0.5)
                    : isMe
                        ? const Color(0xFF60A5FA).withValues(alpha: 0.4)
                        : (_isDark ? Colors.white12 : Colors.grey.shade200),
                width: isTeacher ? 1.5 : 1.0,
              ),
              boxShadow: isTeacher
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFA000).withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header of message (Avatar + Name + Role Badge + Time)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: isTeacher
                          ? const Color(0xFFFFA000)
                          : isMe
                              ? const Color(0xFF60A5FA)
                              : const Color(0xFF475569),
                      child: isTeacher
                          ? const Icon(Icons.school, size: 14, color: Colors.black)
                          : Text(
                              message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  isMe ? 'You' : message.senderName,
                                  style: TextStyle(
                                    color: isTeacher ? const Color(0xFFFFD54F) : Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isTeacher) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 14, color: Color(0xFFFFA000)),
                              ],
                            ],
                          ),
                          Text(
                            isTeacher
                                ? '🎓 Verified Faculty • Mentor'
                                : message.senderTag,
                            style: TextStyle(
                              color: isTeacher
                                  ? const Color(0xFFFDE68A)
                                  : isMe
                                      ? Colors.blue.shade100
                                      : Colors.white60,
                              fontSize: 9.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: TextStyle(
                        color: isMe ? Colors.blue.shade200 : Colors.white38,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),

                // Teacher Answer Banner indicator
                if (isTeacher)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFFFFA000), size: 11),
                        SizedBox(width: 4),
                        Text(
                          'OFFICIAL FACULTY SOLUTION',
                          style: TextStyle(
                            color: Color(0xFFFFA000),
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Message Text Content
                SelectableText(
                  message.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 10),

                // Footer: Reactions and Reply button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Reaction items
                    ...message.reactions.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => _toggleReaction(message, entry.key),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(entry.key, style: const TextStyle(fontSize: 11)),
                                const SizedBox(width: 3),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // Quick add reaction button
                    InkWell(
                      onTap: () => _showReactionPicker(message),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_reaction_outlined, size: 12, color: Colors.white60),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Reply Button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _replyingToMessage = message;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA000).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.reply_rounded, size: 12, color: Color(0xFFFFA000)),
                            SizedBox(width: 4),
                            Text(
                              'Reply',
                              style: TextStyle(
                                color: Color(0xFFFFA000),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReactionPicker(CommunityMessage message) {
    final emojis = ['👍', '❤️', '💡', '🔥', '👏', '🎯'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'React to Message',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: emojis.map((emoji) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _toggleReaction(message, emoji);
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: Color(0xFFFFA000), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_replyingToMessage!.senderName}',
                  style: const TextStyle(
                    color: Color(0xFFFFA000),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _replyingToMessage!.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10.5),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 16),
            onPressed: () => setState(() => _replyingToMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return Container(
      height: 34,
      color: const Color(0xFF081220),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        itemCount: _quickPrompts.length,
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                _messageController.text = prompt;
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tips_and_updates_outlined, size: 11, color: Color(0xFFFFA000)),
                    const SizedBox(width: 4),
                    Text(
                      prompt,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(top: BorderSide(color: _isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Role switcher toggle: Posting as Student vs Faculty
            Row(
              children: [
                const Text(
                  'Post as: ',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                InkWell(
                  onTap: () => setState(() => _isPostingAsTeacher = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: !_isPostingAsTeacher
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !_isPostingAsTeacher ? Colors.blue.shade300 : Colors.white12,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 11, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Student',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => setState(() => _isPostingAsTeacher = true),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isPostingAsTeacher
                          ? const Color(0xFFFFA000)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isPostingAsTeacher ? const Color(0xFFFFD54F) : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school,
                          size: 11,
                          color: _isPostingAsTeacher ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Faculty (Teacher)',
                          style: TextStyle(
                            color: _isPostingAsTeacher ? Colors.black : Colors.white70,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _isPostingAsTeacher ? '🎓 Verified Badge Enabled' : '🧑‍🎓 Peer Discussion',
                  style: TextStyle(
                    color: _isPostingAsTeacher ? const Color(0xFFFFA000) : Colors.white38,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Text Input field + Action buttons
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: _isPostingAsTeacher
                            ? const Color(0xFFFFA000).withValues(alpha: 0.5)
                            : (_isDark ? Colors.white12 : Colors.grey.shade300),
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      style: TextStyle(color: _isDark ? Colors.white : const Color(0xFF1E293B), fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _isPostingAsTeacher
                            ? 'Reply with faculty solution or explanation...'
                            : 'Ask a doubt or converse with peers...',
                        hintStyle: TextStyle(color: _isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _sendMessage,
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: _isPostingAsTeacher
                          ? const LinearGradient(
                              colors: [Color(0xFFFFA000), Color(0xFFFF8F00)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _isPostingAsTeacher
                              ? const Color(0xFFFFA000).withValues(alpha: 0.3)
                              : const Color(0xFF2563EB).withValues(alpha: 0.3),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.forum_outlined, size: 40, color: Color(0xFFFFA000)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No messages in this channel yet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Be the first student or faculty member to start the conversation!',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
