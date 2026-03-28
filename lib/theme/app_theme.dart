import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors: Hyper-Focus Brutalism / High-Contrast Monochromatism
  static const Color surface = Color(0xFF121414);
  static const Color surfaceContainerLow = Color(0xFF1B1C1C);
  static const Color surfaceContainerHigh = Color(0xFF292A2A);
  static const Color surfaceContainerLowest = Color(0xFF0D0E0F);
  static const Color surfaceVariant = Color(0xFF343535);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFF2F3131);
  static const Color secondaryFixedDim = Color(0xFFC6C6C7);
  static const Color secondary = Color(0xFFC7C6C6);
  static const Color onSurface = Color(0xFFE3E2E2);
  static const Color onSurfaceVariant = Color(0xFFC4C7C8);
  static const Color outlineVariant = Color(0xFF444748);
  
  static const Color success = Color(0xFF007A5A); // Vercel Green approx
  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimary,
        secondary: secondary,
        surface: surface,
        onSurface: onSurface,
        error: error,
        errorContainer: errorContainer,
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          displayMedium: const TextStyle(
            fontSize: 44, // 2.75rem approx
            letterSpacing: -0.04 * 44,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
          titleSmall: const TextStyle(
            fontSize: 16, // 1rem
            fontWeight: FontWeight.w600,
            color: primary,
          ),
          bodyMedium: const TextStyle(
            fontSize: 14, // 0.875rem
            color: onSurface,
          ),
          labelSmall: const TextStyle(
            fontSize: 11, // 0.6875rem
            letterSpacing: 0.05 * 11,
            fontWeight: FontWeight.w600,
            color: onSurfaceVariant,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2), // radius-sm (0.125rem)
          ),
        ),
      ),
    );
  }
}

