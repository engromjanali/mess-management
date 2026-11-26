import 'dart:math' as math;

import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/features/home/presentation/widgets/home_dashboard_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/network/api_client.dart';
import 'package:mess_pilot/core/role/role_cubit.dart';
import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/core/widgets/stat_card.dart';
import 'package:mess_pilot/core/widgets/stat_card_grid.dart';
import 'package:mess_pilot/core/widgets/mess_google_map_sheet.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/home/domain/entities/dashboard_entity.dart';
import 'package:mess_pilot/features/home/presentation/bloc/home_bloc.dart';
import 'package:mess_pilot/features/home/presentation/bloc/home_event.dart';
import 'package:mess_pilot/features/home/presentation/bloc/home_state.dart';
import 'package:mess_pilot/features/home/presentation/widgets/animated_entrance.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_hero_banner.dart';
import 'package:mess_pilot/features/home/presentation/widgets/feedback_banner_card.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/home_sliver_app_bar.dart';
import 'package:mess_pilot/features/membership/data/membership_api_service.dart';
import 'package:mess_pilot/features/membership/presentation/bloc/membership_cubit.dart';
import 'package:mess_pilot/features/home/presentation/widgets/member_stats_table.dart';
import 'package:mess_pilot/features/home/presentation/widgets/pinned_notice_card.dart';
import 'package:mess_pilot/features/home/presentation/widgets/pinned_section_header.dart';
import 'package:mess_pilot/features/home/presentation/widgets/section_title.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/membership/presentation/screens/membership_gate.dart';

