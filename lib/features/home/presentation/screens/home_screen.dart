import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/core/widgets/stat_card.dart';
import 'package:clean_boilerplate/core/widgets/mess_google_map_sheet.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/domain/entities/dashboard_entity.dart';
import 'package:clean_boilerplate/features/home/presentation/bloc/home_bloc.dart';
import 'package:clean_boilerplate/features/home/presentation/bloc/home_event.dart';
import 'package:clean_boilerplate/features/home/presentation/bloc/home_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_hero_banner.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/home_sliver_app_bar.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/member_stats_table.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/pinned_notice_card.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/pinned_section_header.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/membership/presentation/bloc/membership_cubit.dart';
import 'package:clean_boilerplate/features/membership/presentation/screens/membership_gate.dart';

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
    _Stat('Total Balance', DashboardFormatters.taka(d.totalBalance), Icons.account_balance_wallet_rounded, c.primaryColor),
    _Stat('Meal Balance', DashboardFormatters.taka(d.mealBalance), Icons.restaurant_rounded, c.secondaryColor),
    _Stat('Fund Balance', DashboardFormatters.taka(d.fundBalance), Icons.savings_rounded, c.infoColor),
    _Stat('Total Deposit', DashboardFormatters.taka(d.totalDeposit), Icons.payments_rounded, c.successColor),
    _Stat('Cost Cost', DashboardFormatters.taka(d.bazerCost), Icons.shopping_cart_rounded, c.warningColor),
    _Stat('Total Meal', DashboardFormatters.number(d.totalMeal), Icons.set_meal_rounded, c.infoColor),
    _Stat('Meal Rate', DashboardFormatters.taka(d.mealRate), Icons.sell_rounded, c.secondaryColor),
  ];
}

List<_Stat> _myStats(BuildContext context, DashboardEntity d) {
  final c = context.customThemeColors;
  return [
    _Stat('My Total Meal', DashboardFormatters.number(d.myTotalMeal), Icons.restaurant_menu_rounded, c.primaryColor),
    _Stat('My Deposit', DashboardFormatters.taka(d.myDeposit), Icons.account_balance_wallet_rounded, c.successColor),
    _Stat('My Remaining', DashboardFormatters.taka(d.myRemaining), Icons.account_balance_rounded, d.myRemaining < 0 ? c.errorColor : c.successColor),
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
    return BlocProvider<MembershipCubit>(
      create: (_) => MembershipCubit(MembershipApiService(getIt<ApiClient>()))..load(),
      child: MembershipGate(connectedChild: BlocProvider<HomeBloc>(create: (_) => getIt<HomeBloc>()..add(const HomeEvent.loadDashboard()), child: const _HomeView())),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context) ? const WebProfileDrawer() : null,
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return state.when(
            initial: _loading,
            loading: _loading,
            error: (message) => _ErrorView(message: message),
            loaded: (dashboard) {
              final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
              final previewRole = context.watch<RoleCubit>().state;
              final scoped = dashboard.copyWith(userName: user?.name, isManager: previewRole.isAdmin);

              if (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) {
                return _DesktopDashboard(dashboard: scoped);
              }
              // Phone + small tablet → animated bottom nav bar (capped width).
              return _PhoneDashboard(dashboard: scoped);
            },
          );
        },
      ),
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
            ElevatedButton.icon(onPressed: () => context.read<HomeBloc>().add(const HomeEvent.loadDashboard()), icon: const Icon(Icons.refresh_rounded), label: const Text('Retry')),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    final photoUrl = context.select<AuthBloc, String?>((bloc) => bloc.state.maybeWhen(authenticated: (user) => user.photoUrl, orElse: () => null));

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                HomeSliverAppBar(userName: dashboard.userName, photoUrl: photoUrl, currentSeasonName: dashboard.currentSeasonName, totalBalance: dashboard.totalBalance, expandedHeight: 200),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedSectionHeader(title: 'Mess Section', icon: Icons.groups_rounded),
                ),
                _StatSliverGrid(stats: _messStats(context, dashboard)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
                  sliver: SliverToBoxAdapter(child: AnimatedEntrance(child: _MessDetailsCard(dashboard: dashboard))),
                ),
                SliverToBoxAdapter(child: SizedBox(key: _statsAnchor, height: 0)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: PinnedSectionHeader(title: 'My Section', icon: Icons.person_rounded),
                ),
                if (dashboard.isMember)
                  _StatSliverGrid(stats: _myStats(context, dashboard))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
                    sliver: SliverToBoxAdapter(child: _NoSeasonMembershipCard(message: context.local.noSeasonMembershipAccess)),
                  ),
                if (dashboard.isManager) ...[
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: PinnedSectionHeader(title: 'Members', icon: Icons.bar_chart_rounded),
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
}

