import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/widgets/animated_bottom_nav_bar.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MainNavigationShell extends StatelessWidget {
  const MainNavigationShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) return child;

    const routes = [AppRoutes.home, AppRoutes.meals, AppRoutes.deposits, AppRoutes.costs, AppRoutes.profile];
    final currentIndex = routes.indexOf(location);
    final photoUrl = context.select<AuthBloc, String?>((bloc) => bloc.state.maybeWhen(authenticated: (user) => user.photoUrl, orElse: () => null));

    void navigate(int index) {
      if (index != currentIndex) context.go(routes[index]);
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : Align(
              heightFactor: 1,
              child: AnimatedBottomNavBar(
                currentIndex: currentIndex,
                visible: true,
                items: [
                  BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: context.local.home, onTap: () => navigate(0)),
                  BottomNavItem(icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant_rounded, label: context.local.meals, onTap: () => navigate(1)),
                  BottomNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded, label: context.local.deposits, onTap: () => navigate(2)),
                  BottomNavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: context.local.cost, onTap: () => navigate(3)),
                  BottomNavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: context.local.profile, profileImageUrl: photoUrl ?? '', onTap: () => navigate(4)),
                ],
              ),
            ),
    );
  }
}
