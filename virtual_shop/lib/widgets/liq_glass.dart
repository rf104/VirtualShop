import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';
import 'package:virtual_shop/widgets/glass_container.dart';

class LiqGlass extends StatelessWidget {
  const LiqGlass({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your background content
        Image.asset('assets/images/demo1.jpg'),

        // Glass layer with custom settings
        const GlassContainer(
          width: 120,
          height: 80,
          borderRadius: 40,
          settings: OCLiquidGlassSettings(
            refractStrength: -0.08, // Stronger refraction
            blurRadiusPx: 2.0, // Add frosted glass blur
            specStrength: 25.0, // Brighter reflections
            lightbandColor: Colors.cyan, // Colored light band
          ),
          child: Center(
            child: Text(
              'Liquid Glass',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
