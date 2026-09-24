import 'package:flutter/material.dart';

// ── Palette (earthy warm tones) ─────────────────────────────────────────────
abstract final class Palette {
  Palette._();

  static const Color darkWalnut = Color(0xFF582F0E);
  static const Color saddleBrown = Color(0xFF7F4F24);
  static const Color toffeeBrown = Color(0xFF936639);
  static const Color camel = Color(0xFFA68A64);
  static const Color khakiBeige = Color(0xFFB6AD90);
  static const Color drySage = Color(0xFFC2C5AA);
  static const Color drySage2 = Color(0xFFA4AC86);
  static const Color dustyOlive = Color(0xFF656D4A);
  static const Color ebony = Color(0xFF414833);
  static const Color charcoalBrown = Color(0xFF333D29);

  // Extrapolated
  static const Color warmOffWhite = Color(0xFFFEFAF2);
  static const Color warmBrick = Color(0xFFC84840);
  static const Color darkSurface = Color(0xFF1A1A1E);
  static const Color darkSurfaceContainer = Color(0xFF2A2A30);
  static const Color darkOnSurface = Color(0xFFE4E2DC);
  static const Color darkPrimaryLight = Color(0xFFB8845A);
  static const Color onPrimaryDark = Color(
    0xFFF5EDE0,
  ); // light warm text for dark primary bg

  // Outline / border: tuned for contrast
  static const Color outlineLight = Color(0xFF7A735D); // darken khaki a bit
  static const Color outlineVariantLight = Color(
    0xFFA49C82,
  ); // slightly darker than khakiBeige
  static const Color outlineDark = Color(0xFF8A9270); // lightened dusty olive
  static const Color outlineVariantDark = Color(
    0xFF535359,
  ); // visible against darkSurface

  // Dark-mode text on container backgrounds: bumped for readability
  static const Color onContainerDark = Color(
    0xFFE0D5C8,
  ); // warm light tone for toffee brown bg
}

// ── Light colour scheme ─────────────────────────────────────────────────────
ColorScheme _lightScheme() {
  return ColorScheme(
    brightness: Brightness.light,
    primary: Palette.toffeeBrown,
    onPrimary: Colors.white,
    primaryContainer: Palette.camel,
    onPrimaryContainer: Palette.onPrimaryDark,
    secondary: Palette.camel,
    onSecondary: Colors.white,
    secondaryContainer: Palette.khakiBeige,
    onSecondaryContainer: Palette.charcoalBrown,
    tertiary: Palette.drySage,
    onTertiary: Palette.charcoalBrown,
    tertiaryContainer: Palette.drySage2,
    onTertiaryContainer: Palette.ebony,
    error: Palette.warmBrick,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD4),
    onErrorContainer: Color(0xFF410002),
    surface: Palette.warmOffWhite,
    onSurface: Palette.ebony,
    surfaceContainerHighest: Palette.khakiBeige,
    onSurfaceVariant: Palette.dustyOlive,
    outline: Palette.outlineLight,
    outlineVariant: Palette.outlineVariantLight,
    inverseSurface: Palette.darkSurface,
    onInverseSurface: Palette.darkOnSurface,
    inversePrimary: Palette.darkPrimaryLight,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}

// ── Dark colour scheme ──────────────────────────────────────────────────────
ColorScheme _darkScheme() {
  return ColorScheme(
    brightness: Brightness.dark,
    primary: Palette.darkPrimaryLight,
    onPrimary: Palette.onPrimaryDark,
    primaryContainer: Palette.toffeeBrown,
    onPrimaryContainer: Palette.onContainerDark,
    secondary: Palette.camel,
    onSecondary: Palette.charcoalBrown,
    secondaryContainer: Palette.dustyOlive,
    onSecondaryContainer: Palette.khakiBeige,
    tertiary: Palette.drySage,
    onTertiary: Palette.ebony,
    tertiaryContainer: Palette.drySage2,
    onTertiaryContainer: Palette.charcoalBrown,
    error: Palette.warmBrick,
    onError: Colors.white,
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD4),
    surface: Palette.darkSurface,
    onSurface: Palette.darkOnSurface,
    surfaceContainerHighest: Palette.darkSurfaceContainer,
    onSurfaceVariant: Palette.khakiBeige,
    outline: Palette.outlineDark,
    outlineVariant: Palette.outlineVariantDark,
    inverseSurface: Palette.warmOffWhite,
    onInverseSurface: Palette.ebony,
    inversePrimary: Palette.toffeeBrown,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}

// ── AppTheme ────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = _lightScheme();
    return _themeData(scheme);
  }

  static ThemeData dark() {
    final scheme = _darkScheme();
    return _themeData(scheme);
  }

  static ThemeData _themeData(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),

      // Card
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Bottom Navigation
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(colorScheme.primary),
          foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      // Segmented button — selected uses primaryContainer/onPrimaryContainer
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primaryContainer;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimaryContainer;
            }
            return colorScheme.onSurface;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
    );
  }
}
