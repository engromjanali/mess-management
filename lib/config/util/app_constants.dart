import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:clean_boilerplate/features/settings/domain/entities/language_model.dart';

/// Application-level constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Clean Boilerplate';
  static const String appVersion = '1.0.0';

  static const int _port = 8000;
  static String get baseUrl {
    const override = String.fromEnvironment('BASE_URL');
    if (override.isNotEmpty) return override;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:$_port';
    return 'http://localhost:$_port';
  }

  // API endpoints
  static const String configEndPoint = '/api/v1/config';

  // auth 
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String logoutEndpoint = '/api/auth/logout';
  static const String refreshTokenEndpoint = '/api/auth/refresh';
  static const String profileEndpoint = '/api/auth/me';
  static const String forgotPasswordEndpoint = '/api/auth/forgot-password';
  static const String resetPasswordEndpoint = '/api/auth/reset-password';

  // membership
  static const String membershipStatusEndpoint = '/api/v1/membership/status';
  static const String joinInviteEndpoint = '/api/v1/membership/join-invite';
  static const String joinRequestEndpoint = '/api/v1/membership/join-request';
  static const String leaveMessEndpoint = '/api/v1/membership/leave';
  static const String availableMessesEndpoint = '/api/v1/messes';
  static const String createMessEndpoint = '/api/v1/membership/create-mess';
  static const String createInviteEndpoint = '/api/v1/membership/invites';
  static const String managerJoinRequestsEndpoint = '/api/v1/membership/requests';
  static const String joinRequestDecisionEndpoint = '/api/v1/membership/requests/decision';
  static const String memberLookupEndpoint = '/api/v1/membership/member-lookup';
  static const String managerMembersEndpoint = '/api/v1/membership/members';
  static const String messDetailsEndpoint = '/api/v1/membership/mess';
  static const String messLeadershipEndpoint = '/api/v1/membership/mess/leadership';
  static const String mealAdminDataEndpoint = '/api/v1/meals/admin-data';
  static const String addMealBulkEndpoint = '/api/v1/meals/add-meal-bulk';
  static const String addMealEndpoint = '/api/v1/meals/add-meal';

  // keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
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