/// Internal view-model for a single metric card.
class _Stat {
  const _Stat(this.label, this.value, this.icon, this.accent);
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

const double _messRowCardWidth = 148.0;
const double _messRowCardMaxWidth = 210.0;
const double _messBoxCardWidth = 230.0;

/// Per-card stride for the phone row: fixed width on phones, scaled up on
/// small tablets so the row uses the wider band.
double _phoneCardStride(double viewport) {
  const spacing = Dimensions.paddingSizeDefault;
  final cardWidth = (viewport / 4.5).clamp(_messRowCardWidth, _messRowCardMaxWidth).toDouble();
  return cardWidth + spacing;
}

/// Per-card stride for the desktop row: packs columns exactly like the
/// width-adaptive grid it replaced.
double _desktopCardStride(double viewport) {
  const spacing = Dimensions.paddingSizeDefault;
  if (!viewport.isFinite || viewport <= 0) return _messBoxCardWidth + spacing;
  final columns = math.max(1, (viewport / (_messBoxCardWidth + spacing)).ceil());
  return ((viewport - spacing * (columns - 1)) / columns) + spacing;
}

/// Builds the shared mess/personal metric lists from a [DashboardEntity].
List<_Stat> _messStats(BuildContext context, DashboardEntity d) {
  final c = context.customThemeColors;
  return [
    _Stat(context.local.uiTotalBalance, DashboardFormatters.taka(d.totalBalance), Icons.account_balance_wallet_rounded, c.primaryColor),
    _Stat(context.local.uiMealBalance, DashboardFormatters.taka(d.mealBalance), Icons.restaurant_rounded, c.secondaryColor),
    _Stat(context.local.fundBalance, DashboardFormatters.taka(d.fundBalance), Icons.savings_rounded, c.infoColor),
    _Stat(context.local.uiTotalDeposit, DashboardFormatters.taka(d.totalDeposit), Icons.payments_rounded, c.successColor),
    _Stat(context.local.uiCostCost, DashboardFormatters.taka(d.bazerCost), Icons.shopping_cart_rounded, c.warningColor),
    _Stat(context.local.uiTotalMeal, DashboardFormatters.number(d.totalMeal), Icons.set_meal_rounded, c.infoColor),
    _Stat(context.local.mealRate, DashboardFormatters.taka(d.mealRate), Icons.sell_rounded, c.secondaryColor),
  ];
}

List<_Stat> _myStats(BuildContext context, DashboardEntity d) {
  final c = context.customThemeColors;
  return [
    _Stat(context.local.uiMyTotalMeal, DashboardFormatters.number(d.myTotalMeal), Icons.restaurant_menu_rounded, c.primaryColor),
    _Stat(context.local.uiMyDeposit, DashboardFormatters.taka(d.myDeposit), Icons.account_balance_wallet_rounded, c.successColor),
    _Stat(context.local.uiMyRemaining, DashboardFormatters.taka(d.myRemaining), Icons.account_balance_rounded, d.myRemaining < 0 ? c.errorColor : c.successColor),
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
    final showDesktopBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: showDesktopBar ? PreferredSize(
        preferredSize: const Size.fromHeight(DashboardTopBar.height),
        child: Builder(builder: (context) => DashboardTopBar(active: DashboardSection.home, onProfileTap: () => Scaffold.of(context).openEndDrawer())),
      ) : null,
      endDrawer: ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context) ? const WebProfileDrawer() : null,
      body: MembershipGate(loadingChild: const HomeDashboardShimmer(), connectedChild: BlocProvider<HomeBloc>(create: (_) => getIt<HomeBloc>()..add(const HomeEvent.loadDashboard()), child: const _HomeView())),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return state.when(
            initial: _loading,
            loading: _loading,
            error: (message) => _ErrorView(message: message),
            loaded: (dashboard) {
              final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
              final role = context.watch<RoleCubit>().state;
              final scoped = dashboard.copyWith(userName: user?.name, isManager: role.canManage);

              if (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) {
                return _DesktopDashboard(dashboard: scoped);
              }
              // Phone + small tablet → animated bottom nav bar (capped width).
              return _PhoneDashboard(dashboard: scoped);
            },
          );
        },
    );
  }

  Widget _loading() => const HomeDashboardShimmer();
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppErrorState(error: message, onRetry: () => context.read<HomeBloc>().add(const HomeEvent.loadDashboard()));
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
  final _messRowController = ScrollController();

  /// Created once so repeated dashboard rebuilds reuse the same widget
  /// instance and the pinned header skips redundant rebuilds.
  late final _messArrows = _StatRowScrollArrows(controller: _messRowController, strideBuilder: _phoneCardStride);

  // Zero-height anchors used to scroll to a section from the bottom nav.
  final _statsAnchor = GlobalKey();
  final _noticeAnchor = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    _messRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    final role = context.watch<RoleCubit>().state;
    final photoUrl = context.select<AuthBloc, String?>((bloc) => bloc.state.maybeWhen(authenticated: (user) => user.photoUrl, orElse: () => null));
    final showMembers = dashboard.isManager || dashboard.members.isNotEmpty;
    final membershipState = context.watch<MembershipCubit>().state;
    final membership = membershipState is MembershipLoaded ? membershipState.status.current : null;
    final canSwitchMembership = membership != null && membershipState is MembershipLoaded && membershipState.status.memberships.any((item) => item.messId == membership.messId && item.canSwitch && !item.isCurrent);

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                HomeSliverAppBar(
                  userName: dashboard.userName,
                  role: role,
                  photoUrl: photoUrl,
                  currentSeasonName: dashboard.currentSeasonName,
                  totalBalance: dashboard.totalBalance,
                  expandedHeight: 210,
                  membership: membership,
                  hasSwitch: canSwitchMembership,
                ),
                if (dashboard.isManager) ...[
                  ..._buildMessSection(context, dashboard),
                  ..._buildCardSection(dashboard),
                  SliverToBoxAdapter(child: SizedBox(key: _statsAnchor, height: 0)),
                  ..._buildMySection(context, dashboard),
                  if (showMembers) ..._buildMembersSection(context, dashboard),
                ] else ...[
                  ..._buildMySection(context, dashboard),
                  SliverToBoxAdapter(child: SizedBox(key: _statsAnchor, height: 0)),
                  ..._buildCardSection(dashboard),
                  ..._buildMessSection(context, dashboard),
                  if (showMembers) ..._buildMembersSection(context, dashboard),
                ],
                SliverToBoxAdapter(child: SizedBox(key: _noticeAnchor, height: 0)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeExtraLarge32),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedEntrance(child: PinnedNoticeCard(notice: dashboard.pinnedNotice)),
                  ),
                ),
              ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMessSection(BuildContext context, DashboardEntity dashboard) {
    return [
      SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedSectionHeader(title: context.local.uiMessSection, icon: Icons.groups_rounded, trailing: _messArrows),
          ),
          _StatSliverRow(stats: _messStats(context, dashboard), controller: _messRowController),
        ],
      ),
    ];
  }

  List<Widget> _buildCardSection(DashboardEntity dashboard) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
        sliver: SliverToBoxAdapter(child: AnimatedEntrance(child: _MessDetailsCard(dashboard: dashboard))),
      ),
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, 0, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault),
        sliver: SliverToBoxAdapter(child: AnimatedEntrance(child: FeedbackBannerCard())),
      ),
    ];
  }

  List<Widget> _buildMySection(BuildContext context, DashboardEntity dashboard) {
    return [
      SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedSectionHeader(title: context.local.uiMySection, icon: Icons.person_rounded),
          ),
          if (dashboard.isMember)
            _StatSliverGrid(stats: _myStats(context, dashboard))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
              sliver: SliverToBoxAdapter(child: _NoSeasonMembershipCard(message: context.local.noSeasonMembershipAccess)),
            ),
        ],
      ),
    ];
  }

  List<Widget> _buildMembersSection(BuildContext context, DashboardEntity dashboard) {
    return [
      SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedSectionHeader(title: context.local.members, icon: Icons.bar_chart_rounded),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
            sliver: SliverToBoxAdapter(
              child: AnimatedEntrance(
                child: MemberStatsTable(members: dashboard.members, mealRate: dashboard.mealRate),
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

/// Sliver metric grid used by the phone layout.
class _StatSliverGrid extends StatelessWidget {
  const _StatSliverGrid({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    const spacing = Dimensions.paddingSizeDefault;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final crossAxisExtent = constraints.crossAxisExtent - Dimensions.paddingSizeLarge * 2;
          final columnCount = math.max(1, (crossAxisExtent / (130 + spacing)).ceil());
          final cardWidth = (crossAxisExtent - spacing * (columnCount - 1)) / columnCount;
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columnCount,
              mainAxisExtent: StatCard.gridMainAxisExtent(context, cardWidth: cardWidth, regular: 150),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) => AnimatedEntrance(
              delay: Duration(milliseconds: 50 * index),
              child: _statCard(stats[index]),
            ),
          );
        },
      ),
    );
  }
}

