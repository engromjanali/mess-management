import 'package:clean_boilerplate/core/assets/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/theme/custom_theme_colors.dart';

/// Light theme data configuration
ThemeData lightThemeData = ThemeData(
  fontFamily: FontFamily.sFProRounded,
  useMaterial3: true,
  brightness: Brightness.light,

  // Color scheme
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF1FA463),
    primary: const Color(0xFF1FA463),
    secondary: const Color(0xFF4CAF50),
    error: const Color(0xFFE53935),
    surface: const Color(0xFFFFFFFF),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onError: Colors.white,
    onSurface: const Color(0xFF212121),
  ),

  // Scaffold
  scaffoldBackgroundColor: const Color(0xFFF5F5F5),

  // AppBar
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 0,
    backgroundColor: Color(0xFFFFFFFF),
    foregroundColor: Color(0xFF212121),
    surfaceTintColor: Colors.transparent,
    iconTheme: IconThemeData(color: Color(0xFF212121)),
    shape: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
  ),

  // Card
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Colors.white,
  ),

  // Elevated Button
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF1FA463),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
    ),
  ),

  // Text Button
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFF1FA463), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
  ),

  // Outlined Button
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF1FA463),
      side: const BorderSide(color: Color(0xFF1FA463)),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),

  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF1FA463), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE53935)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  ),

  // Divider
  dividerColor: const Color(0xFFBDBDBD),

  // Icon
  iconTheme: const IconThemeData(color: Color(0xFF757575)),

  // Custom theme extension
  extensions: <ThemeExtension<CustomThemeColors>>[CustomThemeColors.light()],
);
