import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mess_pilot/config/route/app_router.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/core/di/injection.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/extensions/overly_extensions.dart';
import 'package:mess_pilot/core/extensions/screen_matres_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/core/role/role_cubit.dart';
import 'package:mess_pilot/core/widgets/app_dialog.dart';
import 'package:mess_pilot/core/widgets/app_footer.dart';
import 'package:mess_pilot/core/widgets/app_page_scroll_view.dart';
import 'package:mess_pilot/core/widgets/home_back_button.dart';
import 'package:mess_pilot/core/widgets/pill_tab_bar.dart';
import 'package:mess_pilot/core/widgets/segmented_tab_bar.dart';
import 'package:mess_pilot/core/widgets/web_page_title_bar.dart';

import 'package:mess_pilot/features/home/presentation/widgets/animated_entrance.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/section_title.dart';
import 'package:mess_pilot/core/widgets/stat_card.dart';
import 'package:mess_pilot/core/widgets/stat_card_slider.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/fund/domain/entities/fund_entity.dart';
import 'package:mess_pilot/features/fund/presentation/bloc/fund_bloc.dart';
import 'package:mess_pilot/features/fund/presentation/bloc/fund_date_filter.dart';
import 'package:mess_pilot/features/fund/presentation/bloc/fund_event.dart';
import 'package:mess_pilot/features/fund/presentation/bloc/fund_state.dart';
import 'package:mess_pilot/features/fund/presentation/widgets/fund_filter_bar.dart';
import 'package:mess_pilot/features/fund/presentation/widgets/fund_form_sheet.dart';
import 'package:mess_pilot/features/fund/presentation/widgets/fund_formatters.dart';
import 'package:mess_pilot/features/fund/presentation/widgets/fund_tile.dart';

/// Fund screen — the shared mess fund (all seasons of the mess).
///
/// * **Manager / acting manager** — add / edit / delete fund entries.
/// * **User** — a read-only list of the same entries.
///
/// Both can browse by date (a single day, a custom range, or all time).
class FundScreen extends StatelessWidget {
  const FundScreen({this.showAddTab = false, super.key});

  final bool showAddTab;

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<RoleCubit>().state.canManage;
    return BlocProvider<FundBloc>(
      create: (_) => getIt<FundBloc>()..add(FundEvent.started(isAdmin: canManage)),
      child: _FundView(showAddTab: showAddTab),
    );
  }
}

enum _FundTab { funds, add }

class _FundView extends StatefulWidget {
  const _FundView({required this.showAddTab});

  final bool showAddTab;

  @override
  State<_FundView> createState() => _FundViewState();
}

class _FundViewState extends State<_FundView> {
  late _FundTab _tab;
  final _summaryRowController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tab = widget.showAddTab ? _FundTab.add : _FundTab.funds;
  }

  @override
  void didUpdateWidget(covariant _FundView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showAddTab != widget.showAddTab) _tab = widget.showAddTab ? _FundTab.add : _FundTab.funds;
  }

  @override
  void dispose() {
    _summaryRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);

    final content = BlocConsumer<FundBloc, FundState>(
      listener: (context, state) {
        state.maybeWhen(error: (message) => context.showErrorSnackBar(message), orElse: () {});
      },
      builder: (context, state) {
        return state.maybeWhen(
          loading: () => const Center(child: AppLoader()),
          error: (message) => _ErrorView(message: message),
          loaded: (funds, dateFilter, selectedDate, isAdmin, selectedRange, saving) => isAdmin
              ? Column(
                  children: [
                    Align(alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, 0),
                          child: SegmentedTabBar<_FundTab>(
                            tabs: [
                              PillTab(value: _FundTab.funds, label: context.local.fund),
                              PillTab(value: _FundTab.add, label: context.local.add),
                            ],
                            selected: _tab,
                            onChanged: (value) => context.go(value == _FundTab.add ? AppRoutes.addFund : AppRoutes.funds),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _tab == _FundTab.funds
                          ? _FundBody(funds: funds, dateFilter: dateFilter, selectedDate: selectedDate, isAdmin: isAdmin, selectedRange: selectedRange, saving: saving, summaryRowController: _summaryRowController)
                          : _AddFundTab(onSaved: _onSaved),
                    ),
                  ],
                )
              : _FundBody(funds: funds, dateFilter: dateFilter, selectedDate: selectedDate, isAdmin: isAdmin, selectedRange: selectedRange, saving: saving, summaryRowController: _summaryRowController),
          orElse: () => const Center(child: AppLoader()),
        );
      },
    );

    // Reload when the authenticated role changes.
    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, role) => context.read<FundBloc>().add(FundEvent.started(isAdmin: role.canManage)),
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
        appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.fund)),
        body: Column(
          children: [
            // Single fixed-type slot so crossing the responsive breakpoint
            // never remounts the content subtree (tab/form/scroll state).
            showWebAppBar
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DashboardTopBar(),
                      WebPageTitleBar(title: context.local.fund),
                    ],
                  )
                : const SizedBox.shrink(),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  void _onSaved() {
    if (!mounted) return;
    context.go(AppRoutes.funds);
  }
}

class _AddFundTab extends StatelessWidget {
  const _AddFundTab({required this.onSaved});

  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FundBloc>();
    return AppPageScrollView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      maxWidth: 680,
      child: FundForm(
        embedded: true,
        onSave: ({required amount, required date, note}) => bloc.add(FundEvent.add(amount: amount, date: date, note: note)),
        onSaved: onSaved,
      ),
    );
  }
}