/// Prev/next arrow buttons that slide a stat row two cards per tap.
class _StatRowScrollArrows extends StatefulWidget {
  const _StatRowScrollArrows({required this.controller, required this.strideBuilder});
  final ScrollController controller;

  /// Per-card stride (card width + spacing) for the current viewport width.
  final double Function(double viewportWidth) strideBuilder;

  @override
  State<_StatRowScrollArrows> createState() => _StatRowScrollArrowsState();
}

class _StatRowScrollArrowsState extends State<_StatRowScrollArrows> {
  bool _lastBack = false;
  bool _lastForward = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _StatRowScrollArrows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    void refresh() {
      if (!mounted) return;
      final back = _canScrollBack;
      final forward = _canScrollForward;
      if (back == _lastBack && forward == _lastForward) return;
      setState(() {
        _lastBack = back;
        _lastForward = forward;
      });
    }

    // ScrollController fires during layout (position attach / first frame);
    // defer so we never call setState while the tree is building.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
    } else {
      refresh();
    }
  }

  bool get _canScrollBack {
    if (!widget.controller.hasClients) return false;
    return widget.controller.position.pixels > 0;
  }

  bool get _canScrollForward {
    if (!widget.controller.hasClients) return false;
    final position = widget.controller.position;
    // maxScrollExtent is null until content dimensions are applied.
    return position.hasContentDimensions && position.pixels < position.maxScrollExtent;
  }

  void _scroll(int direction) {
    final controller = widget.controller;
    if (!controller.hasClients || !controller.position.hasContentDimensions) return;
    final stride = widget.strideBuilder(controller.position.viewportDimension);
    final target = (controller.offset + direction * stride * 2).clamp(0.0, controller.position.maxScrollExtent);
    controller.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _arrowButton(context, icon: Icons.chevron_left_rounded, enabled: _canScrollBack, direction: -1),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        _arrowButton(context, icon: Icons.chevron_right_rounded, enabled: _canScrollForward, direction: 1),
      ],
    );
  }

  Widget _arrowButton(BuildContext context, {required IconData icon, required bool enabled, required int direction}) {
    final colors = context.customThemeColors;
    return Material(
      color: enabled ? colors.primaryColor.withValues(alpha: 0.10) : colors.textHintColor.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? () => _scroll(direction) : null,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(icon, size: Dimensions.iconSizeSmall + 2, color: enabled ? colors.primaryColor : colors.textHintColor),
        ),
      ),
    );
  }
}

