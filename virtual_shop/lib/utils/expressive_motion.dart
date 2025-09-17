// import 'package:motor/motor.dart';
import 'package:flutter/material.dart';

/// Material 3 Expressive Motion System
/// Physics-based animations for natural, fluid motion

class ExpressiveMotion {
  // Material Design 3 Spring Motion Tokens
  // These will be used when the motor package is available

  // Standard Spatial Motion - for position, size, and layout changes
  static const Duration standardSpatialFastDuration = Duration(
    milliseconds: 200,
  );
  static const Duration standardSpatialDefaultDuration = Duration(
    milliseconds: 300,
  );
  static const Duration standardSpatialSlowDuration = Duration(
    milliseconds: 500,
  );

  // Expressive Spatial Motion - with bounce and personality
  static const Duration expressiveSpatialFastDuration = Duration(
    milliseconds: 250,
  );
  static const Duration expressiveSpatialDefaultDuration = Duration(
    milliseconds: 400,
  );
  static const Duration expressiveSpatialSlowDuration = Duration(
    milliseconds: 600,
  );

  // Standard Effects Motion - for opacity, color changes
  static const Duration standardEffectsFastDuration = Duration(
    milliseconds: 100,
  );
  static const Duration standardEffectsDefaultDuration = Duration(
    milliseconds: 200,
  );
  static const Duration standardEffectsSlowDuration = Duration(
    milliseconds: 300,
  );

  // Expressive spring curves for natural motion
  static const Curve expressiveSpringCurve = Curves.easeOutBack;
  static const Curve smoothSpringCurve = Curves.easeOutCubic;
  static const Curve bouncySpringCurve = Curves.elasticOut;
  static const Curve snappySpringCurve = Curves.easeOutQuart;

  // Future: Material Spring Motion tokens (when motor package is integrated)
  /*
  static Motion get standardSpatialFast => MaterialSpringMotion.standardSpatialFast();
  static Motion get standardSpatialDefault => MaterialSpringMotion.standardSpatialDefault();
  static Motion get standardSpatialSlow => MaterialSpringMotion.standardSpatialSlow();
  
  static Motion get expressiveSpatialFast => MaterialSpringMotion.expressiveSpatialFast();
  static Motion get expressiveSpatialDefault => MaterialSpringMotion.expressiveSpatialDefault();
  static Motion get expressiveSpatialSlow => MaterialSpringMotion.expressiveSpatialSlow();
  
  static Motion get standardEffectsFast => MaterialSpringMotion.standardEffectsFast();
  static Motion get standardEffectsDefault => MaterialSpringMotion.standardEffectsDefault();
  static Motion get standardEffectsSlow => MaterialSpringMotion.standardEffectsSlow();
  */

  // Spring simulation parameters for natural motion
  static SpringDescription createExpressiveSpring({
    double mass = 1.0,
    double stiffness = 380.0,
    double damping = 0.8,
  }) {
    return SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
  }

  static SpringDescription createSmoothSpring({
    double mass = 1.0,
    double stiffness = 700.0,
    double damping = 0.9,
  }) {
    return SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
  }

  static SpringDescription createBouncySpring({
    double mass = 1.0,
    double stiffness = 800.0,
    double damping = 0.6,
  }) {
    return SpringDescription(
      mass: mass,
      stiffness: stiffness,
      damping: damping,
    );
  }

  // Predefined animation curves for different expressive moments
  static Curve getCurveForContext(ExpressiveContext context) {
    switch (context) {
      case ExpressiveContext.hero:
        return bouncySpringCurve;
      case ExpressiveContext.playful:
        return expressiveSpringCurve;
      case ExpressiveContext.energetic:
        return snappySpringCurve;
      case ExpressiveContext.smooth:
        return smoothSpringCurve;
      case ExpressiveContext.subtle:
        return Curves.easeInOut;
    }
  }

  static Duration getDurationForContext(ExpressiveContext context) {
    switch (context) {
      case ExpressiveContext.hero:
        return expressiveSpatialSlowDuration;
      case ExpressiveContext.playful:
        return expressiveSpatialDefaultDuration;
      case ExpressiveContext.energetic:
        return expressiveSpatialFastDuration;
      case ExpressiveContext.smooth:
        return standardSpatialDefaultDuration;
      case ExpressiveContext.subtle:
        return standardEffectsDefaultDuration;
    }
  }

  // Shape morph animation support
  static AnimationController createShapeMorphController({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? expressiveSpatialDefaultDuration,
      vsync: vsync,
    );
  }

  // Custom tween for smooth shape morphing
  static Tween<double> createShapeMorphTween({
    double begin = 0.0,
    double end = 1.0,
  }) {
    return Tween<double>(begin: begin, end: end);
  }

  // Page transition with expressive motion
  static PageRouteBuilder createExpressivePageRoute({
    required Widget page,
    ExpressiveContext motionContext = ExpressiveContext.smooth,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: getDurationForContext(motionContext),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = getCurveForContext(motionContext);

        return SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: curve)),
          ),
          child: child,
        );
      },
    );
  }

  // Floating action button with expressive animation
  static Widget createExpressiveFAB({
    required VoidCallback onPressed,
    required Widget child,
    ExpressiveContext context = ExpressiveContext.playful,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: getDurationForContext(context),
      curve: getCurveForContext(context),
      builder: (context, scale, widget) {
        return Transform.scale(
          scale: scale,
          child: FloatingActionButton(onPressed: onPressed, child: child),
        );
      },
    );
  }

  // Animated container with expressive motion
  static Widget createExpressiveContainer({
    required Widget child,
    required bool isExpanded,
    ExpressiveContext context = ExpressiveContext.smooth,
    EdgeInsetsGeometry? padding,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return AnimatedContainer(
      duration: getDurationForContext(context),
      curve: getCurveForContext(context),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  // Loading indicator with expressive animation
  static Widget createExpressiveLoading({
    ExpressiveContext context = ExpressiveContext.energetic,
    Color? color,
    double size = 24.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: getDurationForContext(context),
      curve: getCurveForContext(context),
      builder: (context, progress, child) {
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            color: color,
            strokeWidth: 3.0,
          ),
        );
      },
    );
  }
}

// Context enum for different expressive moments
enum ExpressiveContext {
  hero, // For standout, attention-grabbing moments
  playful, // For fun, engaging interactions
  energetic, // For quick, responsive actions
  smooth, // For elegant, flowing transitions
  subtle, // For gentle, understated changes
}
