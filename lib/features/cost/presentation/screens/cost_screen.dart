import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:clean_boilerplate/core/helpers/responsive_helper.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/widgets/app_footer.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/core/widgets/pill_tab_bar.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:clean_boilerplate/features/auth/presentation/bloc/auth_state.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
import 'package:clean_boilerplate/core/widgets/stat_card.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_bloc.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_event.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_state.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_entry_form.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_formatters.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_tile.dart';

/// Cost (bazar) screen — the active season's shopping entries.
///
/// * **Admin** — two tabs: *Cost List* (browse, edit, delete) and
///   *Cost Entry* (record a new Cost with multiple products).
/// * **User** — the read-only *Cost List* only.
class CostScreen extends StatelessWidget {
  const CostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<RoleCubit>().state.isAdmin;
    return BlocProvider<CostBloc>(
      create: (_) => getIt<CostBloc>()..add(CostEvent.started(isAdmin: isAdmin)),
      child: const _CostView(),
    );
  }
}

enum _CostTab { list, entry }

class _CostView extends StatefulWidget {
  const _CostView();

  @override
  State<_CostView> createState() => _CostViewState();
}

class _CostViewState extends State<_CostView> {
  _CostTab _tab = _CostTab.list;

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);

    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, role) {
        setState(() => _tab = _CostTab.list);
        context.read<CostBloc>().add(CostEvent.started(isAdmin: role.isAdmin));
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
        appBar: showWebAppBar ? null : AppBar(
          leading: const HomeBackButton(),
          title: Text(context.local.cost),
          actions: [IconButton(tooltip: context.local.refresh, icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<CostBloc>().add(const CostEvent.refresh()))],
        ),
        body: showWebAppBar ? Column(children: [const _CostTopBar(), Expanded(child: _content())]) : _content(),
      ),
    );
  }

  /// The list / entry tabs for the current state (no top bar).
  Widget _content() {
    return BlocConsumer<CostBloc, CostState>(
      listener: (context, state) {
        state.maybeWhen(
          loaded: (costs, seasonName, members, isAdmin, saving, justSaved) {
            if (justSaved) {
              setState(() => _tab = _CostTab.list);
              context.showSuccessSnackBar(context.local.costSaved);
            }
          },
          error: (message) => context.showErrorSnackBar(message),
          orElse: () {},
        );
      },
      builder: (context, state) {
        return state.maybeWhen(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (message) => _ErrorView(message: message),
          loaded: (costs, seasonName, members, isAdmin, saving, _) {
            final tab = isAdmin ? _tab : _CostTab.list;
            return Stack(
              children: [
                Column(
                  children: [
                    if (isAdmin)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, 0),
                            child: PillTabBar<_CostTab>(
                              tabs: [PillTab(value: _CostTab.list, label: context.local.costList), PillTab(value: _CostTab.entry, label: context.local.costEntry)],
                              selected: tab,
                              onChanged: (t) => setState(() => _tab = t),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: tab == _CostTab.list
                          ? _ListTab(costs: costs, seasonName: seasonName, isAdmin: isAdmin, members: members)
                          : _EntryTab(members: members),
                    ),
                  ],
                ),
                if (saving) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
              ],
            );
          },
          orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
        );
      },
    );
  }
}

