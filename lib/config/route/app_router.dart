import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/features/splash/presentation/screens/maintenance_screen.dart';
import 'package:mess_pilot/features/splash/presentation/screens/splash_screeen.dart';
import 'package:mess_pilot/features/splash/presentation/screens/update_required_screen.dart';
import 'package:mess_pilot/features/app_info/domain/entities/content_page_entity.dart';
import 'package:mess_pilot/features/app_info/presentation/screens/content_page_screen.dart';
import 'package:mess_pilot/features/app_info/presentation/screens/faq_screen.dart';
import 'package:mess_pilot/features/app_info/presentation/screens/support_screen.dart';
import 'package:mess_pilot/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mess_pilot/features/auth/presentation/screens/login_screen.dart';
import 'package:mess_pilot/features/auth/presentation/screens/edit_profile_screen.dart';
import 'package:mess_pilot/features/auth/presentation/screens/profile_screen.dart';
import 'package:mess_pilot/features/auth/presentation/screens/register_screen.dart';
import 'package:mess_pilot/features/cost/presentation/screens/cost_screen.dart';
import 'package:mess_pilot/features/deposit/presentation/screens/deposit_screen.dart';
import 'package:mess_pilot/features/fund/presentation/screens/fund_screen.dart';
import 'package:mess_pilot/features/home/presentation/screens/home_screen.dart';
import 'package:mess_pilot/features/meal/presentation/screens/meal_entry_screen.dart';
import 'package:mess_pilot/features/meal/presentation/screens/meal_list_screen.dart';
import 'package:mess_pilot/features/meal/presentation/screens/meal_screen.dart';
import 'package:mess_pilot/features/membership/presentation/screens/manage_membership_screen.dart';
import 'package:mess_pilot/features/membership/presentation/screens/join_mess_screen.dart';
import 'package:mess_pilot/features/membership/presentation/screens/mess_details_screen.dart';
import 'package:mess_pilot/features/membership/presentation/screens/edit_mess_screen.dart';
import 'package:mess_pilot/features/membership/presentation/screens/mess_leadership_screen.dart';
import 'package:mess_pilot/features/notice/presentation/screens/notice_screen.dart';
import 'package:mess_pilot/features/notice/presentation/screens/notice_details_screen.dart';
import 'package:mess_pilot/features/notice/domain/entities/notice_entity.dart';
import 'package:mess_pilot/features/opinion/presentation/screens/opinion_screen.dart';
import 'package:mess_pilot/features/season/presentation/screens/season_management_screen.dart';
import 'package:mess_pilot/features/settings/presentation/screens/settings_screen.dart';
import 'package:mess_pilot/core/widgets/main_navigation_shell.dart';

/// App route constants
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // Authentication routes
  static const String _splash = '/splash';
  static const String _login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // App gate (from the admin's app config)
  static const String maintenance = '/maintenance';
  static const String updateRequired = '/update-required';

  // Main routes
  static const String home = '/';
  static const String meals = '/meals';
  static const String addMeal = '/meals/add';
  static const String mealList = '/meals/list';
  static const String deposits = '/deposits';
  static const String funds = '/funds';
  static const String costs = '/costs';
  static const String notices = '/notices';
  static const String noticeDetails = '/notices/:id';
  static String getNoticeDetailsRoute(String id) => '$notices/${Uri.encodeComponent(id)}';

  static const String opinions = '/opinions';
  static const String createOpinionPeriod = '/opinions/create';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String deleteAccount = '/account/delete';
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsAndConditions = '/terms-and-conditions';
  static const String faq = '/faq';
  static const String support = '/support';
  static const String manageMembership = '/membership/manage';
  static const String joinMess = '/mess/join';
  static const String joinMessInvites = '/mess/join/invites';
  static const String joinMessRequests = '/mess/join/requests';
  static const String createMess = '/mess/join/create';
  static const String messDetails = '/mess';
  static const String editMess = '/mess/edit';
  static const String messLeadership = '/mess/leadership';
  static const String seasons = '/seasons';

  // Helper methods for parameterized routes
  static String getProfileRoute({required String userId}) => '$profile?userId=$userId';

  static String getSplashRoute() => _splash;

  static String getLoginRoute() => _login;

  static String getHomeRoute() => home;

  static String loginRouteFor(String destination) {
    final resolvedDestination = startupRoute(destination);
    if (resolvedDestination == home) return _login;
    return Uri(path: _login, queryParameters: {'redirect': resolvedDestination}).toString();
  }

  static String startupRoute(String destination) {
    final uri = Uri.tryParse(destination);
    if (uri == null || uri.hasScheme || uri.hasAuthority || !uri.path.startsWith('/') || uri.path.startsWith('//')) return home;
    const startupRoutes = [_splash, _login, register, forgotPassword, maintenance, updateRequired];
    if (startupRoutes.contains(uri.path)) return home;
    return uri.toString();
  }
}

String initialDestination = _initialDestination();

String _initialDestination() {
  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.fragment.startsWith('/')) return uri.fragment;
    return uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
  }
  return PlatformDispatcher.instance.defaultRouteName;
}

