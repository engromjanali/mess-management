import 'package:clean_boilerplate/features/settings/domain/entities/language_model.dart';

/// Application-level constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Clean Boilerplate';
  static const String appVersion = '1.0.0';

  // API constants (Update with your actual API URLs)
  static const String baseUrl = 'https://efood-admin.6amtech.com';

  // API endpoints
  static const String configEndPoint = '/api/v1/config';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String profileEndpoint = '/user/profile';

  static const String tokenKey = 'auth_token';
  static const String guestUserIdKey = 'guest_user_id';
  static const String languageCodeKey = 'language_code';

  // Pagination
  static const int paginationLimit = 20;
  static const int paginationLimitSmall = 10;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;

  // Timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;

  // Error messages
  static const String networkErrorMessage = 'Network error. Please check your connection.';
  static const String serverErrorMessage = 'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String validationErrorMessage = 'Please check your input and try again.';

  static final List<LanguageModel> languages = [
    LanguageModel(code: 'bn', name: 'Bangla', nativeName: 'বাংলা'),

    LanguageModel(code: 'en', name: 'English', nativeName: 'English'),

    LanguageModel(code: 'ar', name: 'Arabic', nativeName: 'العربية'),
  ];
}
