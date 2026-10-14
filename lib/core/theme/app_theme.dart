import 'package:flutter/material.dart';

/// Hệ thống Design Tokens và Theme Fintech UI/UX Pro Max cho BudgetMate.
/// Tối ưu độ tương phản, nền tối sâu (Deep Midnight) và hiển thị số liệu tài chính rõ nét.
class AppTheme {
  AppTheme._();

  // ── Palette Màu Cốt Lõi FinTech Emerald & Dark Charcoal ──
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF262626);
  static const Color darkBorder = Color(0xFF2E2E2E);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Brand & Action Colors
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryGreenDark = Color(0xFF059669);
  static const Color successGreen = Color(0xFF10B981);
  static const Color incomeGreen = Color(0xFF34D399);
  static const Color expenseRed = Color(0xFFF87171);
  static const Color dangerRed = expenseRed;
  static const Color primaryBlue = primaryGreen; // Tương thích ngược
  static const Color primaryBlueDark = primaryGreenDark;
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color purpleAccent = Color(0xFF8B5CF6);

  static const Color textMutedDark = Color(0xFF8E8E93);
  static const Color textMutedLight = Color(0xFF64748B);

  // ── Dark Theme (Mặc định) ──
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: incomeGreen,
      surface: darkSurface,
      error: expenseRed,
      onPrimary: Colors.white,
      onSurface: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceVariant,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: const BorderSide(color: darkBorder),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkSurface,
      modalBackgroundColor: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );

  // ── Light Theme ──
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: primaryBlueDark,
      secondary: successGreen,
      surface: lightSurface,
      error: dangerRed,
      onPrimary: Colors.white,
      onSurface: Color(0xFF0F172A),
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
        letterSpacing: -0.5,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryBlueDark,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),
  );
}
