import 'package:flutter/material.dart';

/// Screen size extension on BuildContext
extension ScreenMatressExtensions on BuildContext {
  /// Get MediaQuery data
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => mediaQuery.size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Get status bar height
  double get statusBarHeight => mediaQuery.padding.top;

  /// Get bottom padding (safe area)
  double get bottomPadding => mediaQuery.padding.bottom;

  /// Get keyboard height
  double get keyboardHeight => mediaQuery.viewInsets.bottom;

  /// Check if keyboard is open
  bool get isKeyboardOpen => keyboardHeight > 0;

  /// Device orientation
  Orientation get orientation => mediaQuery.orientation;

  /// Check if device is in portrait mode
  bool get isPortrait => orientation == Orientation.portrait;

  /// Check if device is in landscape mode
  bool get isLandscape => orientation == Orientation.landscape;

  /// Device pixel ratio
  double get devicePixelRatio => mediaQuery.devicePixelRatio;
}