class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<RoleCubit>().state.canManage;
    return AppErrorState(error: message, onRetry: () => context.read<FundBloc>().add(FundEvent.started(isAdmin: canManage)));
  }
}

class _FundBody extends StatelessWidget {
  const _FundBody({required this.funds, required this.dateFilter, required this.selectedDate, required this.isAdmin, required this.selectedRange, required this.saving, required this.summaryRowController});

  final List<FundEntity> funds;
  final FundDateFilter dateFilter;
  final DateTime selectedDate;
  final bool isAdmin;
  final DateTimeRange? selectedRange;
  final ScrollController summaryRowController;
  final bool saving;

  List<_Stat> _summary(BuildContext context) {
    final c = context.customThemeColors;
    final net = funds.net;
    return [
      _Stat(context.local.totalCredit, FundFormatters.taka(funds.totalCredit), Icons.south_west_rounded, c.successColor),
      _Stat(context.local.totalDebit, FundFormatters.taka(funds.totalDebit), Icons.north_east_rounded, c.errorColor),
      _Stat(context.local.netBalance, FundFormatters.signedTaka(net), Icons.savings_rounded, net < 0 ? c.errorColor : c.primaryColor),
      _Stat(context.local.entries, '${funds.length}', Icons.receipt_long_rounded, c.infoColor),
    ];
  }

  void _onEdit(BuildContext context, FundEntity fund) {
    final bloc = context.read<FundBloc>();
    showFundFormSheet(
      context: context,
      existing: fund,
      onSave: ({required amount, required date, note}) => bloc.add(FundEvent.update(id: fund.id, amount: amount, date: date, note: note)),
    );
  }

  Future<void> _onDelete(BuildContext context, FundEntity fund) async {
    final bloc = context.read<FundBloc>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.local.deleteFund,
      message: context.local.deleteFundConfirm(
        (fund.isCredit ? context.local.credit : context.local.debit).toLowerCase(),
        FundFormatters.taka(fund.absoluteAmount),
        FundFormatters.date(fund.date),
      ),
      confirmLabel: context.local.delete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed) {
      bloc.add(FundEvent.delete(fund.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, viewportConstraints) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Body is at least 105% of the viewport when the footer shows,
                // so the footer never peeks into the first screen.
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: showWebAppBar ? viewportConstraints.maxHeight : viewportConstraints.maxHeight),
                  child: Align(alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                      child: Padding(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionTitle(
                              title: context.local.fundSummary,
                              icon: Icons.insights_rounded,
                              trailing: StatRowScrollArrows(controller: summaryRowController, strideBuilder: (viewport) => StatCardSlider.strideFor(context, viewport, maxCardWidth: 200)),
                            ),
                            _SummaryGrid(stats: _summary(context), controller: summaryRowController),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            FundFilterBar(dateFilter: dateFilter, selectedDate: selectedDate, selectedRange: selectedRange),
                            const SizedBox(height: Dimensions.paddingSizeDefault),
                            SectionTitle(title: _listTitle(context), icon: Icons.receipt_long_rounded),
                            if (funds.isEmpty) const _EmptyView() else _FundList(funds: funds, isAdmin: isAdmin, onEdit: (f) => _onEdit(context, f), onDelete: (f) => _onDelete(context, f)),
                            SizedBox(height: context.bottomPadding + 72),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (showWebAppBar) const AppFooter(),
              ],
            ),
          ),
        ),
        if (saving) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }

  String _listTitle(BuildContext context) {
    switch (dateFilter) {
      case FundDateFilter.allTime:
        return context.local.allFunds;
      case FundDateFilter.day:
        return context.local.fundsInPeriod(FundFormatters.shortDate(selectedDate));
      case FundDateFilter.range:
        final r = selectedRange;
        return r == null ? context.local.allFunds : context.local.fundsInPeriod(FundFormatters.rangeLabel(r.start, r.end));
    }
  }
}

/// Responsive fund list — a single column on phones, two balanced columns
/// once there's room (tablet / desktop).
class _FundList extends StatelessWidget {
  const _FundList({required this.funds, required this.isAdmin, required this.onEdit, required this.onDelete});

  final List<FundEntity> funds;
  final bool isAdmin;
  final ValueChanged<FundEntity> onEdit;
  final ValueChanged<FundEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 720;
        final tiles = [
          for (var i = 0; i < funds.length; i++)
            AnimatedEntrance(
              delay: Duration(milliseconds: 25 * i),
              child: FundTile(fund: funds[i], showActions: isAdmin, onEdit: () => onEdit(funds[i]), onDelete: () => onDelete(funds[i])),
            ),
        ];

        if (!twoColumn) {
          return Column(
            children: [
              for (final tile in tiles)
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: tile,
                ),
            ],
          );
        }

        final left = <Widget>[];
        final right = <Widget>[];
        for (var i = 0; i < tiles.length; i++) {
          (i.isEven ? left : right).add(
            Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
              child: tiles[i],
            ),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: left)),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(child: Column(children: right)),
          ],
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(title: context.local.noFundEntries, icon: Icons.savings_outlined);
  }
}

/// Width-adaptive summary metric grid (reuses the dashboard's [StatCard]).
class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.stats, required this.controller});
  final List<_Stat> stats;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return StatCardSlider(
      maxCardWidth: 200,
      regularExtent: 168,
      controller: controller,
      overlayArrows: false,
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
