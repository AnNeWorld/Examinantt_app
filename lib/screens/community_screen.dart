import 'package:flutter/material.dart';
import '../widgets/community_chat_view.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070F1E),
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
