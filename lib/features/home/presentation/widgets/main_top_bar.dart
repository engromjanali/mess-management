import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_top_bar.dart';

/// The main sections in the desktop app bar.
enum MainSection { home, meals, deposits, cost }

/// Desktop / big-tablet app bar with the main sections, for screens that use
/// the shared layout. [active] marks the current section; screens outside the
/// main sections (e.g. Mess, Membership) leave it null and add a
/// `WebPageTitleBar` below. Must sit below the `Scaffold` (it opens the end
/// drawer) — use it inside the body.
class MainTopBar extends StatelessWidget {
  const MainTopBar({this.active, super.key});

  final MainSection? active;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    return DashboardTopBar(
      userName: user?.name ?? context.local.roleUser,
      onProfileTap: () => Scaffold.of(context).openEndDrawer(),
      navItems: [
        DashboardNavItem(label: context.local.home, icon: Icons.home_rounded, active: active == MainSection.home, onTap: () => context.go(AppRoutes.home)),
        DashboardNavItem(label: context.local.meals, icon: Icons.restaurant_rounded, active: active == MainSection.meals, onTap: () => context.go(AppRoutes.meals)),
        DashboardNavItem(label: context.local.deposits, icon: Icons.account_balance_wallet_rounded, active: active == MainSection.deposits, onTap: () => context.go(AppRoutes.deposits)),
        DashboardNavItem(label: context.local.cost, icon: Icons.shopping_cart_rounded, active: active == MainSection.cost, onTap: () => context.go(AppRoutes.costs)),
      ],
    );
  }
}
