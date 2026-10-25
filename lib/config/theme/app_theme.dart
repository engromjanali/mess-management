import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/theme/light_theme_data.dart';
import 'package:clean_boilerplate/config/theme/dark_theme_data.dart';

/// App theme configuration with singleton pattern
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  /// Light theme data
  static ThemeData get light => lightThemeData;

  /// Dark theme data
  static ThemeData get dark => darkThemeData;
}