/// Horizontally slidable single-row metrics (phone mess section).
class _StatSliverRow extends StatelessWidget {
  const _StatSliverRow({required this.stats, required this.controller});
  final List<_Stat> stats;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    const spacing = Dimensions.paddingSizeDefault;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      sliver: SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth / 4.5).clamp(_messRowCardWidth, _messRowCardMaxWidth).toDouble();
            return SizedBox(
              height: StatCard.gridMainAxisExtent(context, cardWidth: cardWidth, regular: 150),
              child: ListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
                itemCount: stats.length,
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(right: index == stats.length - 1 ? 0 : spacing),
                  child: SizedBox(
                    width: cardWidth,
                    child: AnimatedEntrance(
                      delay: Duration(milliseconds: 50 * index),
                      child: _statCard(stats[index]),
                    ),
                  ),
                ),
              ),
            );
          },
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
  final _messRowController = ScrollController();

  /// Created once so repeated dashboard rebuilds reuse the same widget
  /// instance and `SectionTitle` skips redundant rebuilds.
  late final _messArrows = _StatRowScrollArrows(controller: _messRowController, strideBuilder: _desktopCardStride);

  @override
  void dispose() {
    _scrollController.dispose();
    _messRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: AppPageScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                        AnimatedEntrance(child: _heroBanner(dashboard)),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        const AnimatedEntrance(child: FeedbackBannerCard()),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        if (dashboard.isManager) ...[
                          // 1. Mess section
                          SectionTitle(title: context.local.uiMessSection, icon: Icons.groups_rounded, trailing: _messArrows),
                          _StatBoxRow(stats: _messStats(context, dashboard), controller: _messRowController),
                          const SizedBox(height: Dimensions.paddingSizeDefault),

                          // 2. Card
                          AnimatedEntrance(child: _MessDetailsCard(dashboard: dashboard)),
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          // 3. My section (left) + pinned notice (right)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SectionTitle(title: context.local.uiMySection, icon: Icons.person_rounded),
                                    if (dashboard.isMember)
                                      _StatBoxGrid(stats: _myStats(context, dashboard), maxCrossAxisExtent: 230)
                                    else
                                      _NoSeasonMembershipCard(message: context.local.noSeasonMembershipAccess),
                                  ],
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeLarge),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SectionTitle(title: context.local.uiPinnedNotice, icon: Icons.push_pin_rounded),
                                    AnimatedEntrance(child: PinnedNoticeCard(notice: dashboard.pinnedNotice)),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // 4. Member
                          if (dashboard.members.isNotEmpty || dashboard.isManager) ...[
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            SectionTitle(title: context.local.members, icon: Icons.bar_chart_rounded),
                            AnimatedEntrance(
                              child: MemberStatsTable(members: dashboard.members, mealRate: dashboard.mealRate),
                            ),
                          ],
                        ] else ...[
                          // 1. My section (left) + pinned notice (right)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SectionTitle(title: context.local.uiMySection, icon: Icons.person_rounded),
                                    if (dashboard.isMember)
                                      _StatBoxGrid(stats: _myStats(context, dashboard), maxCrossAxisExtent: 230)
                                    else
                                      _NoSeasonMembershipCard(message: context.local.noSeasonMembershipAccess),
                                  ],
                                ),
                              ),
                              const SizedBox(width: Dimensions.paddingSizeLarge),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SectionTitle(title: context.local.uiPinnedNotice, icon: Icons.push_pin_rounded),
                                    AnimatedEntrance(child: PinnedNoticeCard(notice: dashboard.pinnedNotice)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          // 2. Card
                          AnimatedEntrance(child: _MessDetailsCard(dashboard: dashboard)),
                          const SizedBox(height: Dimensions.paddingSizeLarge),

                          // 3. Mess section
                          SectionTitle(title: context.local.uiMessSection, icon: Icons.groups_rounded, trailing: _messArrows),
                          _StatBoxRow(stats: _messStats(context, dashboard), controller: _messRowController),

                          // 4. Member
                          if (dashboard.members.isNotEmpty) ...[
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            SectionTitle(title: context.local.members, icon: Icons.bar_chart_rounded),
                            AnimatedEntrance(
                              child: MemberStatsTable(members: dashboard.members, mealRate: dashboard.mealRate),
                            ),
                          ],
                        ],
                            const SizedBox(height: Dimensions.paddingSizeExtraLarge32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

class _NoSeasonMembershipCard extends StatelessWidget {
  const _NoSeasonMembershipCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: colors.infoColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: colors.infoColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: colors.infoColor),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(child: Text(message, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor, height: 1.4))),
        ],
      ),
    );
  }
}

