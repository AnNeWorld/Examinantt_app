import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int openTickets = 1;
  int resolvedTickets = 4;
  int closedTickets = 2;

  final List<Map<String, String>> faqList = [
    {
      'q': 'How do I download mock test reports?',
      'a': 'Go to the "My Tests" tab on your profile dashboard, select the completed test, and tap the download PDF report icon.'
    },
    {
      'q': 'Can I access Examinantt on a desktop PC?',
      'a': 'Yes, you can log in on your computer by visiting web.examinantt.com using the same credentials.'
    },
    {
      'q': 'How do I change my target year or primary exam?',
      'a': 'You can change this anytime under the "My Preparation" tab or "Account Settings" within the Profile dashboard.'
    },
    {
      'q': 'What payment options are supported?',
      'a': 'We support UPI (GPay, PhonePe, Paytm), Credit/Debit cards, Net Banking, and popular mobile wallets.'
    }
  ];

  void _showFAQDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text('Help Center FAQs', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: faqList.length,
              itemBuilder: (context, index) {
                final faq = faqList[index];
                return ExpansionTile(
                  title: Text(faq['q']!, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w600)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(faq['a']!, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12)),
                    )
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFFFFA000))),
            ),
          ],
        );
      },
    );
  }

  void _showTicketCreationDialog(String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subjectController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text('Create $type', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: 'Subject / Title'),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Detailed Description', alignLabelWithHint: true),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (subjectController.text.isEmpty || descController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all details.')),
                  );
                  return;
                }
                setState(() {
                  openTickets += 1;
                });
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
                      title: const Text('Success!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      content: Text('Your ticket has been filed under ID #${10000 + openTickets}. We will respond within 24 hours.'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
                          child: const Text('OK', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showLiveChatSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textController = TextEditingController();
    final List<Map<String, dynamic>> chatMessages = [
      {'text': 'Hello! Welcome to Examinantt Support. How can we help you today?', 'isBot': true}
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setChatState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SafeArea(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(width: 16),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Examinantt Support Bot',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: chatMessages.length,
                          itemBuilder: (context, index) {
                            final msg = chatMessages[index];
                            final isBot = msg['isBot'] as bool;
                            return Align(
                              alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isBot
                                      ? (isDark ? const Color(0xFF1B2C56) : Colors.grey.shade200)
                                      : const Color(0xFFFFA000),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(isBot ? 0 : 16),
                                    bottomRight: Radius.circular(isBot ? 16 : 0),
                                  ),
                                ),
                                child: Text(
                                  msg['text']!,
                                  style: TextStyle(
                                    color: isBot ? (isDark ? Colors.white : Colors.black87) : Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: textController,
                                decoration: InputDecoration(
                                  hintText: 'Type your query here...',
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF16254A) : Colors.grey.shade100,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.send_rounded, color: Color(0xFFFFA000)),
                              onPressed: () {
                                final text = textController.text.trim();
                                if (text.isEmpty) return;
                                textController.clear();
                                setChatState(() {
                                  chatMessages.add({'text': text, 'isBot': false});
                                });

                                // Simulate bot typing & reply
                                Future.delayed(const Duration(milliseconds: 800), () {
                                  String botReply = 'Thank you for the message! One of our support executives will join the chat shortly.';
                                  final lower = text.toLowerCase();
                                  if (lower.contains('payment') || lower.contains('refund') || lower.contains('money')) {
                                    botReply = 'For payment issues, refunds take 5-7 business days to credit to your account. Feel free to raise a Support Ticket for custom checking!';
                                  } else if (lower.contains('test') || lower.contains('mock') || lower.contains('result')) {
                                    botReply = 'You can find your test results, answer keys, and dynamic analysis in the "My Tests" tab under your profile.';
                                  } else if (lower.contains('courses') || lower.contains('buy')) {
                                    botReply = 'Courses can be browsed and purchased on the Homepage or via the Courses tab. All locked items unlock immediately upon purchase!';
                                  }
                                  setChatState(() {
                                    chatMessages.add({'text': botReply, 'isBot': true});
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mockLauncher(String title, String detail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
          title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: Text('Simulating launching local app to send to: $detail'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFA000)),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.support_agent_rounded, color: Color(0xFFFFA000), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Help & Support',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We\'re here to help you 24/7. Find answers, get support and report issues.',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA000).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.headset_mic_rounded, color: Color(0xFFFFA000), size: 28),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            // Get Help Grid (4 Cards)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.15,
              children: [
                _buildHelpActionCard(
                  context,
                  title: 'Help Center',
                  desc: 'Browse FAQs and step-by-step guides',
                  btnLabel: 'Explore Now',
                  color: const Color(0xFF3B82F6),
                  icon: Icons.menu_book_rounded,
                  onTap: _showFAQDialog,
                ),
                _buildHelpActionCard(
                  context,
                  title: 'Contact Support',
                  desc: 'Talk to our support team for any help',
                  btnLabel: 'Contact Us',
                  color: const Color(0xFF10B981),
                  icon: Icons.question_answer_rounded,
                  onTap: () => _showTicketCreationDialog('Support Ticket'),
                ),
                _buildHelpActionCard(
                  context,
                  title: 'Report a Problem',
                  desc: 'Report bugs, errors or technical issues',
                  btnLabel: 'Report Now',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.bug_report_outlined,
                  onTap: () => _showTicketCreationDialog('Bug Report'),
                ),
                _buildHelpActionCard(
                  context,
                  title: 'Suggestions',
                  desc: 'Share your feedback and help us improve',
                  btnLabel: 'Share Now',
                  color: const Color(0xFFFFA000),
                  icon: Icons.lightbulb_outline_rounded,
                  onTap: () => _showTicketCreationDialog('Feature Suggestion'),
                ),
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            const SizedBox(height: 28),

            // Section 2: My Support Tickets
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, color: subColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'My Support Tickets',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
                          title: Text('Your Support Tickets', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: const Text('Ticket #10042: Payment Failure'),
                                subtitle: Text('Status: Open • $openTickets open tickets total'),
                              ),
                              ListTile(
                                title: const Text('Ticket #10029: Class access difficulty'),
                                subtitle: Text('Status: Resolved • $resolvedTickets resolved total'),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close', style: TextStyle(color: Color(0xFFFFA000))),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Row(
                    children: [
                      Text('View All Tickets', style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 12)),
                      Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFA000), size: 13),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTicketStat(context, '$openTickets', 'Open', 'Needs your response', Icons.mark_chat_unread_outlined, const Color(0xFF3B82F6)),
                  _buildTicketDivider(),
                  _buildTicketStat(context, '$resolvedTickets', 'Resolved', 'Successfully resolved', Icons.check_circle_outline_rounded, const Color(0xFF10B981)),
                  _buildTicketDivider(),
                  _buildTicketStat(context, '$closedTickets', 'Closed', 'No longer active', Icons.history_rounded, const Color(0xFF8B5CF6)),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
            const SizedBox(height: 28),

            // Section 3: Common Topics
            Text(
              'Common Topics',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTopicChip(context, 'Account & Profile', Icons.person_outline_rounded, const Color(0xFF3B82F6)),
                  const SizedBox(width: 10),
                  _buildTopicChip(context, 'Payments & Refunds', Icons.payment_rounded, const Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  _buildTopicChip(context, 'Tests & Results', Icons.assignment_outlined, const Color(0xFF8B5CF6)),
                  const SizedBox(width: 10),
                  _buildTopicChip(context, 'Courses & Content', Icons.school_outlined, const Color(0xFFFFA000)),
                  const SizedBox(width: 10),
                  _buildTopicChip(context, 'Technical Issues', Icons.settings_outlined, const Color(0xFFEC4899)),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            const SizedBox(height: 28),

            // Section 4: Still Need Help Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Still need help?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our support team is ready to assist you through your preferred channel.',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _mockLauncher('Call Support', '+91 98765 43210'),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildContactRow(
                        context,
                        title: 'Call Us',
                        desc: '+91 98765 43210',
                        meta: '9 AM - 9 PM',
                        icon: Icons.phone_in_talk_outlined,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  InkWell(
                    onTap: () => _mockLauncher('Email Support', 'support@examinantt.com'),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildContactRow(
                        context,
                        title: 'Email Us',
                        desc: 'support@examinantt.com',
                        meta: '24/7',
                        icon: Icons.mail_outline_rounded,
                        color: const Color(0xFFFFA000),
                      ),
                    ),
                  ),
                  const Divider(height: 20),
                  InkWell(
                    onTap: _showLiveChatSheet,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: _buildContactRow(
                        context,
                        title: 'Live Chat',
                        desc: 'Chat with our support team',
                        meta: 'Online',
                        icon: Icons.chat_bubble_outline_rounded,
                        color: const Color(0xFF10B981),
                        isLive: true,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
            const SizedBox(height: 24),

            // Bottom trust hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA000).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFA000).withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xFFFFA000), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'We respect your time and privacy. Your queries are important to us. We respond within 24 hours.',
                      style: TextStyle(fontSize: 10, color: textColor, height: 1.3),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpActionCard(
    BuildContext context, {
    required String title,
    required String desc,
    required String btnLabel,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 9, color: subColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  btnLabel,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_rounded, color: color, size: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketStat(
    BuildContext context,
    String count,
    String label,
    String desc,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              count,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: TextStyle(fontSize: 8, color: subColor),
        ),
      ],
    );
  }

  Widget _buildTicketDivider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.grey.shade400.withValues(alpha: 0.2),
    );
  }

  Widget _buildTopicChip(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0E1A3D) : Colors.white,
              title: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text('Browse guides, FAQs and support articles related specifically to "$label". Coming soon!', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK', style: TextStyle(color: Color(0xFFFFA000))),
                ),
              ],
            );
          },
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_right_rounded, color: Colors.grey.shade400, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required String title,
    required String desc,
    required String meta,
    required IconData icon,
    required Color color,
    bool isLive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 10, color: subColor),
              ),
            ],
          ),
        ),
        if (isLive)
          Row(
            children: [
              Text(
                meta,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
              ),
            ],
          )
        else
          Text(
            meta,
            style: TextStyle(fontSize: 10, color: subColor, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}
