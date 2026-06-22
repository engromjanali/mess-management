import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/route/app_router.dart';
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
import '../widgets/animated_bottom_nav_bar.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/dashboard_formatters.dart';
import '../widgets/dashboard_hero_banner.dart';
import '../widgets/dashboard_top_bar.dart';
import '../widgets/home_sliver_app_bar.dart';
import '../widgets/member_stats_table.dart';
import '../widgets/pinned_notice_card.dart';
import '../widgets/pinned_section_header.dart';
import '../widgets/section_title.dart';
import '../widgets/stat_card.dart';

/// Internal view-model for a single metric card.
class _Stat {
  const _Stat(this.label, this.value, this.icon, this.accent);
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

/// Builds the shared mess/personal metric lists from a [DashboardEntity].
List<_Stat> _messStats(BuildContext context, DashboardEntity d) {
  final c = context.customThemeColors;
  return [
    _Stat('Total Balance', DashboardFormatters.taka(d.totalBalance),
        Icons.account_balance_wallet_rounded, c.primaryColor),
    _Stat('Meal Balance', DashboardFormatters.taka(d.mealBalance),
        Icons.restaurant_rounded, c.secondaryColor),
    _Stat('Fund Balance', DashboardFormatters.taka(d.fundBalance),
        Icons.savings_rounded, c.infoColor),
    _Stat('Total Deposit', DashboardFormatters.taka(d.totalDeposit),
        Icons.payments_rounded, c.successColor),
    _Stat('Bazar Cost', DashboardFormatters.taka(d.bazerCost),
        Icons.shopping_cart_rounded, c.warningColor),
    _Stat('Total Meal', DashboardFormatters.number(d.totalMeal),
        Icons.set_meal_rounded, c.infoColor),
    _Stat('Meal Rate', DashboardFormatters.taka(d.mealRate),
        Icons.sell_rounded, c.secondaryColor),
  ];
}

List<_Stat> _myStats(BuildContext context, DashboardEntity d) {
  final c = context.customThemeColors;
  return [
    _Stat('My Total Meal', DashboardFormatters.number(d.myTotalMeal),
        Icons.restaurant_menu_rounded, c.primaryColor),
    _Stat('My Deposit', DashboardFormatters.taka(d.myDeposit),
        Icons.account_balance_wallet_rounded, c.successColor),
    _Stat('My Remaining', DashboardFormatters.taka(d.myRemaining),
        Icons.account_balance_rounded,
        d.myRemaining < 0 ? c.errorColor : c.successColor),
  ];
}

/// Responsive home dashboard.
///
/// Switches between three professionally-tuned layouts:
/// * **Phone** — collapsing hero [SliverAppBar] + single column.
/// * **Tablet** — compact top bar + gradient banner + two-column body.
/// * **Desktop** — full top navigation bar + gradient banner + multi-column.
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
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return state.when(
            initial: _loading,
            loading: _loading,
            error: (message) => _ErrorView(message: message),
            loaded: (dashboard) {
              if (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) {
                return _DesktopDashboard(dashboard: dashboard);
              }
              // Phone + small tablet → animated bottom nav bar (capped width).
              return _PhoneDashboard(dashboard: dashboard);
            },
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

// ─────────────────────────────────────────────────────────────────────────
// Phone — collapsing hero + single column (sliver layout).
// ─────────────────────────────────────────────────────────────────────────

class _PhoneDashboard extends StatefulWidget {
  const _PhoneDashboard({required this.dashboard});
  final DashboardEntity dashboard;

  @override
  State<_PhoneDashboard> createState() => _PhoneDashboardState();
}

class _PhoneDashboardState extends State<_PhoneDashboard> {
  final _scrollController = ScrollController();

  // Zero-height anchors used to scroll to a section from the bottom nav.
  final _statsAnchor = GlobalKey();
  final _noticeAnchor = GlobalKey();

  bool _navVisible = true;
  int _currentIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Show the bar on scroll-up, hide it on scroll-down.
  bool _onScroll(UserScrollNotification n) {
    // Ignore horizontal / inner scrollables.
    if (n.metrics.axis != Axis.vertical) return false;

    switch (n.direction) {
      case ScrollDirection.reverse:
        if (_navVisible) setState(() => _navVisible = false);
        break;
      case ScrollDirection.forward:
        if (!_navVisible) setState(() => _navVisible = true);
        break;
      case ScrollDirection.idle:
        break;
    }
    return false;
  }

  void _onNavTap(int index, VoidCallback action) {
    setState(() {
      _currentIndex = index;
      // Any deliberate navigation reveals the bar again.
      _navVisible = true;
    });
    action();
  }

  void _scrollToTop() => _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );

  void _scrollToAnchor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      alignment: 0.1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    // Leave room so the floating nav never covers the last content.
    final bottomInset = context.bottomPadding + 96;

    final navItems = <BottomNavItem>[
      BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        onTap: () => _onNavTap(0, _scrollToTop),
      ),
      BottomNavItem(
        icon: Icons.insights_outlined,
        activeIcon: Icons.insights_rounded,
        label: 'Stats',
        onTap: () => _onNavTap(1, () => _scrollToAnchor(_statsAnchor)),
      ),
      BottomNavItem(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications_rounded,
        label: 'Notice',
        onTap: () => _onNavTap(2, () => _scrollToAnchor(_noticeAnchor)),
      ),
      BottomNavItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
        onTap: () => _onNavTap(3, () => context.push(AppRoutes.settings)),
      ),
    ];

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: NotificationListener<UserScrollNotification>(
            onNotification: _onScroll,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                HomeSliverAppBar(
                  userName: dashboard.userName,
                  totalBalance: dashboard.totalBalance,
                  mealBalance: dashboard.mealBalance,
                  fundBalance: dashboard.fundBalance,
                  expandedHeight: 260,
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedSectionHeader(
                    title: 'Mess Section',
                    icon: Icons.groups_rounded,
                  ),
                ),
                _StatSliverGrid(stats: _messStats(context, dashboard)),
                SliverToBoxAdapter(
                  child: SizedBox(key: _statsAnchor, height: 0),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedSectionHeader(
                    title: 'My Section',
                    icon: Icons.person_rounded,
                  ),
                ),
                _StatSliverGrid(stats: _myStats(context, dashboard)),
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
                SliverToBoxAdapter(
                  child: SizedBox(key: _noticeAnchor, height: 0),
                ),
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
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBottomNavBar(
            items: navItems,
            currentIndex: _currentIndex,
            visible: _navVisible,
          ),
        ),
      ],
    );
  }
}