class _MessDetailsCard extends StatefulWidget {
  const _MessDetailsCard({required this.dashboard});

  final DashboardEntity dashboard;

  @override
  State<_MessDetailsCard> createState() => _MessDetailsCardState();
}

class _MessDetailsCardState extends State<_MessDetailsCard> {
  bool _openingMap = false;

  Future<void> _openMap() async {
    if (_openingMap) return;
    setState(() => _openingMap = true);
    try {
      final mess = await MembershipApiService(getIt<ApiClient>()).getMessDetails();
      if (!mounted) return;
      if (mess.latitude == null || mess.longitude == null) {
        context.showInfoSnackBar(context.local.messLocationNotSet);
        return;
      }
      setState(() => _openingMap = false);
      await showMessGoogleMap(context: context, latitude: mess.latitude, longitude: mess.longitude, address: mess.address);
    } catch (error) {
      if (mounted) context.showErrorSnackBar(error);
    } finally {
      if (mounted && _openingMap) setState(() => _openingMap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final dashboard = widget.dashboard;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          final contactWidth = wide ? (constraints.maxWidth - Dimensions.paddingSizeLarge) / 2 : constraints.maxWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: Dimensions.paddingSizeLarge,
                runSpacing: Dimensions.paddingSizeLarge,
                children: [
                  if ([dashboard.managerName, dashboard.managerEmail, dashboard.managerPhone].any((value) => value.isNotEmpty))
                    SizedBox(width: contactWidth, child: _MessContact(title: context.local.roleManager, name: dashboard.managerName, email: dashboard.managerEmail, phone: dashboard.managerPhone)),
                  if ([dashboard.actingManagerName, dashboard.actingManagerEmail, dashboard.actingManagerPhone].any((value) => value.isNotEmpty))
                    SizedBox(width: contactWidth, child: _MessContact(title: context.local.roleActingManager, name: dashboard.actingManagerName, email: dashboard.actingManagerEmail, phone: dashboard.actingManagerPhone)),
                ],
              ),
              if (dashboard.messAddress.isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, color: colors.primaryColor),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(child: Text(dashboard.messAddress, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textPrimaryColor))),
                  ],
                ),
              ],
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Wrap(
                spacing: Dimensions.paddingSizeSmall,
                runSpacing: Dimensions.paddingSizeSmall,
                children: [
                  FilledButton.icon(
                    onPressed: _openingMap ? null : _openMap,
                    icon: _openingMap ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.map_outlined),
                    label: Text(context.local.showOnMap),
                  ),
                  OutlinedButton.icon(onPressed: () => context.go(AppRoutes.opinions), icon: const Icon(Icons.forum_outlined), label: Text(context.local.shareOpinion)),
                  OutlinedButton.icon(onPressed: () => context.go(AppRoutes.polls), icon: const Icon(Icons.poll_outlined), label: Text(context.local.pollPolls)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MessContact extends StatelessWidget {
  const _MessContact({required this.title, required this.name, required this.email, required this.phone});

  final String title;
  final String name;
  final String email;
  final String phone;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor)),
        if (name.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _MessContactLine(icon: Icons.person_outline_rounded, value: name),
        ],
        if (email.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          _MessContactLine(icon: Icons.email_outlined, value: email),
        ],
        if (phone.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          _MessContactLine(icon: Icons.phone_outlined, value: phone),
        ],
      ],
    );
  }
}

