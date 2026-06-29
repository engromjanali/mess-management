import 'package:flutter/material.dart';

/// Custom theme colors extension for additional color support
class CustomThemeColors extends ThemeExtension<CustomThemeColors> {
  // Primary colors
  final Color primaryColor;
  final Color primaryLightColor;
  final Color primaryDarkColor;
  final Color secondaryColor;

  // Background colors
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardBackgroundColor;

  // Text colors
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color textHintColor;

  // Status colors
  final Color successColor;
  final Color warningColor;
  final Color errorColor;
  final Color infoColor;

  // UI colors
  final Color borderColor;
  final Color dividerColor;
  final Color shadowColor;

  const CustomThemeColors({
    required this.primaryColor,
    required this.primaryLightColor,
    required this.primaryDarkColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardBackgroundColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.textHintColor,
    required this.successColor,
    required this.warningColor,
    required this.errorColor,
    required this.infoColor,
    required this.borderColor,
    required this.dividerColor,
    required this.shadowColor,
  });

  /// Light theme colors
  factory CustomThemeColors.light() => const CustomThemeColors(
    primaryColor: Color(0xFF1FA463),
    primaryLightColor: Color(0xFF5FD79A),
    primaryDarkColor: Color(0xFF0E6E3F),
    secondaryColor: Color(0xFFFFB300),
    backgroundColor: Color(0xFFF5F5F5),
    surfaceColor: Color(0xFFFFFFFF),
    cardBackgroundColor: Color(0xFFFFFFFF),
    textPrimaryColor: Color(0xFF212121),
    textSecondaryColor: Color(0xFF757575),
    textHintColor: Color(0xFFBDBDBD),
    successColor: Color(0xFF4CAF50),
    warningColor: Color(0xFFFFA726),
    errorColor: Color(0xFFE53935),
    infoColor: Color(0xFF2196F3),
    borderColor: Color(0xFFE0E0E0),
    dividerColor: Color(0xFFBDBDBD),
    shadowColor: Color(0x1A000000),
  );

  /// Dark theme colors
  factory CustomThemeColors.dark() => const CustomThemeColors(
    primaryColor: Color(0xFF35C57F),
    primaryLightColor: Color(0xFF6FE3A8),
    primaryDarkColor: Color(0xFF0E6E3F),
    secondaryColor: Color(0xFFFFC233),
    backgroundColor: Color(0xFF121212),
    surfaceColor: Color(0xFF1E1E1E),
    cardBackgroundColor: Color(0xFF2C2C2C),
    textPrimaryColor: Color(0xFFFFFFFF),
    textSecondaryColor: Color(0xFFB0B0B0),
    textHintColor: Color(0xFF757575),
    successColor: Color(0xFF66BB6A),
    warningColor: Color(0xFFFFB74D),
    errorColor: Color(0xFFEF5350),
    infoColor: Color(0xFF42A5F5),
    borderColor: Color(0xFF424242),
    dividerColor: Color(0xFF616161),
    shadowColor: Color(0x3A000000),
  );

  @override
  CustomThemeColors copyWith({
    Color? primaryColor,
    Color? primaryLightColor,
    Color? primaryDarkColor,
    Color? secondaryColor,
    Color? backgroundColor,
    Color? surfaceColor,
    Color? cardBackgroundColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    Color? textHintColor,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
    Color? infoColor,
    Color? borderColor,
    Color? dividerColor,
    Color? shadowColor,
  }) {
    return CustomThemeColors(
      primaryColor: primaryColor ?? this.primaryColor,
      primaryLightColor: primaryLightColor ?? this.primaryLightColor,
      primaryDarkColor: primaryDarkColor ?? this.primaryDarkColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardBackgroundColor: cardBackgroundColor ?? this.cardBackgroundColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      textHintColor: textHintColor ?? this.textHintColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColor: errorColor ?? this.errorColor,
      infoColor: infoColor ?? this.infoColor,
      borderColor: borderColor ?? this.borderColor,
      dividerColor: dividerColor ?? this.dividerColor,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  CustomThemeColors lerp(ThemeExtension<CustomThemeColors>? other, double t) {
    if (other is! CustomThemeColors) return this;

    return CustomThemeColors(
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      primaryLightColor: Color.lerp(primaryLightColor, other.primaryLightColor, t)!,
      primaryDarkColor: Color.lerp(primaryDarkColor, other.primaryDarkColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      cardBackgroundColor: Color.lerp(cardBackgroundColor, other.cardBackgroundColor, t)!,
      textPrimaryColor: Color.lerp(textPrimaryColor, other.textPrimaryColor, t)!,
      textSecondaryColor: Color.lerp(textSecondaryColor, other.textSecondaryColor, t)!,
      textHintColor: Color.lerp(textHintColor, other.textHintColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t)!,
    );
  }
}
