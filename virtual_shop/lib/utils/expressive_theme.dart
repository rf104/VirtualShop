import 'package:flutter/material.dart';
import 'package:virtual_shop/utils/expressive_colors.dart';
import 'package:virtual_shop/utils/expressive_typography.dart';
import 'package:virtual_shop/utils/expressive_shapes.dart';
import 'package:virtual_shop/utils/expressive_motion.dart';

/// Material 3 Expressive Theme System
/// Complete theme implementation with vibrant colors, emphasized typography,
/// expressive shapes, and natural motion

class ExpressiveTheme {
  // Create complete expressive light theme
  static ThemeData createLightTheme() {
    final colorScheme = ExpressiveColors.createExpressiveLightScheme();
    final textTheme = ExpressiveTypography.createExpressiveTextTheme(
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // Enhanced AppBar with expressive design
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: ExpressiveTypography.emphasizedTitle(
          brightness: Brightness.light,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),

      // Expressive Card theme
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(ShapeContext.card),
        ),
        shadowColor: colorScheme.shadow,
      ),

      // Enhanced Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 4,
          shadowColor: colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: ExpressiveShapes.getShapeForContext(
              ShapeContext.button,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: ExpressiveTypography.emphasizedLabel(
            brightness: Brightness.light,
          ),
          animationDuration: ExpressiveMotion.standardEffectsDefaultDuration,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: ExpressiveShapes.getShapeForContext(
              ShapeContext.button,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: ExpressiveTypography.emphasizedLabel(
            brightness: Brightness.light,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: ExpressiveShapes.getShapeForContext(
              ShapeContext.button,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: ExpressiveTypography.emphasizedLabel(
            brightness: Brightness.light,
          ),
        ),
      ),

      // Expressive FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(ShapeContext.fab),
        ),
      ),

      // Enhanced input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.container,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.container,
          ),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.container,
          ),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.container,
          ),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      ),

      // Enhanced Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.dialog,
          ),
        ),
        titleTextStyle: ExpressiveTypography.emphasizedHeadline(
          brightness: Brightness.light,
        ),
        contentTextStyle: textTheme.bodyLarge,
      ),

      // Chip theme with expressive shapes
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        deleteIconColor: colorScheme.onSurfaceVariant,
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        selectedColor: colorScheme.secondaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge,
        brightness: Brightness.light,
        shape: RoundedRectangleBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(ShapeContext.chip),
        ),
      ),

      // Bottom Navigation Bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Navigation Rail theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Scaffold background
      scaffoldBackgroundColor: colorScheme.surface,

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Icon theme
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),

      // Primary icon theme
      primaryIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
    );
  }

  // Create complete expressive dark theme
  static ThemeData createDarkTheme() {
    final colorScheme = ExpressiveColors.createExpressiveDarkScheme();
    final textTheme = ExpressiveTypography.createExpressiveTextTheme(
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,

      // Enhanced AppBar with expressive design
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainer,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: ExpressiveTypography.emphasizedTitle(
          brightness: Brightness.dark,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),

      // Expressive Card theme
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(ShapeContext.card),
        ),
        shadowColor: colorScheme.shadow,
      ),

      // Enhanced Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 4,
          shadowColor: colorScheme.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: ExpressiveShapes.getShapeForContext(
              ShapeContext.button,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: ExpressiveTypography.emphasizedLabel(
            brightness: Brightness.dark,
          ),
          animationDuration: ExpressiveMotion.standardEffectsDefaultDuration,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: ExpressiveShapes.getShapeForContext(
              ShapeContext.button,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: ExpressiveTypography.emphasizedLabel(
            brightness: Brightness.dark,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: ExpressiveShapes.getShapeForContext(
              ShapeContext.button,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: ExpressiveTypography.emphasizedLabel(
            brightness: Brightness.dark,
          ),
        ),
      ),

      // Expressive FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(ShapeContext.fab),
        ),
      ),

      // Enhanced input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.container,
          ),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.container,
          ),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.container,
          ),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.container,
          ),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
        ),
      ),

      // Enhanced Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(
            ShapeContext.dialog,
          ),
        ),
        titleTextStyle: ExpressiveTypography.emphasizedHeadline(
          brightness: Brightness.dark,
        ),
        contentTextStyle: textTheme.bodyLarge,
      ),

      // Chip theme with expressive shapes
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        deleteIconColor: colorScheme.onSurfaceVariant,
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        selectedColor: colorScheme.secondaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge,
        brightness: Brightness.dark,
        shape: RoundedRectangleBorder(
          borderRadius: ExpressiveShapes.getShapeForContext(ShapeContext.chip),
        ),
      ),

      // Bottom Navigation Bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Navigation Rail theme
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.primary),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Scaffold background
      scaffoldBackgroundColor: colorScheme.surface,

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Icon theme
      iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),

      // Primary icon theme
      primaryIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
    );
  }

  // Get theme for specific expressive context
  static ThemeData getContextualTheme({
    required Brightness brightness,
    required ExpressiveContext context,
  }) {
    final baseTheme = brightness == Brightness.light
        ? createLightTheme()
        : createDarkTheme();

    switch (context) {
      case ExpressiveContext.hero:
        return baseTheme.copyWith(
          primaryColor: ExpressiveColors.vibrantAccent,
          colorScheme: baseTheme.colorScheme.copyWith(
            primary: ExpressiveColors.vibrantAccent,
          ),
        );
      case ExpressiveContext.playful:
        return baseTheme.copyWith(
          primaryColor: ExpressiveColors.playfulGreen,
          colorScheme: baseTheme.colorScheme.copyWith(
            primary: ExpressiveColors.playfulGreen,
          ),
        );
      case ExpressiveContext.energetic:
        return baseTheme.copyWith(
          primaryColor: ExpressiveColors.energeticOrange,
          colorScheme: baseTheme.colorScheme.copyWith(
            primary: ExpressiveColors.energeticOrange,
          ),
        );
      default:
        return baseTheme;
    }
  }

  // Helper method to get vibrant colors for different purposes
  static Map<String, Color> getVibrantPalette(Brightness brightness) {
    return ExpressiveColors.getVibrantPalette();
  }

  // Create custom decoration with expressive design
  static Decoration createExpressiveDecoration({
    required Color color,
    required Brightness brightness,
    ShapeContext context = ShapeContext.card,
    bool useGradient = false,
  }) {
    final shadows = ExpressiveShapes.softShadow;

    if (useGradient) {
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, color.withOpacity(0.8)],
      );

      return ExpressiveShapes.createExpressiveDecoration(
        color: color,
        context: context,
        shadows: shadows,
        gradient: gradient,
      );
    }

    return ExpressiveShapes.createExpressiveDecoration(
      color: color,
      context: context,
      shadows: shadows,
    );
  }
}
