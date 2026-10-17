import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Global touch ripple effect wrapper.
/// Listens to pointer down events anywhere on the screen and paints a fluid,
/// elegant ripple animation at the exact touch location without blocking
/// or interfering with any underlying gestures, scrolling, or clicks.
class GlobalTapEffect extends StatefulWidget {
  final Widget child;

  const GlobalTapEffect({
    super.key,
    required this.child,
  });

  @override
  State<GlobalTapEffect> createState() => _GlobalTapEffectState();
}

class _GlobalTapEffectState extends State<GlobalTapEffect>
    with TickerProviderStateMixin {
  final List<_RippleItem> _ripples = [];
  final ValueNotifier<int> _ticker = ValueNotifier<int>(0);
  final math.Random _random = math.Random();

  void _onPointerDown(PointerDownEvent event) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final Offset localPosition = renderBox != null
        ? renderBox.globalToLocal(event.position)
        : event.position;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Create 5 subtle sparkle particles shooting outward
    final List<_ParticleItem> particles = List.generate(5, (index) {
      final double baseAngle = (index * 2 * math.pi / 5);
      final double angleVariance = (_random.nextDouble() - 0.5) * 0.4;
      return _ParticleItem(
        angle: baseAngle + angleVariance,
        distance: 24.0 + _random.nextDouble() * 16.0,
        radius: 1.5 + _random.nextDouble() * 1.5,
      );
    });

    final ripple = _RippleItem(
      position: localPosition,
      controller: controller,
      particles: particles,
    );

    controller.addListener(() {
      _ticker.value++;
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _ripples.remove(ripple);
        controller.dispose();
        _ticker.value++;
      }
    });

    _ripples.add(ripple);
    controller.forward();
    _ticker.value++;
  }

  @override
  void dispose() {
    for (final ripple in _ripples) {
      ripple.controller.dispose();
    }
    _ripples.clear();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent = AppColors.accent;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _RipplePainter(
                    ripples: _ripples,
                    repaint: _ticker,
                    accentColor: primaryAccent,
                    isDark: isDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RippleItem {
  final Offset position;
  final AnimationController controller;
  final List<_ParticleItem> particles;

  _RippleItem({
    required this.position,
    required this.controller,
    required this.particles,
  });
}

class _ParticleItem {
  final double angle;
  final double distance;
  final double radius;

  _ParticleItem({
    required this.angle,
    required this.distance,
    required this.radius,
  });
}

class _RipplePainter extends CustomPainter {
  final List<_RippleItem> ripples;
  final Color accentColor;
  final bool isDark;

  _RipplePainter({
    required this.ripples,
    required super.repaint,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (ripples.isEmpty) return;

    for (final ripple in ripples) {
      final double progress = ripple.controller.value;
      if (progress <= 0.0 || progress >= 1.0) continue;

      final double curvedProgress = Curves.easeOutCubic.transform(progress);
      final double fadeProgress = Curves.easeOutQuad.transform(progress);
      final double opacity = (1.0 - fadeProgress).clamp(0.0, 1.0);

      final center = ripple.position;

      // 1. Soft glowing center halo
      final double glowRadius = 4.0 + 26.0 * curvedProgress;
      final Paint glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            accentColor.withValues(alpha: 0.35 * opacity),
            accentColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: glowRadius))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, glowRadius, glowPaint);

      // 2. Main expanding outer ring
      final double ringRadius = 6.0 + 34.0 * curvedProgress;
      final double strokeWidth = (2.2 * (1.0 - curvedProgress * 0.6)).clamp(0.8, 2.5);
      final Paint ringPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.65 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, ringRadius, ringPaint);

      // 3. Second delayed echo ring (creates rich, tactile wave effect)
      if (progress > 0.15) {
        final double echoProgress = Curves.easeOutQuad.transform(
          ((progress - 0.15) / 0.85).clamp(0.0, 1.0),
        );
        final double echoRadius = 4.0 + 22.0 * echoProgress;
        final double echoOpacity = (1.0 - echoProgress).clamp(0.0, 1.0);
        final Paint echoPaint = Paint()
          ..color = (isDark ? Colors.white : accentColor).withValues(
            alpha: 0.35 * echoOpacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(center, echoRadius, echoPaint);
      }

      // 4. Subtle micro sparkle particles
      final double particleOpacity = (1.0 - fadeProgress).clamp(0.0, 1.0);
      for (final p in ripple.particles) {
        final double currentDist = p.distance * curvedProgress;
        final double px = center.dx + currentDist * math.cos(p.angle);
        final double py = center.dy + currentDist * math.sin(p.angle);

        final Paint particlePaint = Paint()
          ..color = accentColor.withValues(alpha: 0.7 * particleOpacity)
          ..style = PaintingStyle.fill;

        final double currentSize = p.radius * (1.0 - curvedProgress * 0.5);
        canvas.drawCircle(Offset(px, py), currentSize, particlePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) => true;
}
