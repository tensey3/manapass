import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const primary = Color(0xFF3B9BFF);
  static const primaryGlow = Color(0x593B9BFF);
  static const success = Color(0xFF3CBE4B);
  static const track = Color(0xFFE3E6EE);
  static const textStrong = Color(0xFF1F2A44);
  static const textMuted = Color(0xFF8A93A6);
  static const menuSelectedBg = Color(0xFFE8F2FF);
  static const menuSelectedBorder = Color(0xFFA8D0FF);
  static const menuSelectedText = Color(0xFF1E6BC4);
  static const cardShadow = Color(0x14000000);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      scaffoldBackgroundColor: Colors.white,
    );
    return base.copyWith(
      textTheme: GoogleFonts.zenMaruGothicTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textStrong,
        displayColor: AppColors.textStrong,
      ),
    );
  }
}
