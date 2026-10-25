import 'package:clean_boilerplate/core/assets/fonts.gen.dart';
import 'package:flutter/material.dart';

/// Reusable text styles for consistent typography using SF Pro Rounded

/// Reusable text styles for consistent typography
class AppTextStyles {
  AppTextStyles._();

  static const sfProRoundedRegular = TextStyle(fontFamily: FontFamily.sFProRounded, fontWeight: regular);

  static const sfProRoundedMedium = TextStyle(fontFamily: FontFamily.sFProRounded, fontWeight: medium);

  static const sfProRoundedSemiBold = TextStyle(fontFamily: FontFamily.sFProRounded, fontWeight: semiBold);

  static const sfProRoundedBold = TextStyle(fontFamily: FontFamily.sFProRounded, fontWeight: bold);

  // Font weights (for convenience)
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
}
