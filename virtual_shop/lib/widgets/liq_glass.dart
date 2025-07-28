import 'package:flutter/material.dart';
import 'package:oc_liquid_glass/oc_liquid_glass.dart';

class LiqGlass extends StatelessWidget {
  const LiqGlass({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Your background content
        Image.asset('assets/images/demo1.jpg'),

        // Glass layer with custom settings
        OCLiquidGlassGroup(
          settings: const OCLiquidGlassSettings(
            refractStrength: -0.08, // Stronger refraction
            blurRadiusPx: 2.0, // Add frosted glass blur
            specStrength: 25.0, // Brighter reflections
            lightbandColor: Colors.cyan, // Colored light band
          ),
          child: OCLiquidGlass(
            width: 120,
            height: 80,
            borderRadius: 40,
            child: Container(
              alignment: Alignment.center,
              child: const Text(
                'Liquid Glass',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
