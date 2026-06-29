/// String extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Convert string to int safely
  int? get toIntOrNull => int.tryParse(this);

  /// Convert string to double safely
  double? get toDoubleOrNull => double.tryParse(this);

  /// Validate email
  bool get isValidEmail {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(this);
  }

  /// Validate phone number (basic)
  bool get isValidPhone {
    final phoneRegExp = RegExp(r'^\+?[\d\s-]{10,}$');
    return phoneRegExp.hasMatch(this);
  }
}
