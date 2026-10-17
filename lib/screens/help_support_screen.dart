import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../widgets/notification_bell_action.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int openTickets = 1;
  int resolvedTickets = 4;
  int closedTickets = 2;

  void _openHelpCenter({String? initialCategory}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HelpCenterFaqScreen(initialCategory: initialCategory),
      ),
    );
  }

  void _openCreateTicket(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateSupportTicketScreen(
          initialType: type,
          onTicketCreated: () {
            if (mounted) {
              setState(() {
                openTickets += 1;
              });
            }
          },
        ),
      ),
    );
  }

  void _openAllTickets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportTicketsScreen(
          openCount: openTickets,
          resolvedCount: resolvedTickets,
          closedCount: closedTickets,
        ),
      ),
    );
  }

  void _openLiveChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LiveChatSupportScreen(),
      ),
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
        actions: const [
          NotificationBellAction(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Get Help Grid (4 Main Cards -> All open dedicated full pages)
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
                  onTap: () => _openHelpCenter(),
                ),
                _buildHelpActionCard(
                  context,
                  title: 'Contact Support',
                  desc: 'Talk to our support team for any help',
                  btnLabel: 'Contact Us',
                  color: const Color(0xFF10B981),
                  icon: Icons.question_answer_rounded,
                  onTap: () => _openCreateTicket('Support Ticket'),
                ),
                _buildHelpActionCard(
                  context,
                  title: 'Report a Problem',
                  desc: 'Report bugs, errors or technical issues',
                  btnLabel: 'Report Now',
                  color: const Color(0xFF8B5CF6),
                  icon: Icons.bug_report_outlined,
                  onTap: () => _openCreateTicket('Bug Report'),
                ),
                _buildHelpActionCard(
                  context,
                  title: 'Suggestions',
                  desc: 'Share your feedback and help us improve',
                  btnLabel: 'Share Now',
                  color: const Color(0xFFFFA000),
                  icon: Icons.lightbulb_outline_rounded,
                  onTap: () => _openCreateTicket('Feature Suggestion'),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms),
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
                  onPressed: _openAllTickets,
                  child: const Row(
                    children: [
                      Text('View All Tickets', style: TextStyle(color: Color(0xFFFFA000), fontWeight: FontWeight.bold, fontSize: 12)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFA000), size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _openAllTickets,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTicketStat(context, '$openTickets', 'Open', 'Needs response', Icons.mark_chat_unread_outlined, const Color(0xFF3B82F6)),
                    _buildTicketDivider(),
                    _buildTicketStat(context, '$resolvedTickets', 'Resolved', 'Solved', Icons.check_circle_outline_rounded, const Color(0xFF10B981)),
                    _buildTicketDivider(),
                    _buildTicketStat(context, '$closedTickets', 'Closed', 'Archived', Icons.history_rounded, const Color(0xFF8B5CF6)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
            const SizedBox(height: 28),

            // Section 3: Common Topics -> Opens full Help Center with category
            Text(
              'Common Topics',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildTopicChip(context, 'Account & Profile', Icons.person_outline_rounded, const Color(0xFF3B82F6)),
                  const SizedBox(width: 10),
                  _buildTopicChip(context, 'Payments & Refunds', Icons.payment_rounded, const Color(0xFF10B981)),
                  const SizedBox(width: 10),
                  _buildTopicChip(context, 'Tests & Results', Icons.assignment_outlined, const Color(0xFF8B5CF6)),
                  const SizedBox(width: 10),
                  _buildTopicChip(context, 'Courses & Batches', Icons.school_outlined, const Color(0xFFFFA000)),
                  const SizedBox(width: 10),
                  _buildTopicChip(context, 'Technical Issues', Icons.settings_outlined, const Color(0xFFEC4899)),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
            const SizedBox(height: 28),

            // Section 4: Direct Channels (WhatsApp, Live Chat Assistant, Phone, Email)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Direct Contact Channels',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our support team is ready to assist you through your preferred channel.',
                    style: TextStyle(fontSize: 13, color: subColor),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('https://wa.me/918881188678?text=Hello%20Examinantt%20Team%2C%20I%20need%20academic%20support.');
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (_) {
                        if (context.mounted) {
                          AppTheme.showSuccessSnackBar(context, 'WhatsApp: +91 8881188678');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: _buildContactRow(
                        context,
                        title: 'WhatsApp Support',
                        desc: '+91 8881188678',
                        meta: '24x7 Active',
                        icon: Icons.chat_rounded,
                        color: const Color(0xFF25D366),
                        isLive: true,
                      ),
                    ),
                  ),
                  const Divider(height: 18),
                  InkWell(
                    onTap: _openLiveChat,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: _buildContactRow(
                        context,
                        title: 'Live Chat Assistant',
                        desc: 'Examinantt Academic Support Bot',
                        meta: 'Instant 24x7',
                        icon: Icons.support_agent_rounded,
                        color: const Color(0xFF6366F1),
                        isLive: true,
                      ),
                    ),
                  ),
                  const Divider(height: 18),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('tel:+918881188678');
                      try {
                        await launchUrl(uri);
                      } catch (_) {
                        if (context.mounted) {
                          AppTheme.showSuccessSnackBar(context, 'Call Support: +91 8881188678');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: _buildContactRow(
                        context,
                        title: 'Call Us',
                        desc: '+91 8881188678',
                        meta: '9 AM - 9 PM',
                        icon: Icons.phone_in_talk_outlined,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  const Divider(height: 18),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('mailto:support@examinantt.com');
                      try {
                        await launchUrl(uri);
                      } catch (_) {
                        if (context.mounted) {
                          AppTheme.showSuccessSnackBar(context, 'Email: support@examinantt.com');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
            const SizedBox(height: 24),
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
        padding: const EdgeInsets.all(14),
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
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11.5, color: subColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  btnLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 12, color: color),
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
    String sub,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 10.5, color: subColor)),
      ],
    );
  }

  Widget _buildTicketDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _buildTopicChip(BuildContext context, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: () => _openHelpCenter(initialCategory: label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(fontSize: 12.5, color: subColor),
              ),
            ],
          ),
        ),
        if (isLive)
          Row(
            children: [
              Text(
                meta,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
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
            style: TextStyle(fontSize: 12, color: subColor, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }
}

/// DEDICATED FULL PAGE: Help Center & FAQs
class HelpCenterFaqScreen extends StatefulWidget {
  final String? initialCategory;
  const HelpCenterFaqScreen({super.key, this.initialCategory});

  @override
  State<HelpCenterFaqScreen> createState() => _HelpCenterFaqScreenState();
}

class _HelpCenterFaqScreenState extends State<HelpCenterFaqScreen> {
  late String _selectedCategory;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Account & Profile',
    'Payments & Refunds',
    'Tests & Results',
    'Courses & Batches',
    'Technical Issues',
  ];

  final List<Map<String, String>> _allFaqs = [
    {
      'category': 'Payments & Refunds',
      'q': 'What payment options are supported?',
      'a': 'We support all major payment options: UPI (Google Pay, PhonePe, Paytm), Credit & Debit cards, Net Banking, and Wallet payments via Razorpay secure gateway.',
    },
    {
      'category': 'Payments & Refunds',
      'q': 'How do refunds work on Examinantt?',
      'a': 'For courses with a refund policy, refund requests are reviewed within 24-48 business hours. Approved refunds are credited back to your original payment method in 5-7 working days.',
    },
    {
      'category': 'Tests & Results',
      'q': 'How do I download my mock test reports & solutions?',
      'a': 'Go to the Test Series tab or Profile dashboard, open your completed test attempt, and tap on the "Detailed Analysis" or "Download PDF Report" icon.',
    },
    {
      'category': 'Tests & Results',
      'q': 'Can I re-attempt a mock test after submission?',
      'a': 'Mock tests with multiple attempts allowed can be re-attempted from your test details screen. Your latest and best scores are both recorded in analytics.',
    },
    {
      'category': 'Courses & Batches',
      'q': 'When do live classes happen and can I watch recordings?',
      'a': 'Every batch features daily live classes as per the published schedule. Complete high-definition video archives and annotated lecture PPTs are saved under the "Recorded Videos" and "PPTs" tabs.',
    },
    {
      'category': 'Courses & Batches',
      'q': 'Can I access study material offline?',
      'a': 'Yes, study notes and formula PDFs can be downloaded directly in the app for offline viewing without requiring active internet connectivity.',
    },
    {
      'category': 'Account & Profile',
      'q': 'Can I access Examinantt on a desktop PC / Laptop?',
      'a': 'Yes! You can log in on your computer browser by visiting web.examinantt.com using your registered student phone number and password.',
    },
    {
      'category': 'Account & Profile',
      'q': 'How do I change my target exam or target year?',
      'a': 'Open Account Settings from the Profile dashboard, select your primary exam category, and your entire study plan will adjust dynamically.',
    },
    {
      'category': 'Technical Issues',
      'q': 'Video player is buffering or showing a black screen, what should I do?',
      'a': 'Ensure you have an active internet connection. You can lower the video quality from 1080p to 480p/720p using the gear settings icon inside the player, or clear app cache.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0A122C) : Colors.grey.shade50;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;

    final filteredFaqs = _allFaqs.where((f) {
      final matchesCategory = _selectedCategory == 'All' || f['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          f['q']!.toLowerCase().contains(_searchQuery) ||
          f['a']!.toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help Center & FAQs',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search queries, questions, topics...',
                hintStyle: TextStyle(color: subColor, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: subColor, size: 20),
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                ),
              ),
            ),
          ),

          // Categories Horizontal Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                    },
                    selectedColor: const Color(0xFFFFA000),
                    backgroundColor: cardBg,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFFA000) : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade300),
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),

          // FAQ List
          Expanded(
            child: filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: subColor),
                        const SizedBox(height: 12),
                        Text('No FAQs match your search.', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Try another keyword or select All categories.', style: TextStyle(color: subColor, fontSize: 12.5)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            title: Text(
                              faq['q']!,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            iconColor: const Color(0xFFFFA000),
                            collapsedIconColor: subColor,
                            children: [
                              Text(
                                faq['a']!,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// DEDICATED FULL PAGE: Create Support Ticket / Bug Report / Suggestions
class CreateSupportTicketScreen extends StatefulWidget {
  final String initialType;
  final VoidCallback? onTicketCreated;

  const CreateSupportTicketScreen({
    super.key,
    required this.initialType,
    this.onTicketCreated,
  });

  @override
  State<CreateSupportTicketScreen> createState() => _CreateSupportTicketScreenState();
}

class _CreateSupportTicketScreenState extends State<CreateSupportTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  String _selectedPriority = 'Normal';
  bool _isSubmitting = false;

  final List<String> _ticketTypes = [
    'Support Ticket',
    'Bug Report',
    'Feature Suggestion',
    'Refund Request',
  ];

  final List<String> _priorities = ['Low', 'Normal', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _selectedType = _ticketTypes.contains(widget.initialType) ? widget.initialType : 'Support Ticket';
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      widget.onTicketCreated?.call();
      Navigator.pop(context);
      AppTheme.showSuccessSnackBar(
        context,
        'Ticket submitted! ID: #${10000 + DateTime.now().millisecond}. Response guaranteed within 24 hours.',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0A122C) : Colors.grey.shade50;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Submit $_selectedType',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA000).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.headset_mic_rounded, color: Color(0xFFFFA000), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Direct Academic Support Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                          const SizedBox(height: 2),
                          Text('Our dedicated support team responds to all tickets within 24 hours.', style: TextStyle(fontSize: 12, color: subColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category Selector
              Text('Issue Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    dropdownColor: cardBg,
                    items: _ticketTypes.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t, style: TextStyle(color: textColor, fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Priority Selector
              Text('Priority', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              Row(
                children: _priorities.map((p) {
                  final isSelected = _selectedPriority == p;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(p),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => _selectedPriority = p);
                      },
                      selectedColor: const Color(0xFFFFA000),
                      backgroundColor: cardBg,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFFFA000) : borderColor,
                        ),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Subject Input
              Text('Subject / Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _subjectCtrl,
                style: TextStyle(color: textColor, fontSize: 14),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null,
                decoration: InputDecoration(
                  hintText: 'Brief summary of what happened...',
                  hintStyle: TextStyle(color: subColor, fontSize: 14),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                ),
              ),
              const SizedBox(height: 18),

              // Detailed Description
              Text('Detailed Explanation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 5,
                style: TextStyle(color: textColor, fontSize: 14),
                validator: (v) => (v == null || v.trim().length < 10) ? 'Please write at least 10 characters' : null,
                decoration: InputDecoration(
                  hintText: 'Describe the problem, steps to reproduce or suggestions in detail...',
                  hintStyle: TextStyle(color: subColor, fontSize: 14),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Submit Support Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DEDICATED FULL PAGE: Support Tickets History & Status
class SupportTicketsScreen extends StatefulWidget {
  final int openCount;
  final int resolvedCount;
  final int closedCount;

  const SupportTicketsScreen({
    super.key,
    required this.openCount,
    required this.resolvedCount,
    required this.closedCount,
  });

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  String _activeTab = 'All';

  final List<Map<String, dynamic>> _tickets = [
    {
      'id': '#10042',
      'title': 'Payment verification for NEET Booster Batch',
      'status': 'Open',
      'date': 'Today, 02:45 PM',
      'desc': 'UPI transaction was successful but batch took a few minutes to reflect. Checking if payment is reconciled.',
      'reply': 'Support response: We verified the transaction and your batch is active and ready to stream.',
    },
    {
      'id': '#10029',
      'title': 'Video player buffering issue in Physics live stream',
      'status': 'Resolved',
      'date': '12 Oct 2026',
      'desc': 'Live stream had intermittent buffering during the 7 PM class.',
      'reply': 'Resolved: AWS CDN server latency was mitigated. Class recordings are fully available in 1080p.',
    },
    {
      'id': '#10015',
      'title': 'Question error in Reasoning Mock Test #4',
      'status': 'Resolved',
      'date': '05 Oct 2026',
      'desc': 'Question 24 had an ambiguous diagram in Section 2.',
      'reply': 'Academic review completed: +2 bonus marks awarded to all test takers and question updated.',
    },
    {
      'id': '#09982',
      'title': 'Account email update request',
      'status': 'Closed',
      'date': '20 Sep 2026',
      'desc': 'Wanted to update primary email to student personal domain.',
      'reply': 'Account details updated and verified successfully.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0A122C) : Colors.grey.shade50;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.grey.shade200;

    final filtered = _tickets.where((t) {
      if (_activeTab == 'All') return true;
      return t['status'] == _activeTab;
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Support Tickets',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Open', 'Resolved', 'Closed'].map((tab) {
                final isSelected = _activeTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(tab),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _activeTab = tab),
                    selectedColor: const Color(0xFFFFA000),
                    backgroundColor: cardBg,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isSelected ? const Color(0xFFFFA000) : borderColor),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final status = item['status'] as String;
                final isOpen = status == 'Open';
                final isResolved = status == 'Resolved';

                final statusColor = isOpen
                    ? const Color(0xFF3B82F6)
                    : (isResolved ? const Color(0xFF10B981) : const Color(0xFF8B5CF6));

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['id']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFA000), fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11.5)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(item['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: textColor)),
                      const SizedBox(height: 6),
                      Text(item['desc']!, style: TextStyle(fontSize: 12.5, color: subColor, height: 1.4)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF030D20) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item['reply']!, style: TextStyle(fontSize: 12, color: textColor, height: 1.35))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(item['date']!, style: TextStyle(fontSize: 11, color: subColor)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// DEDICATED FULL PAGE: Live Chat Assistant Screen
class LiveChatSupportScreen extends StatefulWidget {
  const LiveChatSupportScreen({super.key});

  @override
  State<LiveChatSupportScreen> createState() => _LiveChatSupportScreenState();
}

class _LiveChatSupportScreenState extends State<LiveChatSupportScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! Welcome to Examinantt Support Assistant. How can we help you with your preparation today?',
      'isBot': true,
      'time': 'Just now',
    }
  ];

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();

    setState(() {
      _messages.add({
        'text': text,
        'isBot': false,
        'time': 'Now',
      });
    });

    _scrollToBottom();

    // Instant smart automated reply
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      String reply = 'Thank you for reaching out! A dedicated support executive has received your inquiry.';
      final lower = text.toLowerCase();
      if (lower.contains('payment') || lower.contains('refund') || lower.contains('money')) {
        reply = 'Payments and invoices are processed via Razorpay. Any refund requests are processed back to your original source account in 5-7 working days.';
      } else if (lower.contains('test') || lower.contains('mock') || lower.contains('score')) {
        reply = 'You can check all test solutions, percentile rankings, and dynamic graphs under the "Tests" tab or Profile analytics.';
      } else if (lower.contains('batch') || lower.contains('course') || lower.contains('class')) {
        reply = 'All purchased batches unlock instantly with 100% lifetime validity, daily live streaming, and full lecture slide decks.';
      }

      setState(() {
        _messages.add({
          'text': reply,
          'isBot': true,
          'time': 'Just now',
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0A122C) : Colors.grey.shade50;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardBg = isDark ? const Color(0xFF0E1A3D) : Colors.white;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0A122C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Examinantt Support Bot',
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16),
                ),
                const Text(
                  'Online 24/7 • Instant Response',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isBot = msg['isBot'] as bool;
                return Align(
                  alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isBot
                          ? (isDark ? const Color(0xFF16254A) : Colors.white)
                          : const Color(0xFFFFA000),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isBot ? 2 : 16),
                        bottomRight: Radius.circular(isBot ? 16 : 2),
                      ),
                      border: isBot
                          ? Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200)
                          : null,
                    ),
                    child: Text(
                      msg['text'] as String,
                      style: TextStyle(
                        color: isBot ? textColor : Colors.white,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Message Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      onSubmitted: (_) => _sendMessage(),
                      style: TextStyle(color: textColor, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF16254A) : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFFA000),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
