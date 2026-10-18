/// Theme mode options for the app
enum AppThemeMode {
  /// Light theme
  light,

  /// Dark theme
  dark,

  /// System theme
  system,
}

/// Extension methods for AppThemeMode
extension AppThemeModeExtension on AppThemeMode {
  /// Next mode used by the theme action button: light → dark → system.
  AppThemeMode get next {
    switch (this) {
      case AppThemeMode.light:
        return AppThemeMode.dark;
      case AppThemeMode.dark:
        return AppThemeMode.system;
      case AppThemeMode.system:
        return AppThemeMode.light;
    }
  }

  /// Convert enum to string for storage
  String toStringValue() {
    switch (this) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.system:
        return 'system';
    }
  }

  /// Get display name for UI
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

/// Extension to convert string to AppThemeMode
extension StringToAppThemeMode on String {
  /// Parse string to AppThemeMode
  AppThemeMode toAppThemeMode() {
    switch (toLowerCase()) {
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
        return AppThemeMode.system;
      case 'light':
      default:
        return AppThemeMode.light;
    }
  }
}
