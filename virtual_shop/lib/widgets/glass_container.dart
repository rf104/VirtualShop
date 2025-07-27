import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color color;
  final OCLiquidGlassSettings settings;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 30.0,
    this.color = Colors.transparent,
    this.settings = const OCLiquidGlassSettings(
      blurRadiusPx: 5,
      lightbandColor: Colors.greenAccent,
      specAngle: 0.0,
      specStrength: 0.0,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return OCLiquidGlassGroup(
      settings: settings,
      child: OCLiquidGlass(
        width: width,
        height: height,
        borderRadius: borderRadius,
        color: color,
        child: child,
      ),
    );
  }
}
