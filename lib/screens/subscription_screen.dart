import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isAnnual = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Premium Plans'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Header
            const Icon(Icons.workspace_premium, size: 60, color: AppTheme.secondaryColor),
            const SizedBox(height: 16),
            const Text(
              'Unlock Your Potential',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
            ),
            const SizedBox(height: 8),
            Text(
              'Get unlimited access to all mock tests, video classes, and premium study materials.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 32),

            // Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildToggleButton('Monthly', !isAnnual),
                  _buildToggleButton('Annually (Save 40%)', isAnnual),
                ],
              ),
            ).animate().fade().slideY(begin: 0.1),
            const SizedBox(height: 32),

            // Plan Cards
            _buildPlanCard(
              title: 'Gold Pass',
              price: isAnnual ? '₹2999' : '₹399',
              duration: isAnnual ? '/year' : '/month',
              isPopular: true,
              color: AppTheme.secondaryColor,
              features: [
                'All SSC & Banking Mock Tests',
                'Live & Recorded Video Classes',
                'Downloadable PDF Notes',
                'Priority Doubt Solving',
                'Ad-free experience',
              ],
            ).animate().fade().scale(delay: 100.ms),
            
            const SizedBox(height: 24),
            
            _buildPlanCard(
              title: 'Silver Pass',
              price: isAnnual ? '₹1499' : '₹199',
              duration: isAnnual ? '/year' : '/month',
              isPopular: false,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              features: [
                'Only SSC Mock Tests',
                'Limited Video Classes',
                'Downloadable PDF Notes',
                'Standard Support',
              ],
            ).animate().fade().scale(delay: 200.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isAnnual = text.contains('Annually');
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? AppTheme.primaryColor : theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String duration,
    required bool isPopular,
    required Color color,
    required List<String> features,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPopular ? color : theme.colorScheme.onSurface.withOpacity(0.1), width: isPopular ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: isPopular ? color.withOpacity(0.15) : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'MOST POPULAR',
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.darkSlate),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  duration,
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(f, style: const TextStyle(fontSize: 14, color: AppTheme.darkSlate)),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? color : AppTheme.darkSlate,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Choose Plan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
