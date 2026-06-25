import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/stat_card.dart';
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
/// * **Phone** — single scrolling column.
/// * **Tablet / desktop** — centered, capped content with a two-column body
///   (editor + chart on the left, history on the right) under a summary grid.
class MealScreen extends StatelessWidget {
  const MealScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MealBloc>(
      create: (_) => getIt<MealBloc>()..add(const MealEvent.load()),
      child: const _MealView(),
    );
  }
}

class _MealView extends StatelessWidget {
  const _MealView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Meals'),
        actions: [
          // Admins get a shortcut to the bulk "add meal for all" page.
          BlocBuilder<RoleCubit, UserRole>(
            builder: (context, role) => role.isAdmin
                ? IconButton(
                    tooltip: 'Add meal for all',
                    icon: const Icon(Icons.playlist_add_rounded),
                    onPressed: () => context.push(AppRoutes.addMeal),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                context.read<MealBloc>().add(const MealEvent.refresh()),
          ),
        ],
      ),
      body: BlocBuilder<MealBloc, MealState>(
        builder: (context, state) {
          return state.when(
            initial: _loading,
            loading: _loading,
            error: (message) => _ErrorView(message: message),
            loaded: (overview) => _MealBody(overview: overview),
          );
        },
      ),
    );
  }

  Widget _loading() =>
      const Center(child: CircularProgressIndicator.adaptive());
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
            Icon(Icons.error_outline_rounded,
                size: Dimensions.iconSizeExtraLarge, color: colors.errorColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.sfProRoundedMedium.copyWith(
                color: colors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<MealBloc>().add(const MealEvent.load()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
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
      _Stat('My Meals', MealFormatters.count(overview.totalMeals),
          Icons.restaurant_menu_rounded, c.primaryColor),
      _Stat('Meal Rate', DashboardFormatters.taka(overview.mealRate),
          Icons.sell_rounded, c.secondaryColor),
      _Stat('My Cost', DashboardFormatters.taka(overview.mealCost),
          Icons.account_balance_wallet_rounded, c.infoColor),
      _Stat('Avg / Day', overview.averagePerDay.toStringAsFixed(1),
          Icons.trending_up_rounded, c.successColor),
    ];
  }

  void _onMealChanged(
    BuildContext context,
    double breakfast,
    double lunch,
    double dinner,
  ) {
    context.read<MealBloc>().add(
          MealEvent.updateToday(
            breakfast: breakfast,
            lunch: lunch,
            dinner: dinner,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = overview.todayFor(now);

    // Only the admin role can edit meal counts; users get a read-only view.
    final editable = context.watch<RoleCubit>().state.isAdmin;
    final logTitle = editable ? 'Log meals' : 'Today';
    final logIcon =
        editable ? Icons.edit_calendar_rounded : Icons.today_rounded;

    Widget todayCard() => AnimatedEntrance(
          child: MealTodayCard(
            today: today,
            mealRate: overview.mealRate,
            editable: editable,
            onChanged: (b, l, d) => _onMealChanged(context, b, l, d),
          ),
        );

    Widget weekChart() => AnimatedEntrance(
          delay: const Duration(milliseconds: 80),
          child: MealWeekChart(days: overview.lastSevenDays),
        );

    Widget history() => AnimatedEntrance(
          delay: const Duration(milliseconds: 120),
          child: MealHistoryList(
            days: overview.recentFirst,
            mealRate: overview.mealRate,
          ),
        );

    return RefreshIndicator(
      onRefresh: () async {
        context.read<MealBloc>().add(const MealEvent.refresh());
        await Future<void>.delayed(const Duration(milliseconds: 700));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryGrid(stats: _summary(context)),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                      // Admins get a full-width management section to record,
                      // edit and delete meals for any member on any date.
                      if (editable) ...[
                        const AnimatedEntrance(child: MealAdminPanel()),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                      ],
                      if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SectionTitle(title: logTitle, icon: logIcon),
                                  todayCard(),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeLarge),
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
                                  const SectionTitle(
                                      title: 'History',
                                      icon: Icons.history_rounded),
                                  history(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        SectionTitle(title: logTitle, icon: logIcon),
                        todayCard(),
                        const SizedBox(height: Dimensions.paddingSizeLarge),
                        weekChart(),
                        const SectionTitle(
                            title: 'History', icon: Icons.history_rounded),
                        history(),
                      ],
                      SizedBox(height: context.bottomPadding),
                    ],
                  );
                },
              ),
            ),
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
          child: StatCard(
            label: stat.label,
            value: stat.value,
            icon: stat.icon,
            accent: stat.accent,
          ),
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