class _MessContactLine extends StatelessWidget {
  const _MessContactLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Row(
      children: [
        Icon(icon, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.sfProRoundedRegular.copyWith(color: colors.textSecondaryColor))),
      ],
    );
  }
}

/// Horizontally slidable single-row metrics (desktop mess section).
class _StatBoxRow extends StatelessWidget {
  const _StatBoxRow({required this.stats, required this.controller});
  final List<_Stat> stats;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    const spacing = Dimensions.paddingSizeDefault;
    return Scrollbar(
      controller: controller,
      thumbVisibility: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final columns = width.isFinite && width > 0 ? math.max(1, (width / (_messBoxCardWidth + spacing)).ceil()) : 1;
          final cardWidth = (width - spacing * (columns - 1)) / columns;
          return SizedBox(
            height: StatCard.gridMainAxisExtent(context, cardWidth: cardWidth, regular: 150),
            child: ListView.builder(
              controller: controller,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: stats.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(right: index == stats.length - 1 ? 0 : spacing),
                child: SizedBox(
                  width: cardWidth,
                  child: AnimatedEntrance(
                    delay: Duration(milliseconds: 50 * index),
                    child: _statCard(stats[index]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Non-sliver, self-sizing metric grid for the tablet & desktop bodies.
class _StatBoxGrid extends StatelessWidget {
  const _StatBoxGrid({required this.stats, required this.maxCrossAxisExtent});
  final List<_Stat> stats;
  final double maxCrossAxisExtent;

  @override
  Widget build(BuildContext context) {
    return StatCardGrid(
      maxCardExtent: maxCrossAxisExtent,
      regularExtent: 150,
      itemCount: stats.length,
      itemBuilder: (context, index) => AnimatedEntrance(
        delay: Duration(milliseconds: 50 * index),
        child: _statCard(stats[index]),
      ),
    );
  }
}

Widget _statCard(_Stat stat) => StatCard(label: stat.label, value: stat.value, icon: stat.icon, accent: stat.accent);

Widget _heroBanner(DashboardEntity d) => DashboardHeroBanner(userName: d.userName, totalBalance: d.totalBalance);

Future<void> _refresh(BuildContext context) async {
  context.read<HomeBloc>().add(const HomeEvent.refreshDashboard());
  await Future<void>.delayed(const Duration(milliseconds: 900));
}
