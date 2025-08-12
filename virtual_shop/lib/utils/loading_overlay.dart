import 'dart:math' as math;
import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(child: _PulsingSpinner()),
          ),
      ],
    );
  }
}

class _PulsingSpinner extends StatefulWidget {
  @override
  State<_PulsingSpinner> createState() => _PulsingSpinnerState();
}

class _PulsingSpinnerState extends State<_PulsingSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF6D9379);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final scale = 0.9 + 0.2 * math.sin(2 * math.pi * t);
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 6,
                  color: color,
                  backgroundColor: Colors.white24,
                ),
                Icon(Icons.shopping_cart, color: Colors.white, size: 36),
              ],
            ),
          ),
        );
      },
    );
  }
}
