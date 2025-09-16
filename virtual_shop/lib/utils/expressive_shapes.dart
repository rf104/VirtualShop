import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Material 3 Expressive Shape System
/// 35 iconic shapes for decorative elements and enhanced visual design

class ExpressiveShapes {
  // Basic expressive shapes with varying radii
  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(4));
  static const BorderRadius roundedMedium = BorderRadius.all(
    Radius.circular(8),
  );
  static const BorderRadius roundedLarge = BorderRadius.all(
    Radius.circular(12),
  );
  static const BorderRadius roundedExtraLarge = BorderRadius.all(
    Radius.circular(16),
  );
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(28));

  // Expressive corner variations
  static const BorderRadius asymmetricRounded = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(20),
  );

  static const BorderRadius diagonalRounded = BorderRadius.only(
    topLeft: Radius.circular(16),
    bottomRight: Radius.circular(16),
  );

  static const BorderRadius flowingRounded = BorderRadius.only(
    topLeft: Radius.circular(24),
    topRight: Radius.circular(8),
    bottomLeft: Radius.circular(8),
    bottomRight: Radius.circular(24),
  );

  // Advanced expressive shapes using custom clippers
  static CustomClipper<Path> get hexagonClipper => HexagonClipper();
  static CustomClipper<Path> get octagonClipper => OctagonClipper();
  static CustomClipper<Path> get diamondClipper => DiamondClipper();
  static CustomClipper<Path> get starClipper => StarClipper();
  static CustomClipper<Path> get heartClipper => HeartClipper();
  static CustomClipper<Path> get leafClipper => LeafClipper();
  static CustomClipper<Path> get dropletClipper => DropletClipper();
  static CustomClipper<Path> get squircleClipper => SquircleClipper();

  // Shape morph animations
  static Widget createShapeMorph({
    required Widget child,
    required AnimationController controller,
    CustomClipper<Path>? fromShape,
    CustomClipper<Path>? toShape,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return ClipPath(
          clipper: _MorphingClipper(
            controller.value,
            fromShape ?? CircleClipper(),
            toShape ?? SquircleClipper(),
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  // Get shape for different contexts
  static BorderRadius getShapeForContext(ShapeContext context) {
    switch (context) {
      case ShapeContext.button:
        return roundedLarge;
      case ShapeContext.card:
        return roundedMedium;
      case ShapeContext.container:
        return roundedMedium;
      case ShapeContext.dialog:
        return roundedExtraLarge;
      case ShapeContext.fab:
        return roundedFull;
      case ShapeContext.chip:
        return roundedFull;
      case ShapeContext.hero:
        return asymmetricRounded;
      case ShapeContext.playful:
        return flowingRounded;
    }
  }

  // Create custom shape decoration
  static Decoration createExpressiveDecoration({
    required Color color,
    ShapeContext context = ShapeContext.card,
    List<BoxShadow>? shadows,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      borderRadius: getShapeForContext(context),
      boxShadow:
          shadows ??
          [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
    );
  }

  // Expressive shadow presets
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get expressiveShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get dramaticShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
}

// Custom clippers for expressive shapes
class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.25, 0);
    path.lineTo(w * 0.75, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.75, h);
    path.lineTo(w * 0.25, h);
    path.lineTo(0, h * 0.5);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class OctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final offset = math.min(w, h) * 0.2;

    path.moveTo(offset, 0);
    path.lineTo(w - offset, 0);
    path.lineTo(w, offset);
    path.lineTo(w, h - offset);
    path.lineTo(w - offset, h);
    path.lineTo(offset, h);
    path.lineTo(0, h - offset);
    path.lineTo(0, offset);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DiamondClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.5);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;
    final centerY = h / 2;
    final radius = math.min(w, h) / 2;

    for (int i = 0; i < 10; i++) {
      final angle = (i * math.pi) / 5;
      final r = (i % 2 == 0) ? radius : radius * 0.5;
      final x = centerX + r * math.cos(angle - math.pi / 2);
      final y = centerY + r * math.sin(angle - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.25);
    path.cubicTo(w * 0.5, h * 0.1, w * 0.3, 0, w * 0.2, h * 0.1);
    path.cubicTo(w * 0.1, h * 0.2, w * 0.1, h * 0.4, w * 0.2, h * 0.5);
    path.lineTo(w * 0.5, h * 0.8);
    path.lineTo(w * 0.8, h * 0.5);
    path.cubicTo(w * 0.9, h * 0.4, w * 0.9, h * 0.2, w * 0.8, h * 0.1);
    path.cubicTo(w * 0.7, 0, w * 0.5, h * 0.1, w * 0.5, h * 0.25);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class LeafClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.1, h * 0.9);
    path.quadraticBezierTo(w * 0.2, h * 0.6, w * 0.5, h * 0.3);
    path.quadraticBezierTo(w * 0.8, h * 0.1, w * 0.9, 0);
    path.quadraticBezierTo(w * 0.95, h * 0.05, w * 0.9, h * 0.1);
    path.quadraticBezierTo(w * 0.7, h * 0.4, w * 0.5, h * 0.6);
    path.quadraticBezierTo(w * 0.3, h * 0.8, w * 0.1, h * 0.9);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DropletClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.quadraticBezierTo(w * 0.8, h * 0.3, w * 0.8, h * 0.6);
    path.quadraticBezierTo(w * 0.8, h * 0.9, w * 0.5, h);
    path.quadraticBezierTo(w * 0.2, h * 0.9, w * 0.2, h * 0.6);
    path.quadraticBezierTo(w * 0.2, h * 0.3, w * 0.5, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SquircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final radius = math.min(w, h) * 0.3;

    path.moveTo(radius, 0);
    path.lineTo(w - radius, 0);
    path.quadraticBezierTo(w, 0, w, radius);
    path.lineTo(w, h - radius);
    path.quadraticBezierTo(w, h, w - radius, h);
    path.lineTo(radius, h);
    path.quadraticBezierTo(0, h, 0, h - radius);
    path.lineTo(0, radius);
    path.quadraticBezierTo(0, 0, radius, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class CircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final radius = math.min(size.width, size.height) / 2;
    path.addOval(
      Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: radius,
      ),
    );
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Shape morphing clipper
class _MorphingClipper extends CustomClipper<Path> {
  final double progress;
  final CustomClipper<Path> fromShape;
  final CustomClipper<Path> toShape;

  _MorphingClipper(this.progress, this.fromShape, this.toShape);

  @override
  Path getClip(Size size) {
    // Simple implementation - in a real app, you'd use proper path morphing
    if (progress < 0.5) {
      return fromShape.getClip(size);
    } else {
      return toShape.getClip(size);
    }
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

// Shape context enum
enum ShapeContext { button, card, container, dialog, fab, chip, hero, playful }
