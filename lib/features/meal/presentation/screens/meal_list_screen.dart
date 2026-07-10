import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_admin_panel.dart';

class MealListScreen extends StatelessWidget {
  const MealListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: const Text('Meal list')),
      body: showWebAppBar
          ? Builder(
              builder: (context) => Column(
                children: [
                  DashboardTopBar(
                    userName: user?.name ?? 'User',
                    onProfileTap: () => Scaffold.of(context).openEndDrawer(),
                    navItems: [
                      DashboardNavItem(label: 'Home', icon: Icons.home_rounded, onTap: () => context.go(AppRoutes.home)),
                      DashboardNavItem(label: 'Meals', icon: Icons.restaurant_rounded, active: true, onTap: () => context.go(AppRoutes.meals)),
                      DashboardNavItem(label: 'Deposits', icon: Icons.account_balance_wallet_rounded, onTap: () => context.go(AppRoutes.deposits)),
                      DashboardNavItem(label: 'Cost', icon: Icons.shopping_cart_rounded, onTap: () => context.go(AppRoutes.costs)),
                    ],
                  ),
                  const Expanded(child: _MealListBody()),
                ],
              ),
            )
          : const _MealListBody(),
    );
  }
}

class _MealListBody extends StatelessWidget {
  const _MealListBody();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MealAdminPanel(showViewAll: false),
                    SizedBox(height: context.bottomPadding),
                  ],
                ),
              ),
            ),
          ),
          if (ResponsiveHelper.isDesktop(context)) const AppFooter(),
        ],
      ),
    );
  }
}
