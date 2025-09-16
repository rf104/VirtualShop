import 'package:flutter/material.dart';
// import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_color_utilities/material_color_utilities.dart';

/// Material 3 Expressive Color Schemes for VirtualShop
/// Based on the new vibrant color guidelines from M3 Expressive

class ExpressiveColors {
  // Base seed colors for dynamic color schemes
  static const Color primarySeed = Color(0xFF6750A4); // Rich purple
  static const Color secondarySeed = Color(
    0xFF625B71,
  ); // Complementary gray-purple
  static const Color tertiarySeed = Color(0xFF7D5260); // Warm accent

  // Expressive accent colors
  static const Color vibrantAccent = Color(0xFFE91E63); // Bright pink
  static const Color energeticOrange = Color(0xFFFF6F00); // Energetic orange
  static const Color creativeTeal = Color(0xFF00BCD4); // Creative teal
  static const Color playfulGreen = Color(0xFF4CAF50); // Playful green

  // Create expressive light color scheme
  static ColorScheme createExpressiveLightScheme() {
    return ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.light,
      // Enhanced contrast for expressive design
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    ).copyWith(
      // Custom expressive colors for container surfaces
      primaryContainer: const Color(0xFFEADDFF),
      secondaryContainer: const Color(0xFFE8DEF8),
      tertiaryContainer: const Color(0xFFFFD8E4),
      // Enhanced surface colors for expressive containers
      surfaceContainerHighest: const Color(0xFFF3E5F5),
      surfaceContainerHigh: const Color(0xFFF8F0FF),
      surfaceContainer: const Color(0xFFFCF8FF),
      // Custom error colors
      error: const Color(0xFFBA1A1A),
      errorContainer: const Color(0xFFFFDAD6),
    );
  }

  // Create expressive dark color scheme
  static ColorScheme createExpressiveDarkScheme() {
    return ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: Brightness.dark,
      // Enhanced contrast for expressive design
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    ).copyWith(
      // Custom expressive colors for container surfaces
      primaryContainer: const Color(0xFF4F378B),
      secondaryContainer: const Color(0xFF4A4458),
      tertiaryContainer: const Color(0xFF633B48),
      // Enhanced surface colors for expressive containers
      surfaceContainerHighest: const Color(0xFF2B2930),
      surfaceContainerHigh: const Color(0xFF211F26),
      surfaceContainer: const Color(0xFF1D1B20),
      // Custom error colors
      error: const Color(0xFFFFB4AB),
      errorContainer: const Color(0xFF93000A),
    );
  }

  // FlexColorScheme configuration for advanced theming (temporarily commented out)
  /* 
  static FlexColorScheme createFlexLightScheme() {
    return FlexColorScheme.light(
      scheme: FlexScheme.mandyRed,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      appBarStyle: FlexAppBarStyle.material,
      appBarOpacity: 0.87,
      transparentStatusBar: true,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      swapLegacyOnMaterial3: true,
      useMaterial3: true,
      // Custom colors for expressive design
      primary: primarySeed,
      secondary: secondarySeed,
      tertiary: tertiarySeed,
    );
  }

  static FlexColorScheme createFlexDarkScheme() {
    return FlexColorScheme.dark(
      scheme: FlexScheme.mandyRed,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      appBarStyle: FlexAppBarStyle.material,
      appBarOpacity: 0.90,
      transparentStatusBar: true,
      tabBarStyle: FlexTabBarStyle.forAppBar,
      tooltipsMatchBackground: true,
      swapLegacyOnMaterial3: true,
      useMaterial3: true,
      // Custom colors for expressive design
      primary: primarySeed,
      secondary: secondarySeed,
      tertiary: tertiarySeed,
    );
  }
  */

  // Helper method to create vibrant color palette
  static Map<String, Color> getVibrantPalette() {
    return {
      'vibrant': vibrantAccent,
      'energetic': energeticOrange,
      'creative': creativeTeal,
      'playful': playfulGreen,
      'primary': primarySeed,
      'secondary': secondarySeed,
      'tertiary': tertiarySeed,
    };
  }

  // Generate tonal palette for a given color
  static TonalPalette generateTonalPalette(Color color) {
    final hct = Hct.fromInt(color.value);
    return TonalPalette.of(hct.hue, hct.chroma);
  }

  // Get expressive container colors
  static Map<String, Color> getExpressiveContainerColors(
    Brightness brightness,
  ) {
    final palette = generateTonalPalette(primarySeed);

    if (brightness == Brightness.light) {
      return {
        'primaryContainer': Color(palette.get(90)),
        'secondaryContainer': Color(palette.get(85)),
        'tertiaryContainer': Color(palette.get(88)),
        'surfaceContainer': Color(palette.get(96)),
        'surfaceContainerHigh': Color(palette.get(94)),
        'surfaceContainerHighest': Color(palette.get(92)),
      };
    } else {
      return {
        'primaryContainer': Color(palette.get(30)),
        'secondaryContainer': Color(palette.get(25)),
        'tertiaryContainer': Color(palette.get(28)),
        'surfaceContainer': Color(palette.get(12)),
        'surfaceContainerHigh': Color(palette.get(17)),
        'surfaceContainerHighest': Color(palette.get(22)),
      };
    }
  }
}
