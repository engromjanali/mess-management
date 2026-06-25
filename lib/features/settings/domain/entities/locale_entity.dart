import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/app_constants.dart';


/// Supported locales in the application
/// 
/// This class dynamically builds supported locales from AppConstants.languages,
/// making it easy for clients to add new languages without modifying this file.
class AppLocale {
  /// Get all supported locales from AppConstants
  static List<Locale> get supportedLocales {
    return AppConstants.languages
        .map((language) => Locale(language.code))
        .toList();
  }

  /// Get locale from language code
  static Locale fromCode(String code) {
    // Check if the code exists in our languages list
    final languageExists = AppConstants.languages
        .any((language) => language.code == code);
    
    if (languageExists) {
      return Locale(code);
    }
    
    // Default to first language in the list
    return Locale(AppConstants.languages.first.code);
  }

  /// Get language name from locate (returns native name)
  static String getLanguageName(Locale locale) {
    try {
      final language = AppConstants.languages
          .firstWhere((lang) => lang.code == locale.languageCode);
      return language.nativeName;
    } catch (_) {
      // If not found, return English
      return 'English';
    }
  }

}
