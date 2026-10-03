import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/core/widgets/stat_card.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_entity.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_bloc.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_event.dart';
import 'package:clean_boilerplate/features/meal/presentation/bloc/meal_state.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_admin_panel.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_formatters.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_history_list.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_today_card.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_week_chart.dart';

/// Responsive meal tracker screen (phone / tablet / desktop).
///
/// * **Members** — only their own meals ("Mine").
/// * **Admins** — a `Manage meals / Mine` switch: the manager can record meals
///   for any member and still see their own meals, since they eat too.
/// * **Tablet / desktop** — centered, capped content with a two-column body
///   (editor + chart on the left, history on the right) under a summary grid.
class MealScreen extends StatelessWidget {
  const MealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MealBloc>(create: (_) => getIt<MealBloc>()..add(const MealEvent.load()), child: const _MealView());
  }
}

enum _MealTab { manage, mine }

class _MealView extends StatefulWidget {
  const _MealView();

  @override
  State<_MealView> createState() => _MealViewState();
}

class _MealViewState extends State<_MealView> {
  _MealTab _tab = _MealTab.manage;

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    final isAdmin = context.watch<RoleCubit>().state.isAdmin;
    final content = isAdmin ? _adminContent() : const _MineTab();

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.meals)),
      body: showWebAppBar
          ? Column(
              children: [
                const _MealTopBar(),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  void _selectTab(_MealTab tab) {
    setState(() => _tab = tab);
    // Meals may have changed in Manage meals, so reload the manager's own.
    if (tab == _MealTab.mine) context.read<MealBloc>().add(const MealEvent.refresh());
  }

  /// Tab switch over both tabs; [IndexedStack] keeps each tab's scroll and
  /// filters when switching back and forth.
  Widget _adminContent() {
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, 0),
              child: _TabSwitch(tab: _tab, onChanged: _selectTab),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(index: _tab.index, children: const [_ManageTab(), _MineTab()]),
        ),
      ],
    );
  }
}

/// Desktop / big-tablet app bar, shown in every state (loading, error, loaded).
class _MealTopBar extends StatelessWidget {
  const _MealTopBar();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    return DashboardTopBar(
      userName: user?.name ?? context.local.roleUser,
      onProfileTap: () => Scaffold.of(context).openEndDrawer(),
      navItems: [
        DashboardNavItem(label: context.local.home, icon: Icons.home_rounded, onTap: () => context.go(AppRoutes.home)),
        DashboardNavItem(label: context.local.meals, icon: Icons.restaurant_rounded, active: true, onTap: () {}),
        DashboardNavItem(label: context.local.deposits, icon: Icons.account_balance_wallet_rounded, onTap: () => context.go(AppRoutes.deposits)),
        DashboardNavItem(label: context.local.cost, icon: Icons.shopping_cart_rounded, onTap: () => context.go(AppRoutes.costs)),
      ],
    );
  }
}

/// Segmented `Manage meals / Mine` switch (admins only).
class _TabSwitch extends StatelessWidget {
  const _TabSwitch({required this.tab, required this.onChanged});
  final _MealTab tab;
  final ValueChanged<_MealTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_MealTab>(
      segments: [
        ButtonSegment(
          value: _MealTab.manage,
          icon: const Icon(Icons.manage_accounts_rounded),
          label: Text(context.local.manageMeals, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        ButtonSegment(
          value: _MealTab.mine,
          icon: const Icon(Icons.person_rounded),
          label: Text(context.local.mine, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
      selected: {tab},
      showSelectedIcon: false,
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

/// Admin tab: record, edit and delete meals for any member on any date.
class _ManageTab extends StatelessWidget {
  const _ManageTab();

  @override
  Widget build(BuildContext context) {
    return _MealTabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AnimatedEntrance(child: MealAdminPanel()),
          SizedBox(height: context.bottomPadding),
        ],
      ),
    );
  }
}

/// The signed-in user's own meals — the only view for members, and the
/// "Mine" tab for admins.
class _MineTab extends StatelessWidget {
  const _MineTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MealBloc, MealState>(
      builder: (context, state) {
        return state.when(
          initial: _loading,
          loading: _loading,
          error: (message) => _ErrorView(message: message),
          loaded: (overview, refreshing) => Stack(
            children: [
              _MealBody(overview: overview),
              // Background reload (tab switch / pull-to-refresh) keeps the data shown.
              if (refreshing) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
            ],
          ),
        );
      },
    );
  }

  Widget _loading() => const Center(child: CircularProgressIndicator.adaptive());
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: Dimensions.iconSizeExtraLarge, color: colors.errorColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton.icon(onPressed: () => context.read<MealBloc>().add(const MealEvent.load()), icon: const Icon(Icons.refresh_rounded), label: Text(context.local.tryAgain)),
          ],
        ),
      ),
    );
  }
}

