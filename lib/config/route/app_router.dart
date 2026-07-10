import 'package:clean_boilerplate/features/splash/presentation/screens/splash_screeen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:clean_boilerplate/features/auth/presentation/screens/login_screen.dart';
import 'package:clean_boilerplate/features/auth/presentation/screens/profile_screen.dart';
import 'package:clean_boilerplate/features/auth/presentation/screens/register_screen.dart';
import 'package:clean_boilerplate/features/cost/presentation/screens/cost_screen.dart';
import 'package:clean_boilerplate/features/deposit/presentation/screens/deposit_screen.dart';
import 'package:clean_boilerplate/features/fund/presentation/screens/fund_screen.dart';
import 'package:clean_boilerplate/features/home/presentation/screens/home_screen.dart';
import 'package:clean_boilerplate/features/meal/presentation/screens/meal_entry_screen.dart';
import 'package:clean_boilerplate/features/meal/presentation/screens/meal_list_screen.dart';
import 'package:clean_boilerplate/features/meal/presentation/screens/meal_screen.dart';
import 'package:clean_boilerplate/features/membership/presentation/screens/manage_membership_screen.dart';
import 'package:clean_boilerplate/features/membership/presentation/screens/join_mess_screen.dart';
import 'package:clean_boilerplate/features/membership/presentation/screens/mess_details_screen.dart';
import 'package:clean_boilerplate/features/membership/presentation/screens/edit_mess_screen.dart';
import 'package:clean_boilerplate/features/membership/presentation/screens/mess_leadership_screen.dart';
import 'package:clean_boilerplate/features/notice/presentation/screens/notice_screen.dart';
import 'package:clean_boilerplate/features/opinion/presentation/screens/opinion_screen.dart';
import 'package:clean_boilerplate/features/settings/presentation/screens/settings_screen.dart';

/// App route constants
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  // Authentication routes
  static const String _splash = '/splash';
  static const String _login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main routes
  static const String home = '/';
  static const String meals = '/meals';
  static const String addMeal = '/meals/add';
  static const String mealList = '/meals/list';
  static const String deposits = '/deposits';
  static const String funds = '/funds';
  static const String costs = '/costs';
  static const String notices = '/notices';
  static const String opinions = '/opinions';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String manageMembership = '/membership/manage';
  static const String joinMess = '/mess/join';
  static const String joinMessInvites = '/mess/join/invites';
  static const String joinMessRequests = '/mess/join/requests';
  static const String createMess = '/mess/join/create';
  static const String messDetails = '/mess';
  static const String editMess = '/mess/edit';
  static const String messLeadership = '/mess/leadership';

  // Helper methods for parameterized routes
  static String getProfileRoute({required String userId}) => '$profile?userId=$userId';

  static String getSplashRoute() => _splash;

  static String getLoginRoute() => _login;

  static String getHomeRoute() => home;
}

/// Router configuration using go_router
final router = GoRouter(
  initialLocation: AppRoutes._splash,
  routes: [
    GoRoute(path: AppRoutes._splash, name: 'splash', builder: (context, state) => const SplashScreen()),

    // Authentication routes
    GoRoute(path: AppRoutes._login, name: 'login', builder: (context, state) => const LoginScreen()),

    GoRoute(path: AppRoutes.register, name: 'register', builder: (context, state) => const RegisterScreen()),

    GoRoute(path: AppRoutes.forgotPassword, name: 'forgotPassword', builder: (context, state) => const ForgotPasswordScreen()),

    // Home route
    GoRoute(path: AppRoutes.home, name: 'home', builder: (context, state) => const HomeScreen()),

    // Meal route
    GoRoute(path: AppRoutes.meals, name: 'meals', builder: (context, state) => const MealScreen()),

    // Admin: add meal for all members
    GoRoute(path: AppRoutes.addMeal, name: 'addMeal', builder: (context, state) => const MealEntryScreen()),

    GoRoute(path: AppRoutes.mealList, name: 'mealList', builder: (context, state) => const MealListScreen()),

    // Deposit route (role-aware: admin manages, user views own list)
    GoRoute(path: AppRoutes.deposits, name: 'deposits', builder: (context, state) => const DepositScreen()),

    // Fund route (role-aware: admin manages, user views the list)
    GoRoute(path: AppRoutes.funds, name: 'funds', builder: (context, state) => const FundScreen()),

    // Cost / Cost route (role-aware: admin manages, user views the list)
    GoRoute(path: AppRoutes.costs, name: 'costs', builder: (context, state) => const CostScreen()),

    // Notice route (role-aware: admin manages, user views the list)
    GoRoute(path: AppRoutes.notices, name: 'notices', builder: (context, state) => const NoticeScreen()),

    GoRoute(path: AppRoutes.opinions, name: 'opinions', builder: (context, state) => const OpinionScreen()),

    // Profile route
    GoRoute(path: AppRoutes.profile, name: 'profile', builder: (context, state) => const ProfileScreen()),

    // Settings route
    GoRoute(path: AppRoutes.settings, name: 'settings', builder: (context, state) => const SettingsScreen()),

    GoRoute(path: AppRoutes.manageMembership, name: 'manageMembership', builder: (context, state) => const ManageMembershipScreen()),

    GoRoute(path: AppRoutes.joinMess, name: 'joinMess', builder: (context, state) => const JoinMessScreen()),

    GoRoute(path: AppRoutes.joinMessInvites, name: 'joinMessInvites', builder: (context, state) => const JoinMessScreen()),

    GoRoute(path: AppRoutes.joinMessRequests, name: 'joinMessRequests', builder: (context, state) => const JoinMessScreen()),

    GoRoute(path: AppRoutes.createMess, name: 'createMess', builder: (context, state) => const JoinMessScreen()),

    GoRoute(path: AppRoutes.messDetails, name: 'messDetails', builder: (context, state) => const MessDetailsScreen()),

    GoRoute(path: AppRoutes.editMess, name: 'editMess', builder: (context, state) => const EditMessScreen()),

    GoRoute(path: AppRoutes.messLeadership, name: 'messLeadership', builder: (context, state) => const MessLeadershipScreen()),

    // Add more routes as your app grows
  ],

  // Error handling
  errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Page not found: ${state.matchedLocation}'))),
);
