import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpaceColors {
  static const midnight = Color(0xFF101522);
  static const violet = Color(0xFF7655F6);
  static const cyan = Color(0xFF22D3EE);
  static const ice = Color(0xFFF4F6FA);
  static const midnightRaised = Color(0xFF1A2133);
}

class SpaceTheme {
  static ThemeData dark() => _build(
        const ColorScheme.dark(
          primary: SpaceColors.violet,
          secondary: SpaceColors.cyan,
          surface: SpaceColors.midnight,
          onSurface: SpaceColors.ice,
        ),
        SpaceColors.midnight,
      );

  static ThemeData light() => _build(
        const ColorScheme.light(
          primary: SpaceColors.violet,
          secondary: SpaceColors.cyan,
          surface: SpaceColors.ice,
          onSurface: SpaceColors.midnight,
        ),
        SpaceColors.ice,
      );

  static ThemeData _build(ColorScheme scheme, Color bg) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
    );
    final dark = scheme.brightness == Brightness.dark;
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? SpaceColors.midnightRaised : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
