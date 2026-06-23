import 'package:clean_boilerplate/features/splash/presentation/screens/splash_screeen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/meal/presentation/screens/meal_screen.dart';
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
