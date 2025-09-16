import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Material 3 Expressive Typography System
/// Enhanced typography with emphasized styles for expressive design

class ExpressiveTypography {
  // Enhanced type scale with expressive variations
  static TextTheme createExpressiveTextTheme({
    required Brightness brightness,
    String? fontFamily = 'Poppins',
  }) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF1D1B20)
        : const Color(0xFFE6E1E5);

    return TextTheme(
      // Display styles - for hero moments and main headlines
      displayLarge: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        color: baseColor,
      ),
      displayMedium: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.16,
        color: baseColor,
      ),
      displaySmall: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
        color: baseColor,
      ),

      // Headline styles - for section headers
      headlineLarge: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.25,
        color: baseColor,
      ),
      headlineMedium: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.29,
        color: baseColor,
      ),
      headlineSmall: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.33,
        color: baseColor,
      ),

      // Title styles - for card headers and important UI elements
      titleLarge: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 22,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.27,
        color: baseColor,
      ),
      titleMedium: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.50,
        color: baseColor,
      ),
      titleSmall: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.10,
        height: 1.43,
        color: baseColor,
      ),

      // Label styles - for buttons and UI controls
      labelLarge: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.10,
        height: 1.43,
        color: baseColor,
      ),
      labelMedium: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.50,
        height: 1.33,
        color: baseColor,
      ),
      labelSmall: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.50,
        height: 1.45,
        color: baseColor,
      ),

      // Body styles - for main content
      bodyLarge: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.50,
        height: 1.50,
        color: baseColor,
      ),
      bodyMedium: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: baseColor,
      ),
      bodySmall: GoogleFonts.getFont(
        fontFamily ?? 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.40,
        height: 1.33,
        color: baseColor,
      ),
    );
  }

  // Emphasized typography styles for expressive moments
  static TextStyle emphasizedDisplay({
    required Brightness brightness,
    String? fontFamily = 'Poppins',
  }) {
    final emphasisColor = brightness == Brightness.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return GoogleFonts.getFont(
      fontFamily ?? 'Poppins',
      fontSize: 57,
      fontWeight: FontWeight.w700, // Bold for emphasis
      letterSpacing: -0.25,
      height: 1.12,
      color: emphasisColor,
    );
  }

  static TextStyle emphasizedHeadline({
    required Brightness brightness,
    String? fontFamily = 'Poppins',
  }) {
    final emphasisColor = brightness == Brightness.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return GoogleFonts.getFont(
      fontFamily ?? 'Poppins',
      fontSize: 32,
      fontWeight: FontWeight.w600, // Semi-bold for emphasis
      letterSpacing: 0,
      height: 1.25,
      color: emphasisColor,
    );
  }

  static TextStyle emphasizedTitle({
    required Brightness brightness,
    String? fontFamily = 'Poppins',
  }) {
    final emphasisColor = brightness == Brightness.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return GoogleFonts.getFont(
      fontFamily ?? 'Poppins',
      fontSize: 22,
      fontWeight: FontWeight.w600, // Semi-bold for emphasis
      letterSpacing: 0,
      height: 1.27,
      color: emphasisColor,
    );
  }

  static TextStyle emphasizedLabel({
    required Brightness brightness,
    String? fontFamily = 'Poppins',
  }) {
    final emphasisColor = brightness == Brightness.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return GoogleFonts.getFont(
      fontFamily ?? 'Poppins',
      fontSize: 14,
      fontWeight: FontWeight.w700, // Bold for emphasized actions
      letterSpacing: 0.10,
      height: 1.43,
      color: emphasisColor,
    );
  }

  // Expressive typography variants for hero moments
  static TextStyle heroText({
    required Brightness brightness,
    Color? customColor,
    String? fontFamily = 'Poppins',
  }) {
    final defaultColor = brightness == Brightness.light
        ? const Color(0xFF6750A4) // Primary color
        : const Color(0xFFD0BCFF);

    return GoogleFonts.getFont(
      fontFamily ?? 'Poppins',
      fontSize: 64,
      fontWeight: FontWeight.w800, // Extra bold for hero moments
      letterSpacing: -0.5,
      height: 1.0,
      color: customColor ?? defaultColor,
    );
  }

  static TextStyle playfulText({
    required Brightness brightness,
    Color? customColor,
    String? fontFamily = 'Poppins',
  }) {
    final defaultColor = brightness == Brightness.light
        ? const Color(0xFFE91E63) // Vibrant pink
        : const Color(0xFFFF80AB);

    return GoogleFonts.getFont(
      fontFamily ?? 'Poppins',
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      height: 1.2,
      color: customColor ?? defaultColor,
    );
  }

  static TextStyle energeticText({
    required Brightness brightness,
    Color? customColor,
    String? fontFamily = 'Poppins',
  }) {
    final defaultColor = brightness == Brightness.light
        ? const Color(0xFFFF6F00) // Energetic orange
        : const Color(0xFFFFCC02);

    return GoogleFonts.getFont(
      fontFamily ?? 'Poppins',
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.25,
      height: 1.3,
      color: customColor ?? defaultColor,
    );
  }

  // Helper method to get emphasized style based on text theme style
  static TextStyle getEmphasizedStyle(
    TextStyle baseStyle, {
    FontWeight? emphasisWeight,
    Color? emphasisColor,
  }) {
    return baseStyle.copyWith(
      fontWeight: emphasisWeight ?? FontWeight.w700,
      color: emphasisColor ?? baseStyle.color,
    );
  }
}