/// Router configuration using go_router
final router = GoRouter(
  initialLocation: AppRoutes._splash,
  overridePlatformDefaultLocation: true,
  // On web, route focus before the first layout triggers view focus traversal on an unlaid Overlay.
  requestFocus: !kIsWeb,
  routes: [
    GoRoute(path: AppRoutes._splash, name: 'splash', builder: (context, state) => SplashScreen(destination: initialDestination)),

    // App gate: maintenance mode / forced update
    GoRoute(path: AppRoutes.maintenance, name: 'maintenance', builder: (context, state) => const MaintenanceScreen()),
    GoRoute(path: AppRoutes.updateRequired, name: 'updateRequired', builder: (context, state) => const UpdateRequiredScreen()),

    // Authentication routes
    GoRoute(path: AppRoutes._login, name: 'login', builder: (context, state) => const LoginScreen()),

    GoRoute(path: AppRoutes.register, name: 'register', builder: (context, state) => const RegisterScreen()),

    GoRoute(path: AppRoutes.forgotPassword, name: 'forgotPassword', builder: (context, state) => const ForgotPasswordScreen()),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainNavigationShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, name: 'home', builder: (context, state) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: AppRoutes.meals, name: 'meals', builder: (context, state) => const MealScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: AppRoutes.deposits, name: 'deposits', builder: (context, state) => const DepositScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: AppRoutes.costs, name: 'costs', builder: (context, state) => const CostScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: AppRoutes.profile, name: 'profile', builder: (context, state) => const ProfileScreen())]),
      ],
    ),

    // Admin: add meal for all members
    GoRoute(path: AppRoutes.addMeal, name: 'addMeal', builder: (context, state) => const MealEntryScreen()),

    GoRoute(path: AppRoutes.mealList, name: 'mealList', builder: (context, state) => const MealListScreen()),

    // Fund route (role-aware: admin manages, user views the list)
    GoRoute(path: AppRoutes.funds, name: 'funds', builder: (context, state) => const FundScreen()),

    // Notice route (role-aware: admin manages, user views the list)
    GoRoute(path: AppRoutes.notices, name: 'notices', builder: (context, state) => const NoticeScreen(), routes: [
      GoRoute(path: ':id', name: 'noticeDetails', builder: (context, state) => NoticeDetailsScreen(noticeId: state.pathParameters['id'], notice: state.extra is NoticeEntity ? state.extra as NoticeEntity : null)),
    ]),

    GoRoute(path: AppRoutes.opinions, name: 'opinions', pageBuilder: (context, state) => const NoTransitionPage(key: ValueKey('opinions-page'), child: OpinionScreen())),
    GoRoute(path: AppRoutes.createOpinionPeriod, name: 'createOpinionPeriod', pageBuilder: (context, state) => const NoTransitionPage(key: ValueKey('opinions-page'), child: OpinionScreen(showCreateTab: true))),

    // Profile route
    GoRoute(path: AppRoutes.editProfile, name: 'editProfile', builder: (context, state) => const EditProfileScreen()),
    GoRoute(path: AppRoutes.deleteAccount, name: 'deleteAccount', builder: (context, state) => const DeleteAccountScreen()),

    // Settings route
    GoRoute(path: AppRoutes.settings, name: 'settings', builder: (context, state) => const SettingsScreen()),

    // App info (content from Django admin)
    GoRoute(path: AppRoutes.privacyPolicy, name: 'privacyPolicy', builder: (context, state) => const ContentPageScreen(kind: ContentKind.privacyPolicy)),
    GoRoute(path: AppRoutes.termsAndConditions, name: 'termsAndConditions', builder: (context, state) => const ContentPageScreen(kind: ContentKind.termsAndConditions)),
    GoRoute(path: AppRoutes.faq, name: 'faq', builder: (context, state) => const FaqScreen()),
    GoRoute(path: AppRoutes.support, name: 'support', builder: (context, state) => const SupportScreen()),

    GoRoute(path: AppRoutes.manageMembership, name: 'manageMembership', builder: (context, state) => const ManageMembershipScreen()),

    GoRoute(path: AppRoutes.joinMess, name: 'joinMess', builder: (context, state) => const JoinMessScreen()),

    GoRoute(path: AppRoutes.joinMessInvites, name: 'joinMessInvites', builder: (context, state) => const JoinMessScreen()),

    GoRoute(path: AppRoutes.joinMessRequests, name: 'joinMessRequests', builder: (context, state) => const JoinMessScreen()),

    GoRoute(path: AppRoutes.createMess, name: 'createMess', builder: (context, state) => const JoinMessScreen()),

    GoRoute(path: AppRoutes.messDetails, name: 'messDetails', builder: (context, state) => const MessDetailsScreen()),

    GoRoute(path: AppRoutes.editMess, name: 'editMess', builder: (context, state) => const EditMessScreen()),

    GoRoute(path: AppRoutes.messLeadership, name: 'messLeadership', builder: (context, state) => const MessLeadershipScreen()),

    // Season management (admin: start, end, delete seasons)
    GoRoute(path: AppRoutes.seasons, name: 'seasons', builder: (context, state) => const SeasonManagementScreen()),

    // Add more routes as your app grows
  ],

  // Error handling
  errorBuilder: (context, state) => Scaffold(body: Center(child: Text(context.local.uiPageNotFound(state.matchedLocation)))),
);
