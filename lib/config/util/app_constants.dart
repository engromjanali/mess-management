import 'package:clean_boilerplate/features/settings/domain/entities/language_model.dart';

/// Application-level constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Clean Boilerplate';
  static const String appVersion = '1.0.0';

  static const String baseUrl = 'http://127.0.0.1:8000';
  // static const String baseUrl = 'https://mm-backend-kappa.vercel.app';

  // ───────────────────────── API endpoints ─────────────────────────
  // Grouped by feature; inside a feature, user (`/api/v1/user`) routes come
  // before manager (`/api/v1/admin`) routes.

  // Config
  static const String configEndPoint = '/api/v1/auth/config';
  static const String authTestEndpoint = '/api/v1/auth/test';

  // Auth
  static const String loginEndpoint = '/api/v1/auth/sign-in';
  static const String registerEndpoint = '/api/v1/auth/sign-up';
  static const String logoutEndpoint = '/api/v1/auth/logout';
  static const String refreshTokenEndpoint = '/api/auth/refresh';
  static const String profileEndpoint = '/api/v1/auth/update-profile';
  static const String forgotPasswordEndpoint = '/api/v1/auth/forgot-password';
  static const String forgetPasswordEndpoint = '/api/v1/auth/forget-password';
  static const String resetPasswordEndpoint = '/api/v1/auth/change-password';

  // Membership — user
  static const String membershipStatusEndpoint = '/api/v1/user/membership/status';
  static const String availableMessesEndpoint = '/api/v1/user/messes';
  static const String createMessEndpoint = '/api/v1/user/messes/create';
  static const String joinRequestEndpoint = '/api/v1/user/join-requests';
  static const String joinInviteEndpoint = '/api/v1/user/invites/accept';
  static const String leaveMessEndpoint = '/api/v1/user/membership/leave';

  // Membership — admin
  static const String managerMembersEndpoint = '/api/v1/admin/members';
  static const String memberLookupEndpoint = '/api/v1/admin/member-lookup';
  static const String createInviteEndpoint = '/api/v1/admin/invites';
  static const String managerJoinRequestsEndpoint = '/api/v1/admin/join-requests';
  static const String joinRequestDecisionEndpoint = '/api/v1/admin/join-requests/decision';

  // Mess — admin (not on the backend yet)
  static const String messDetailsEndpoint = '/api/v1/membership/mess';
  static const String messLeadershipEndpoint = '/api/v1/membership/mess/leadership';

  // Meals
  static const String addMealEndpoint = '/api/v1/meals/add-meal';
  static const String addMealBulkEndpoint = '/api/v1/meals/add-meal-bulk';
  static const String mealAdminDataEndpoint = '/api/v1/meals/admin-data';

  // Deposits — user
  static const String myDepositsEndpoint = '/api/v1/user/deposits';

  // Deposits — admin
  static const String adminDepositsEndpoint = '/api/v1/admin/deposits';

  // ───────────────────────── Storage keys ─────────────────────────
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
