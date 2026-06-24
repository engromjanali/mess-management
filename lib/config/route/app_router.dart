import 'package:clean_boilerplate/features/splash/presentation/screens/splash_screeen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/cost/presentation/screens/cost_screen.dart';
import '../../features/deposit/presentation/screens/deposit_screen.dart';
import '../../features/fund/presentation/screens/fund_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/meal/presentation/screens/meal_entry_screen.dart';
import '../../features/meal/presentation/screens/meal_screen.dart';
import '../../features/notice/presentation/screens/notice_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// App route constants
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();
  
  // Authentication routes
  static const String _splash = '/splash';
  static const String _login = '/login';
  static const String register = '/register';
  
  // Main routes
  static const String home = '/';
  static const String meals = '/meals';
  static const String addMeal = '/meals/add';
  static const String deposits = '/deposits';
  static const String funds = '/funds';
  static const String costs = '/costs';
  static const String notices = '/notices';
  static const String _profile = '/profile';
  static const String settings = '/settings';
  
  // Helper methods for parameterized routes
  static String getProfileRoute({required String userId}) => '$_profile?userId=$userId';

  static String getSplashRoute() => _splash;

  static String getLoginRoute() => _login;
}

/// Router configuration using go_router
final router = GoRouter(
  initialLocation: AppRoutes._splash,
  routes: [

    GoRoute(
      path: AppRoutes._splash,
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Authentication routes
    GoRoute(
      path: AppRoutes._login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: AppRoutes.register,
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // Home route
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    
    // Meal route
    GoRoute(
      path: AppRoutes.meals,
      name: 'meals',
      builder: (context, state) => const MealScreen(),
    ),

    // Admin: add meal for all members
    GoRoute(
      path: AppRoutes.addMeal,
      name: 'addMeal',
      builder: (context, state) => const MealEntryScreen(),
    ),

    // Deposit route (role-aware: admin manages, user views own list)
    GoRoute(
      path: AppRoutes.deposits,
      name: 'deposits',
      builder: (context, state) => const DepositScreen(),
    ),

    // Fund route (role-aware: admin manages, user views the list)
    GoRoute(
      path: AppRoutes.funds,
      name: 'funds',
      builder: (context, state) => const FundScreen(),
    ),

    // Cost / bazar route (role-aware: admin manages, user views the list)
    GoRoute(
      path: AppRoutes.costs,
      name: 'costs',
      builder: (context, state) => const CostScreen(),
    ),

    // Notice route (role-aware: admin manages, user views the list)
    GoRoute(
      path: AppRoutes.notices,
      name: 'notices',
      builder: (context, state) => const NoticeScreen(),
    ),

    // Settings route
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    
    // Add more routes as your app grows
  ],
  
  // Error handling
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.matchedLocation}'),
    ),
  ),
);