/// Sliver metric grid used by the phone layout.
class _StatSliverGrid extends StatelessWidget {
  const _StatSliverGrid({required this.stats});
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
        itemBuilder: (context, index) => AnimatedEntrance(
          delay: Duration(milliseconds: 50 * index),
          child: _statCard(stats[index]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Big tablet + desktop — full top navigation bar + gradient banner + columns.
// ─────────────────────────────────────────────────────────────────────────

class _DesktopDashboard extends StatefulWidget {
  const _DesktopDashboard({required this.dashboard});
  final DashboardEntity dashboard;

  @override
  State<_DesktopDashboard> createState() => _DesktopDashboardState();
}

class _DesktopDashboardState extends State<_DesktopDashboard> {
  final _scrollController = ScrollController();
  final _messKey = GlobalKey();
  final _myKey = GlobalKey();
  final _membersKey = GlobalKey();
  final _noticeKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    final navItems = <DashboardNavItem>[
      DashboardNavItem(
        label: 'Overview',
        icon: Icons.dashboard_rounded,
        active: true,
        onTap: () => _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        ),
      ),
      DashboardNavItem(
        label: 'Mess',
        icon: Icons.groups_rounded,
        onTap: () => _scrollTo(_messKey),
      ),
      if (dashboard.isManager)
        DashboardNavItem(
          label: 'Members',
          icon: Icons.bar_chart_rounded,
          onTap: () => _scrollTo(_membersKey),
        ),
      DashboardNavItem(
        label: 'Notice',
        icon: Icons.push_pin_rounded,
        onTap: () => _scrollTo(_noticeKey),
      ),
    ];

    return Column(
      children: [
        DashboardTopBar(
          userName: dashboard.userName,
          onRefresh: () => _refresh(context),
          navItems: navItems,
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.all(
                      Dimensions.paddingSizeExtraLarge24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AnimatedEntrance(child: _heroBanner(dashboard)),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        // Mess section — wide grid.
                        SectionTitle(
                          key: _messKey,
                          title: 'Mess Section',
                          icon: Icons.groups_rounded,
                        ),
                        _StatBoxGrid(
                          stats: _messStats(context, dashboard),
                          maxCrossAxisExtent: 230,
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),

                        // My section (left) + pinned notice (right).
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SectionTitle(
                                    key: _myKey,
                                    title: 'My Section',
                                    icon: Icons.person_rounded,
                                  ),
                                  _StatBoxGrid(
                                    stats: _myStats(context, dashboard),
                                    maxCrossAxisExtent: 230,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: Dimensions.paddingSizeLarge),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SectionTitle(
                                    key: _noticeKey,
                                    title: 'Pinned Notice',
                                    icon: Icons.push_pin_rounded,
                                  ),
                                  AnimatedEntrance(
                                    child: PinnedNoticeCard(
                                      notice: dashboard.pinnedNotice,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (dashboard.isManager) ...[
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          SectionTitle(
                            key: _membersKey,
                            title: 'Members',
                            icon: Icons.bar_chart_rounded,
                          ),
                          AnimatedEntrance(
                            child: MemberStatsTable(
                              members: dashboard.members,
                              mealRate: dashboard.mealRate,
                            ),
                          ),
                        ],
                        const SizedBox(height: Dimensions.paddingSizeExtraLarge32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers.
// ─────────────────────────────────────────────────────────────────────────

/// Non-sliver, self-sizing metric grid for the tablet & desktop bodies.
class _StatBoxGrid extends StatelessWidget {
  const _StatBoxGrid({required this.stats, required this.maxCrossAxisExtent});
  final List<_Stat> stats;
  final double maxCrossAxisExtent;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisExtent: 150,
        crossAxisSpacing: Dimensions.paddingSizeDefault,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) => AnimatedEntrance(
        delay: Duration(milliseconds: 50 * index),
        child: _statCard(stats[index]),
      ),
    );
  }
}

Widget _statCard(_Stat stat) => StatCard(
      label: stat.label,
      value: stat.value,
      icon: stat.icon,
      accent: stat.accent,
    );

Widget _heroBanner(DashboardEntity d) => DashboardHeroBanner(
      userName: d.userName,
      totalBalance: d.totalBalance,
      mealBalance: d.mealBalance,
      fundBalance: d.fundBalance,
    );

Future<void> _refresh(BuildContext context) async {
  context.read<HomeBloc>().add(const HomeEvent.refreshDashboard());
  await Future<void>.delayed(const Duration(milliseconds: 900));
}
