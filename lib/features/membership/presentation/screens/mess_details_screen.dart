import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/network/api_client.dart';
import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/core/widgets/stat_card.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/main_page_body.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_formatters.dart';
import 'package:clean_boilerplate/features/membership/data/membership_api_service.dart';
import 'package:clean_boilerplate/features/membership/domain/entities/mess_details_entity.dart';
import 'package:clean_boilerplate/features/membership/presentation/bloc/mess_details_cubit.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_contact_card.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_hero_card.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_leadership_card.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_members_card.dart';
import 'package:clean_boilerplate/features/membership/presentation/widgets/mess_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The signed-in user's current mess: who runs it, the active season and its
/// numbers, the members and the mess's contact details — plus edit, transfer
/// and leave for the roles allowed to.
class MessDetailsScreen extends StatelessWidget {
  const MessDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MessDetailsCubit>(create: (_) => MessDetailsCubit(MembershipApiService(getIt<ApiClient>()))..load(), child: const _MessDetailsView());
  }
}

class _MessDetailsView extends StatelessWidget {
  const _MessDetailsView();

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = MainPageBody.showWebAppBar(context);

    final content = BlocBuilder<MessDetailsCubit, MessDetailsState>(
      builder: (context, state) => switch (state) {
        MessDetailsLoading() => const Center(child: CircularProgressIndicator.adaptive()),
        MessDetailsError(:final message) => _ErrorView(message: message),
        MessDetailsLoaded() => _MessBody(state: state),
      },
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
      appBar: showWebAppBar
          ? null
          : AppBar(
              leading: const HomeBackButton(),
              title: Text(context.local.mess),
              actions: [
                BlocBuilder<MessDetailsCubit, MessDetailsState>(
                  builder: (context, state) =>
                      IconButton(tooltip: context.local.refresh, onPressed: state is MessDetailsLoaded && !state.busy ? () => _refresh(context) : null, icon: const Icon(Icons.refresh_rounded)),
                ),
              ],
            ),
      body: MainPageBody(title: context.local.mess, child: content),
    );
  }
}

/// Reloads the page and reports a failure; shared by pull-to-refresh, the
/// refresh button and returning from edit / transfer.
Future<void> _refresh(BuildContext context) async {
  final error = await context.read<MessDetailsCubit>().refresh();
  if (error != null && context.mounted) context.showErrorSnackBar(error);
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
            Icon(Icons.home_work_outlined, size: Dimensions.iconSizeExtraLarge, color: colors.textHintColor),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Wrap(
              spacing: Dimensions.paddingSizeSmall,
              runSpacing: Dimensions.paddingSizeSmall,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(onPressed: () => context.read<MessDetailsCubit>().load(), icon: const Icon(Icons.refresh_rounded), label: Text(context.local.tryAgain)),
                OutlinedButton.icon(onPressed: () => context.go(AppRoutes.joinMess), icon: const Icon(Icons.group_add_rounded), label: Text(context.local.joinMess)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MessBody extends StatelessWidget {
  const _MessBody({required this.state});

  final MessDetailsLoaded state;

  @override
  Widget build(BuildContext context) {
    final mess = state.mess;
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    final myUserId = int.tryParse(user?.id ?? '');

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                // Fills the screen so the footer sits at the bottom on desktop.
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Column(
                  mainAxisAlignment: isDesktop ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                        child: Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final wide = constraints.maxWidth >= 900;
                              final leadership = AnimatedEntrance(
                                delay: const Duration(milliseconds: 120),
                                child: MessLeadershipCard(manager: mess.manager, actingManager: mess.actingManager),
                              );
                              final members = AnimatedEntrance(
                                delay: const Duration(milliseconds: 160),
                                child: MessMembersCard(members: mess.members, myUserId: myUserId),
                              );
                              final contact = AnimatedEntrance(
                                delay: const Duration(milliseconds: 200),
                                child: MessContactCard(mess: mess),
                              );
                              final actions = AnimatedEntrance(
                                delay: const Duration(milliseconds: 240),
                                child: _ActionsCard(state: state),
                              );
                              const gap = SizedBox(height: Dimensions.paddingSizeLarge);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AnimatedEntrance(child: MessHeroCard(mess: mess)),
                                  const SizedBox(height: Dimensions.paddingSizeSmall),
                                  SectionTitle(title: context.local.seasonSnapshot, icon: Icons.insights_rounded),
                                  AnimatedEntrance(
                                    delay: const Duration(milliseconds: 80),
                                    child: _StatsGrid(stats: mess.stats),
                                  ),
                                  gap,
                                  if (wide)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 3, child: Column(children: [leadership, gap, contact])),
                                        const SizedBox(width: Dimensions.paddingSizeLarge),
                                        Expanded(flex: 2, child: Column(children: [members, gap, actions])),
                                      ],
                                    )
                                  else ...[
                                    leadership,
                                    gap,
                                    members,
                                    gap,
                                    contact,
                                    gap,
                                    actions,
                                  ],
                                  SizedBox(height: context.bottomPadding),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    if (isDesktop) const AppFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (state.busy) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }
}

/// The active season's numbers (fund balance spans every season).
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final MessStatsEntity stats;

  @override
  Widget build(BuildContext context) {
    final c = context.customThemeColors;
    final tiles = [
      (context.local.members, '${stats.members}', Icons.groups_rounded, c.primaryColor),
      (context.local.totalMeals, MealFormatters.count(stats.totalMeals), Icons.restaurant_menu_rounded, c.warningColor),
      (context.local.mealRate, DashboardFormatters.taka(stats.mealRate), Icons.sell_rounded, c.secondaryColor),
      (context.local.totalCost, DashboardFormatters.taka(stats.totalCost), Icons.shopping_cart_rounded, c.errorColor),
      (context.local.deposits, DashboardFormatters.taka(stats.totalDeposit), Icons.account_balance_wallet_rounded, c.infoColor),
      (context.local.fundBalance, DashboardFormatters.taka(stats.fundBalance), Icons.savings_rounded, c.successColor),
    ];

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
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final (label, value, icon, accent) = tiles[index];
        return AnimatedEntrance(
          delay: Duration(milliseconds: 40 * index),
          child: StatCard(label: label, value: value, icon: icon, accent: accent),
        );
      },
    );
  }
}

