import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

class AnimatedTabGlass extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final bool shouldAnimate;

  const AnimatedTabGlass({
    super.key,
    required this.child,
    required this.isSelected,
    required this.shouldAnimate,
  });

  @override
  State<AnimatedTabGlass> createState() => _AnimatedTabGlassState();
}

class _AnimatedTabGlassState extends State<AnimatedTabGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedTabGlass oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shouldAnimate && widget.isSelected) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background glass effect for selected tab
        if (widget.isSelected)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: widget.shouldAnimate ? _opacityAnimation.value : 0.3,
                  child: OCLiquidGlassGroup(
                    settings: const OCLiquidGlassSettings(
                      blurRadiusPx: 2000,
                      blendPx: 14,
                      refractStrength: -0.12,
                      distortFalloffPx: 60,
                      distortExponent: 2.2,
                      specAngle: 35.0,
                      specStrength: 0.55,
                      specPower: 28.0,
                      specWidth: 2.4,
                      lightbandOffsetPx: 8,
                      lightbandWidthPx: 18,
                      lightbandStrength: 0.85,
                      lightbandColor: Colors.green,
                    ),
                    child: OCLiquidGlass(
                      width: (MediaQuery.of(context).size.width - 20) / 4.5,
                      height: 70,
                      borderRadius: 50,
                      color: Colors.white.withOpacity(0.1),
                      child: const SizedBox(),
                    ),
                  ),
                ),
              );
            },
          ),
        // The actual tab content
        widget.child,
      ],
    );
  }
}
