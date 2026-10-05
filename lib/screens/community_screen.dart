import 'package:flutter/material.dart';
import '../widgets/community_chat_view.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070F1E) : Colors.white,
      body: SafeArea(
        child: CommunityChatView(
          isEmbedded: false,
          onBack: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}
