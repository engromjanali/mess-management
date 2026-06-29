import 'package:clean_boilerplate/config/theme/custom_theme_colors.dart';
import 'package:clean_boilerplate/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Context extensions for common operations
extension ContextExtensions on BuildContext {
  /// Theme
  ThemeData get theme => Theme.of(this);

  CustomThemeColors get customThemeColors => theme.extension<CustomThemeColors>()!;

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colorScheme => theme.colorScheme;

  /// Primary color
  Color get primaryColor => colorScheme.primary;

  /// Secondary color
  Color get secondaryColor => colorScheme.secondary;

  /// Background color
  Color get backgroundColor => colorScheme.surface;

  /// Error color
  Color get errorColor => colorScheme.error;

  /// Check if theme is dark
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// Localization
  AppLocalizations get local => AppLocalizations.of(this);
}
