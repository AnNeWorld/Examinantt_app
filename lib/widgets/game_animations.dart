import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

/// 1. Tactile 3D Arcade / Video Game Button with Press Depth & Spring Physics
class GameButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color shadowColor;
  final double height;
  final double borderRadius;
  final bool isGlowing;

  const GameButton({
    super.key,
    required this.child,
    required this.onTap,
    this.primaryColor = AppColors.accent,
    this.shadowColor = const Color(0xFFC2410C),
    this.height = 48,
    this.borderRadius = 14,
    this.isGlowing = false,
  });

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double depth = 4.0;
    final double currentTopOffset = _isPressed ? depth : 0.0;
    final double currentBottomMargin = _isPressed ? 0.0 : depth;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(top: currentTopOffset, bottom: currentBottomMargin),
        height: widget.height - depth,
        decoration: BoxDecoration(
          color: widget.primaryColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            // Bottom 3D depth shadow
            BoxShadow(
              color: widget.shadowColor,
              offset: Offset(0, _isPressed ? 1 : depth),
              blurRadius: 0,
            ),
            if (widget.isGlowing)
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}

/// 2. Gamified Interactive Card with Touch Scale-Down & Spring Pop-Up
class GamifiedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const GamifiedCard({
    super.key,
    required this.child,
    this.onTap,
    this.glowColor,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  State<GamifiedCard> createState() => _GamifiedCardState();
}

class _GamifiedCardState extends State<GamifiedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.shade300;
    final activeGlow = widget.glowColor ?? AppColors.accent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isPressed ? activeGlow : borderColor,
              width: _isPressed ? 1.8 : 1.0,
            ),
            boxShadow: [
              if (_isPressed || widget.glowColor != null)
                BoxShadow(
                  color: activeGlow.withValues(alpha: _isPressed ? 0.35 : 0.15),
                  blurRadius: _isPressed ? 16 : 8,
                  spreadRadius: _isPressed ? 2 : 0,
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 3. Gamified Entry Animation Wrapper (Bounce, Slide, & Scale pop like Loot Boxes)
class GamifiedEntrance extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const GamifiedEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final computedDelay = delay + Duration(milliseconds: (index * 60).clamp(0, 600));

    return child
        .animate()
        .fadeIn(
          delay: computedDelay,
          duration: 350.ms,
          curve: Curves.easeOut,
        )
        .scale(
          begin: const Offset(0.88, 0.88),
          end: const Offset(1.0, 1.0),
          delay: computedDelay,
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .slideY(
          begin: 0.15,
          end: 0,
          delay: computedDelay,
          duration: 350.ms,
          curve: Curves.easeOutQuad,
        );
  }
}

/// 4. Gamified Pulse Level / XP Badge with Energy Aura
class GamePulseBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const GamePulseBadge({
    super.key,
    required this.label,
    this.icon = Icons.bolt,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14)
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.25, 1.25), duration: 800.ms),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

/// 5. Gamified XP / Progress Energy Bar with Shimmer Light Pulse
class GamifiedXPBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Color color;
  final double height;

  const GamifiedXPBar({
    super.key,
    required this.progress,
    this.color = AppColors.accent,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                width: constraints.maxWidth * clamped,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.8), Colors.white],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(height / 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2000.ms, color: Colors.white.withValues(alpha: 0.4));
  }
}
