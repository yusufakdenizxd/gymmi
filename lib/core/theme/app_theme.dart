import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Colors
  static const primary = Color(0xFF6C63FF); // Modern Purple
  static const secondary = Color(0xFF32E0C4); // Mint Green
  static const accent = Color(0xFF00D9F5); // Bright Cyan
  static const background = Color(0xFFF8F9FF); // Light Blue-tinted White
  static const surface = Colors.white;

  // Status Colors
  static const error = Color(0xFFFF4949); // Bright Red
  static const success = Color(0xFF00C853); // Vibrant Green
  static const warning = Color(0xFFFFB300); // Amber

  // Text Colors
  static const textPrimary = Color(0xFF2B2D42); // Dark Blue-Grey
  static const textSecondary = Color(0xFF8D99AE); // Cool Grey
  static const textLight = Color(0xFFCED4DA); // Light Grey

  // Additional Colors for Fitness Features
  static const energy = Color(0xFF00D9F5); // Cyan for Energy
  static const heart = Color(0xFFFF6B6B); // Red for Heart Rate
  static const water = Color(0xFF63C5DA); // Blue for Hydration
  static const sleep = Color(0xFF845EC2); // Purple for Sleep/Rest

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B85FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const energyGradient = LinearGradient(
    colors: [Color(0xFFFF8008), Color(0xFFFFC837)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heartGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const waterGradient = LinearGradient(
    colors: [Color(0xFF63C5DA), Color(0xFF96E4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Styles with new font
  static final TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.poppins(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      letterSpacing: -0.5,
    ),
    displayMedium: GoogleFonts.poppins(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: textPrimary,
      letterSpacing: -0.5,
    ),
    displaySmall: GoogleFonts.poppins(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    headlineMedium: GoogleFonts.poppins(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      color: textPrimary,
      letterSpacing: 0.2,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      color: textPrimary,
      letterSpacing: 0.2,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primary,
      letterSpacing: 0.2,
    ),
  );

  // Input Decoration with softer borders
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: textLight.withOpacity(0.5)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: textLight.withOpacity(0.5)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: error),
    ),
    labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
    floatingLabelStyle: textTheme.bodyMedium?.copyWith(color: primary),
  );

  // Button Themes with enhanced shadows
  static ElevatedButtonThemeData elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      textStyle: textTheme.labelLarge?.copyWith(
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    ).copyWith(
      elevation: WidgetStateProperty.resolveWith<double>(
        (Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) return 0;
          return 4;
        },
      ),
    ),
  );

  // Card Theme with subtle shadows
  static CardTheme cardTheme = CardTheme(
    elevation: 4,
    shadowColor: primary.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    color: surface,
  );

  // Bottom Navigation Bar Theme
  static BottomNavigationBarThemeData bottomNavigationBarTheme = const BottomNavigationBarThemeData(
    backgroundColor: surface,
    selectedItemColor: primary,
    unselectedItemColor: textSecondary,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  );

  // App Bar Theme with transparency
  static AppBarTheme appBarTheme = AppBarTheme(
    elevation: 0,
    backgroundColor: surface.withOpacity(0.8),
    foregroundColor: textPrimary,
    centerTitle: true,
    titleTextStyle: textTheme.headlineMedium,
  );

  // Get ThemeData
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: error,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      inputDecorationTheme: inputDecorationTheme,
      elevatedButtonTheme: elevatedButtonTheme,
      cardTheme: cardTheme,
      bottomNavigationBarTheme: bottomNavigationBarTheme,
      appBarTheme: appBarTheme,
    );
  }
}
