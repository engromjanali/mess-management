import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/screen_matres_extensions.dart';
import '../../../../core/helpers/responsive_helper.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/dashboard_formatters.dart';
import '../widgets/home_sliver_app_bar.dart';
import '../widgets/member_stats_table.dart';
import '../widgets/pinned_notice_card.dart';
import '../widgets/pinned_section_header.dart';
import '../widgets/stat_card.dart';

/// Internal view-model for a single metric card.
class _Stat {
  const _Stat(this.label, this.value, this.icon, this.accent);
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

/// Redesigned, responsive home dashboard (phone / tablet / desktop).
///
/// Carries over every metric from the legacy `FirstScreen` — mess summary,
/// personal summary, the manager member breakdown and the pinned notice —
/// rendered with a collapsing hero header, pinned section headers, a
/// width-adaptive card grid and staggered entrance animations.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => getIt<HomeBloc>()..add(const HomeEvent.loadDashboard()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return state.when(
            initial: _loading,
            loading: _loading,
            error: (message) => _ErrorView(message: message),
            loaded: (dashboard) => _DashboardBody(dashboard: dashboard),
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
              onPressed: () => context
                  .read<HomeBloc>()
                  .add(const HomeEvent.loadDashboard()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard});
  final DashboardEntity dashboard;

  List<_Stat> _messStats(BuildContext context) {
    final c = context.customThemeColors;
    return [
      _Stat('Total Balance', DashboardFormatters.taka(dashboard.totalBalance),
          Icons.account_balance_wallet_rounded, c.primaryColor),
      _Stat('Meal Balance', DashboardFormatters.taka(dashboard.mealBalance),
          Icons.restaurant_rounded, c.secondaryColor),
      _Stat('Fund Balance', DashboardFormatters.taka(dashboard.fundBalance),
          Icons.savings_rounded, c.infoColor),
      _Stat('Total Deposit', DashboardFormatters.taka(dashboard.totalDeposit),
          Icons.payments_rounded, c.successColor),
      _Stat('Bazar Cost', DashboardFormatters.taka(dashboard.bazerCost),
          Icons.shopping_cart_rounded, c.warningColor),
      _Stat('Total Meal', DashboardFormatters.number(dashboard.totalMeal),
          Icons.set_meal_rounded, c.infoColor),
      _Stat('Meal Rate', DashboardFormatters.taka(dashboard.mealRate),
          Icons.sell_rounded, c.secondaryColor),
    ];
  }

  List<_Stat> _myStats(BuildContext context) {
    final c = context.customThemeColors;
    return [
      _Stat('My Total Meal', DashboardFormatters.number(dashboard.myTotalMeal),
          Icons.restaurant_menu_rounded, c.primaryColor),
      _Stat('My Deposit', DashboardFormatters.taka(dashboard.myDeposit),
          Icons.account_balance_wallet_rounded, c.successColor),
      _Stat(
          'My Remaining',
          DashboardFormatters.taka(dashboard.myRemaining),
          Icons.account_balance_rounded,
          dashboard.myRemaining < 0 ? c.errorColor : c.successColor),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Center content and cap it at the web max width on large screens.
    final maxWidth = Dimensions.webMaxWidth;
    final expandedHeight = ResponsiveHelper.isMobile(context) ? 260.0 : 240.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(const HomeEvent.refreshDashboard());
            // Give the bloc a beat to emit before dismissing the indicator.
            await Future<void>.delayed(const Duration(milliseconds: 900));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              HomeSliverAppBar(
                userName: dashboard.userName,
                totalBalance: dashboard.totalBalance,
                mealBalance: dashboard.mealBalance,
                fundBalance: dashboard.fundBalance,
                expandedHeight: expandedHeight,
              ),

              // Mess section
              SliverPersistentHeader(
                pinned: true,
                delegate: PinnedSectionHeader(
                  title: 'Mess Section',
                  icon: Icons.groups_rounded,
                ),
              ),
              _StatGrid(stats: _messStats(context)),

              // My section
              SliverPersistentHeader(
                pinned: true,
                delegate: PinnedSectionHeader(
                  title: 'My Section',
                  icon: Icons.person_rounded,
                ),
              ),
              _StatGrid(stats: _myStats(context)),

              // Manager-only member breakdown
              if (dashboard.isManager) ...[
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedSectionHeader(
                    title: 'Members',
                    icon: Icons.bar_chart_rounded,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Dimensions.paddingSizeLarge,
                    Dimensions.paddingSizeSmall,
                    Dimensions.paddingSizeLarge,
                    Dimensions.paddingSizeLarge,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedEntrance(
                      child: MemberStatsTable(
                        members: dashboard.members,
                        mealRate: dashboard.mealRate,
                      ),
                    ),
                  ),
                ),
              ],

              // Pinned notice
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeSmall,
                  Dimensions.paddingSizeLarge,
                  Dimensions.paddingSizeExtraLarge32,
                ),
                sliver: SliverToBoxAdapter(
                  child: AnimatedEntrance(
                    child: PinnedNoticeCard(notice: dashboard.pinnedNotice),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: SizedBox(height: context.bottomPadding),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Width-adaptive grid of [StatCard]s with staggered entrance animations.
class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeSmall,
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeSmall,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
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
      ),
    );
  }
}