/// Sliver metric grid used by the phone layout.
class _StatSliverGrid extends StatelessWidget {
  const _StatSliverGrid({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    final navItems = <DashboardNavItem>[
      DashboardNavItem(
        label: 'Home',
        icon: Icons.home_rounded,
        active: true,
        onTap: () => _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOutCubic),
      ),
      DashboardNavItem(label: 'Meals', icon: Icons.restaurant_rounded, onTap: () => context.go(AppRoutes.meals)),
      DashboardNavItem(label: 'Deposits', icon: Icons.account_balance_wallet_rounded, onTap: () => context.go(AppRoutes.deposits)),
      DashboardNavItem(label: 'Cost', icon: Icons.shopping_cart_rounded, onTap: () => context.go(AppRoutes.costs)),
    ];

    return Column(
      children: [
        DashboardTopBar(userName: dashboard.userName, onProfileTap: () => Scaffold.of(context).openEndDrawer(), navItems: navItems),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
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
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        // Mess section — wide grid.
                        const SectionTitle(title: 'Mess Section', icon: Icons.groups_rounded),
                        _StatBoxGrid(stats: _messStats(context, dashboard), maxCrossAxisExtent: 230),
                        const SizedBox(height: Dimensions.paddingSizeDefault),
                        AnimatedEntrance(child: _MessDetailsCard(dashboard: dashboard)),
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
                                  const SectionTitle(title: 'My Section', icon: Icons.person_rounded),
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
                                  const SectionTitle(title: 'Pinned Notice', icon: Icons.push_pin_rounded),
                                  AnimatedEntrance(child: PinnedNoticeCard(notice: dashboard.pinnedNotice)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (dashboard.isManager) ...[
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          const SectionTitle(title: 'Members', icon: Icons.bar_chart_rounded),
                          AnimatedEntrance(
                            child: MemberStatsTable(members: dashboard.members, mealRate: dashboard.mealRate),
                          ),
                        ],
                            const SizedBox(height: Dimensions.paddingSizeExtraLarge32),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (ResponsiveHelper.isDesktop(context)) const AppFooter(),
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
                    SizedBox(width: contactWidth, child: _MessContact(title: 'Manager', name: dashboard.managerName, email: dashboard.managerEmail, phone: dashboard.managerPhone)),
                  if ([dashboard.actingManagerName, dashboard.actingManagerEmail, dashboard.actingManagerPhone].any((value) => value.isNotEmpty))
                    SizedBox(width: contactWidth, child: _MessContact(title: 'Acting manager', name: dashboard.actingManagerName, email: dashboard.actingManagerEmail, phone: dashboard.actingManagerPhone)),
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
                    label: Text(context.local.showOnGoogleMaps),
                  ),
                  OutlinedButton.icon(onPressed: () => context.go(AppRoutes.opinions), icon: const Icon(Icons.forum_outlined), label: Text(context.local.shareYourOpinions)),
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

Widget _statCard(_Stat stat) => StatCard(label: stat.label, value: stat.value, icon: stat.icon, accent: stat.accent);

Widget _heroBanner(DashboardEntity d) => DashboardHeroBanner(userName: d.userName, currentSeasonName: d.currentSeasonName, totalBalance: d.totalBalance);

Future<void> _refresh(BuildContext context) async {
  context.read<HomeBloc>().add(const HomeEvent.refreshDashboard());
  await Future<void>.delayed(const Duration(milliseconds: 900));
}