/// Edit / transfer (for the roles allowed to) and leave, disabled while a
/// refresh or leave runs.
class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.state});

  final MessDetailsLoaded state;

  Future<void> _open(BuildContext context, String route) async {
    await context.push(route);
    // The details may have changed there.
    if (context.mounted) await _refresh(context);
  }

  Future<void> _leave(BuildContext context) async {
    final mess = state.mess;
    final cubit = context.read<MessDetailsCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.local.leaveMessConfirmTitle(mess.name)),
        content: Text(context.local.leaveMessConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(context.local.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.customThemeColors.errorColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.local.leave),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final success = context.local.leftMess(mess.name);
    final result = await cubit.leave();
    if (!context.mounted) return;
    if (result.left) {
      context.showSuccessSnackBar(success);
      context.go(AppRoutes.joinMess);
    } else if (result.error != null) {
      context.showErrorSnackBar(result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final mess = state.mess;
    final enabled = !state.busy;

    return MessSectionCard(
      title: context.local.messActions,
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          if (mess.canEdit)
            _ActionTile(
              icon: Icons.edit_rounded,
              title: context.local.editMessDetails,
              subtitle: context.local.editMessDetailsSubtitle,
              color: colors.primaryColor,
              onTap: enabled ? () => _open(context, AppRoutes.editMess) : null,
            ),
          if (mess.canTransfer)
            _ActionTile(
              icon: Icons.swap_horiz_rounded,
              title: context.local.transferLeadership,
              subtitle: context.local.transferLeadershipSubtitle,
              color: colors.secondaryColor,
              onTap: enabled ? () => _open(context, AppRoutes.messLeadership) : null,
            ),
          _ActionTile(
            icon: Icons.logout_rounded,
            title: context.local.leaveMess,
            subtitle: mess.canLeave ? context.local.leaveMessSubtitle : context.local.leaveMessBlocked,
            color: colors.errorColor,
            loading: state.leaving,
            onTap: enabled && mess.canLeave ? () => _leave(context) : null,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap, this.loading = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  /// Null disables (and dims) the tile.
  final VoidCallback? onTap;

  /// Shows a spinner in place of the chevron while the action runs.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Opacity(
      opacity: onTap == null && !loading ? 0.5 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeExtraSmall),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                child: Icon(icon, size: Dimensions.iconSizeDefault, color: color),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              if (loading) const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) else Icon(Icons.chevron_right_rounded, color: colors.textHintColor),
            ],
          ),
        ),
      ),
    );
  }
}
