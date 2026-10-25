import 'package:flutter/material.dart';

import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/screen_matres_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/core/widgets/home_back_button.dart';

import 'package:mess_pilot/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/meal/presentation/widgets/meal_admin_panel.dart';

class MealListScreen extends StatelessWidget {
  const MealListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.uiMealList)),
      body: showWebAppBar
          ? Column(
              children: const [
                DashboardTopBar(active: DashboardSection.meals),
                Expanded(child: _MealListBody()),
              ],
            )
          : const _MealListBody(),
    );
  }
}

class _MealListBody extends StatelessWidget {
  const _MealListBody();

  @override
  Widget build(BuildContext context) {
    return AppPageScrollView(
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
        ],
      ),
    );
  }
}