class _MealBody extends StatelessWidget {
  const _MealBody({required this.overview});
  final MealOverviewEntity overview;

  List<_Stat> _summary(BuildContext context) {
    final c = context.customThemeColors;
    return [
      _Stat('My Meals', MealFormatters.count(overview.totalMeals), Icons.restaurant_menu_rounded, c.primaryColor),
      _Stat('Meal Rate', DashboardFormatters.taka(overview.mealRate), Icons.sell_rounded, c.secondaryColor),
      _Stat('My Cost', DashboardFormatters.taka(overview.mealCost), Icons.account_balance_wallet_rounded, c.infoColor),
      _Stat('Avg / Day', overview.averagePerDay.toStringAsFixed(1), Icons.trending_up_rounded, c.successColor),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = overview.dayFor(now);

    // Read-only for everyone: a manager edits meals from the Manage meals tab.
    Widget todayCard() => AnimatedEntrance(
      child: MealTodayCard(today: today, mealRate: overview.mealRate),
    );

    Widget weekChart() => AnimatedEntrance(
      delay: const Duration(milliseconds: 80),
      child: MealWeekChart(days: overview.weekEndingOn(now)),
    );

    Widget history() => AnimatedEntrance(
      delay: const Duration(milliseconds: 120),
      child: MealHistoryList(days: overview.recentFirst, mealRate: overview.mealRate),
    );

    return RefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<MealBloc>()..add(const MealEvent.refresh());
        // Keep the pull-to-refresh spinner until the reload actually finishes.
        await bloc.stream.firstWhere((state) => state is! MealLoaded || !state.refreshing);
      },
      child: _MealTabScroll(
        physics: const AlwaysScrollableScrollPhysics(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SummaryGrid(stats: _summary(context)),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionTitle(title: 'Today', icon: Icons.today_rounded),
                            todayCard(),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            weekChart(),
                          ],
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeLarge),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SectionTitle(title: 'History', icon: Icons.history_rounded),
                            history(),
                          ],
                        ),
                      ),
                    ],
                  )
                else ...[
                  const SectionTitle(title: 'Today', icon: Icons.today_rounded),
                  todayCard(),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  weekChart(),
                  const SectionTitle(title: 'History', icon: Icons.history_rounded),
                  history(),
                ],
                SizedBox(height: context.bottomPadding),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Centered, width-capped scrolling tab body. On desktop the footer sits at
/// the bottom of the screen even when the content is short.
class _MealTabScroll extends StatelessWidget {
  const _MealTabScroll({required this.child, this.physics});

  final Widget child;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return LayoutBuilder(
      builder: (context, viewportConstraints) => SingleChildScrollView(
        physics: physics,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
          child: Column(
            mainAxisAlignment: isDesktop ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                  child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge), child: child),
                ),
              ),
              if (isDesktop) const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Width-adaptive summary metric grid (reuses the dashboard's [StatCard]).
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 150,
        crossAxisSpacing: Dimensions.paddingSizeDefault,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return AnimatedEntrance(
          delay: Duration(milliseconds: 50 * index),
          child: StatCard(label: stat.label, value: stat.value, icon: stat.icon, accent: stat.accent),
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon, this.accent);
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}