/// Desktop / big-tablet app bar, shown in every state (loading, error, loaded).
class _CostTopBar extends StatelessWidget {
  const _CostTopBar();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.maybeWhen(authenticated: (user) => user, orElse: () => null);
    return DashboardTopBar(
      userName: user?.name ?? context.local.roleUser,
      onProfileTap: () => Scaffold.of(context).openEndDrawer(),
      navItems: [
        DashboardNavItem(label: context.local.home, icon: Icons.home_rounded, onTap: () => context.go(AppRoutes.home)),
        DashboardNavItem(label: context.local.meals, icon: Icons.restaurant_rounded, onTap: () => context.go(AppRoutes.meals)),
        DashboardNavItem(label: context.local.deposits, icon: Icons.account_balance_wallet_rounded, onTap: () => context.go(AppRoutes.deposits)),
        DashboardNavItem(label: context.local.cost, icon: Icons.shopping_cart_rounded, active: true, onTap: () {}),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// List tab
// ─────────────────────────────────────────────────────────────────────────

class _ListTab extends StatelessWidget {
  const _ListTab({required this.costs, required this.seasonName, required this.isAdmin, required this.members});

  final List<CostEntity> costs;
  final String seasonName;
  final bool isAdmin;
  final List<CostMemberEntity> members;

  List<_Stat> _summary(BuildContext context) {
    final c = context.customThemeColors;
    final avg = costs.isEmpty ? 0.0 : costs.grandTotal / costs.length;
    return [
      _Stat(context.local.totalCost, CostFormatters.taka(costs.grandTotal), Icons.shopping_cart_rounded, c.primaryColor),
      _Stat(context.local.entries, '${costs.length}', Icons.receipt_long_rounded, c.infoColor),
      _Stat(context.local.products, '${costs.totalItems}', Icons.inventory_2_rounded, c.secondaryColor),
      _Stat(context.local.avgPerEntry, CostFormatters.taka(avg), Icons.trending_up_rounded, c.successColor),
    ];
  }

  void _onEdit(BuildContext context, CostEntity cost) {
    final bloc = context.read<CostBloc>();
    showCostEditSheet(
      context: context,
      members: members,
      existing: cost,
      onSubmit: ({required personId, required date, required items}) => bloc.add(CostEvent.update(id: cost.id, personId: personId, date: date, items: items)),
    );
  }

  Future<void> _onDelete(BuildContext context, CostEntity cost) async {
    final bloc = context.read<CostBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.local.deleteCost),
        content: Text(context.local.deleteCostConfirm(cost.personName, CostFormatters.taka(cost.total), cost.itemCount)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(context.local.cancel)),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: Text(context.local.delete)),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(CostEvent.delete(cost.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CostBloc>().add(const CostEvent.refresh());
        await Future<void>.delayed(const Duration(milliseconds: 600));
      },
      child: _CostTabScroll(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (seasonName.isNotEmpty) SectionTitle(title: context.local.seasonName(seasonName), icon: Icons.event_note_rounded),
            _SummaryGrid(stats: _summary(context)),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            if (costs.isEmpty)
              const _EmptyView()
            else
              for (var i = 0; i < costs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: AnimatedEntrance(
                    delay: Duration(milliseconds: 30 * i),
                    child: CostTile(cost: costs[i], index: i, maskCost: false, showActions: isAdmin, onEdit: () => _onEdit(context, costs[i]), onDelete: () => _onDelete(context, costs[i])),
                  ),
                ),
            SizedBox(height: context.bottomPadding),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Entry tab
// ─────────────────────────────────────────────────────────────────────────

class _EntryTab extends StatelessWidget {
  const _EntryTab({required this.members});
  final List<CostMemberEntity> members;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CostBloc>();
    return _CostTabScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(title: context.local.newCost, icon: Icons.add_shopping_cart_rounded),
          CostEntryForm(
            key: const ValueKey('cost-entry-form'),
            members: members,
            onSubmit: ({required personId, required date, required items}) => bloc.add(CostEvent.add(personId: personId, date: date, items: items)),
          ),
          SizedBox(height: context.bottomPadding),
        ],
      ),
    );
  }
}

/// Opens the edit form — a dialog on desktop / tablet, a bottom sheet on phone.
Future<void> showCostEditSheet({
  required BuildContext context,
  required List<CostMemberEntity> members,
  required CostEntity existing,
  required void Function({required String personId, required DateTime date, required List<CostItemEntity> items}) onSubmit,
}) {
  return context.showAdaptiveSheet<void>(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.local.editCost,
          style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge, color: context.customThemeColors.textPrimaryColor),
        ),
        const SizedBox(height: Dimensions.paddingSizeLarge),
        CostEntryForm(
          members: members,
          existing: existing,
          onSubmit: ({required personId, required date, required items}) {
            onSubmit(personId: personId, date: date, items: items);
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Shared
// ─────────────────────────────────────────────────────────────────────────

class _CostTabScroll extends StatelessWidget {
  const _CostTabScroll({required this.child, this.physics});

  final Widget child;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewportConstraints) => SingleChildScrollView(
        physics: physics,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
          child: Column(
            mainAxisAlignment: ResponsiveHelper.isDesktop(context) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                  child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge), child: child),
                ),
              ),
              if (ResponsiveHelper.isDesktop(context)) const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final isAdmin = context.read<RoleCubit>().state.isAdmin;
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
            ElevatedButton.icon(
              onPressed: () => context.read<CostBloc>().add(CostEvent.started(isAdmin: isAdmin)),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.local.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge32),
      child: Column(
        children: [
          Icon(Icons.shopping_cart_outlined, size: Dimensions.iconSizeExtraLarge, color: colors.textHintColor),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(context.local.noCostEntries, style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
        ],
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
        maxCrossAxisExtent: 200,
        mainAxisExtent: 168,
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
