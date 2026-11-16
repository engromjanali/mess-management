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
import 'package:mess_pilot/core/widgets/home_back_button.dart';
import 'package:mess_pilot/core/widgets/pill_tab_bar.dart';
import 'package:mess_pilot/core/widgets/segmented_tab_bar.dart';

import 'package:mess_pilot/features/home/presentation/widgets/animated_entrance.dart';
import 'package:mess_pilot/features/home/presentation/widgets/dashboard_top_bar.dart';
import 'package:mess_pilot/features/home/presentation/widgets/section_title.dart';
import 'package:mess_pilot/core/widgets/stat_card.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/deposit/domain/entities/deposit_entity.dart';
import 'package:mess_pilot/features/deposit/presentation/bloc/deposit_bloc.dart';
import 'package:mess_pilot/features/deposit/presentation/bloc/deposit_event.dart';
import 'package:mess_pilot/features/deposit/presentation/bloc/deposit_state.dart';
import 'package:mess_pilot/features/deposit/presentation/bloc/deposit_view_mode.dart';
import 'package:mess_pilot/features/deposit/presentation/widgets/deposit_filter_bar.dart';
import 'package:mess_pilot/features/deposit/domain/entities/deposit_mess_summary_entity.dart';
import 'package:mess_pilot/features/deposit/presentation/widgets/deposit_form_sheet.dart';
import 'package:mess_pilot/features/deposit/presentation/widgets/deposit_mess_overview.dart';
import 'package:mess_pilot/features/deposit/presentation/widgets/deposit_formatters.dart';
import 'package:mess_pilot/features/deposit/presentation/widgets/deposit_tile.dart';

/// Deposit screen.
///
/// * **Manager / acting manager** — add / edit / delete deposits, and browse them by member
///   (incl. "all members") or by date (a single day, a custom range, or all
///   time). The mess overview, the filtered breakdown and the add form each
///   live in their own tab.
/// * **Member** — a read-only list of their own deposits.
class DepositScreen extends StatelessWidget {
  const DepositScreen({this.tab = DepositTab.overview, super.key});

  final DepositTab tab;

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<RoleCubit>().state.canManage;
    return BlocProvider<DepositBloc>(
      create: (_) => getIt<DepositBloc>()..add(DepositEvent.started(isAdmin: canManage)),
      child: _DepositView(initialTab: tab),
    );
  }
}

enum DepositTab { overview, breakdown, add }

class _DepositView extends StatefulWidget {
  const _DepositView({required this.initialTab});

  final DepositTab initialTab;

  @override
  State<_DepositView> createState() => _DepositViewState();
}

class _DepositViewState extends State<_DepositView> {
  late DepositTab _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant _DepositView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  void _onTabChanged(DepositTab tab) {
    switch (tab) {
      case DepositTab.overview:
        context.go(AppRoutes.deposits);
      case DepositTab.breakdown:
        context.go(AppRoutes.depositBreakdown);
      case DepositTab.add:
        context.go(AppRoutes.addDeposit);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);

    // Reload when the authenticated role changes.
    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, role) {
        context.go(AppRoutes.deposits);
        context.read<DepositBloc>().add(DepositEvent.started(isAdmin: role.canManage));
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
        appBar: showWebAppBar ? null : AppBar(leading: const HomeBackButton(), title: Text(context.local.deposits)),
        body: Column(
          children: [
            if (showWebAppBar) const DashboardTopBar(active: DashboardSection.deposits),
            Expanded(
              // Only this content area swaps while loading; the app bar / top
              // bar stay mounted.
              child: BlocConsumer<DepositBloc, DepositState>(
                listener: (context, state) {
                  state.maybeWhen(error: (message) => context.showErrorSnackBar(message), orElse: () {});
                },
                builder: (context, state) {
                  return state.maybeWhen(
                    loading: () => const Center(child: AppLoader()),
                    error: (message) => _ErrorView(message: message),
                    loaded: (mode, deposits, members, dateFilter, selectedDate, isAdmin, selectedMember, selectedRange, saving, isLoading, messSummary) {
                      return _LoadedContent(
                        mode: mode,
                        deposits: deposits,
                        members: members,
                        dateFilter: dateFilter,
                        selectedDate: selectedDate,
                        isAdmin: isAdmin,
                        selectedMember: selectedMember,
                        selectedRange: selectedRange,
                        saving: saving,
                        isLoading: isLoading,
                        messSummary: messSummary,
                        tab: isAdmin ? _tab : DepositTab.breakdown,
                        onTabChanged: _onTabChanged,
                        onSaved: () => context.go(AppRoutes.depositBreakdown),
                      );
                    },
                    orElse: () => const Center(child: AppLoader()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedContent extends StatelessWidget {
  const _LoadedContent({
    required this.mode,
    required this.deposits,
    required this.members,
    required this.dateFilter,
    required this.selectedDate,
    required this.isAdmin,
    required this.selectedMember,
    required this.selectedRange,
    required this.saving,
    required this.isLoading,
    required this.tab,
    required this.onTabChanged,
    required this.onSaved,
    this.messSummary,
  });

  final DepositViewMode mode;
  final List<DepositEntity> deposits;
  final List<DepositMemberEntity> members;
  final DepositDateFilter dateFilter;
  final DateTime selectedDate;
  final bool isAdmin;
  final DepositMemberEntity? selectedMember;
  final DateTimeRange? selectedRange;
  final bool saving;
  final bool isLoading;
  final DepositMessSummaryEntity? messSummary;
  final DepositTab tab;
  final ValueChanged<DepositTab> onTabChanged;
  final VoidCallback onSaved;

  /// Managers browse the overview, the filtered breakdown, or the add form.
  /// Members only ever see their read-only breakdown list.
  Widget _tabContent() {
    if (!isAdmin) {
      return _DepositBreakdownTab(
        mode: mode,
        deposits: deposits,
        members: members,
        dateFilter: dateFilter,
        selectedDate: selectedDate,
        isAdmin: isAdmin,
        selectedMember: selectedMember,
        selectedRange: selectedRange,
      );
    }
    switch (tab) {
      case DepositTab.overview:
        return _DepositOverviewTab(messSummary: messSummary);
      case DepositTab.breakdown:
        return _DepositBreakdownTab(
          mode: mode,
          deposits: deposits,
          members: members,
          dateFilter: dateFilter,
          selectedDate: selectedDate,
          isAdmin: isAdmin,
          selectedMember: selectedMember,
          selectedRange: selectedRange,
        );
      case DepositTab.add:
        return _AddDepositTab(members: members, onSaved: onSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    child: SegmentedTabBar<DepositTab>(
                      tabs: [
                        PillTab(value: DepositTab.overview, label: context.local.deposits),
                        PillTab(value: DepositTab.breakdown, label: context.local.uiDepositBreakdown),
                        PillTab(value: DepositTab.add, label: context.local.uiAddDeposit),
                      ],
                      selected: tab,
                      onChanged: onTabChanged,
                    ),
                  ),
                ),
              ),
            Expanded(child: _tabContent()),
          ],
        ),
        if (saving || isLoading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<RoleCubit>().state.canManage;
    return AppErrorState(error: message, onRetry: () => context.read<DepositBloc>().add(DepositEvent.started(isAdmin: canManage)));
  }
}

/// The "Deposits" tab — the manager's own totals, the mess-wide overview and
/// the per-member balance breakdown.
class _DepositOverviewTab extends StatelessWidget {
  const _DepositOverviewTab({this.messSummary});

  final DepositMessSummaryEntity? messSummary;

  @override
  Widget build(BuildContext context) {
    final summary = messSummary;
    return LayoutBuilder(
      builder: (context, viewportConstraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
          child: Column(
            mainAxisAlignment: (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
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
                        if (summary != null)
                          DepositMessOverview(summary: summary)
                        else
                          AppEmptyState(title: context.local.stateNoDeposits, icon: Icons.insights_outlined),
                        SizedBox(height: context.bottomPadding + Dimensions.paddingSizeExtraLarge),
                      ],
                    ),
                  ),
                ),
              ),
              if (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// The deposit breakdown tab — the filtered summary, filter bar and list.
class _DepositBreakdownTab extends StatefulWidget {
  const _DepositBreakdownTab({
    required this.mode,
    required this.deposits,
    required this.members,
    required this.dateFilter,
    required this.selectedDate,
    required this.isAdmin,
    required this.selectedMember,
    required this.selectedRange,
  });

  final DepositViewMode mode;
  final List<DepositEntity> deposits;
  final List<DepositMemberEntity> members;
  final DepositDateFilter dateFilter;
  final DateTime selectedDate;
  final bool isAdmin;
  final DepositMemberEntity? selectedMember;
  final DateTimeRange? selectedRange;

  @override
  State<_DepositBreakdownTab> createState() => _DepositBreakdownTabState();
}

class _DepositBreakdownTabState extends State<_DepositBreakdownTab> {
  final GlobalKey _measureKey = GlobalKey();
  double _filterHeight = 60;
  bool _measureQueued = false;

  List<_Stat> _summary(BuildContext context) {
    final c = context.customThemeColors;
    final net = widget.deposits.net;
    return [
      _Stat(context.local.totalCredit, DepositFormatters.taka(widget.deposits.totalCredit), Icons.south_west_rounded, c.successColor),
      _Stat(context.local.totalDebit, DepositFormatters.taka(widget.deposits.totalDebit), Icons.north_east_rounded, c.errorColor),
      _Stat(context.local.netBalance, DepositFormatters.signedTaka(net), Icons.account_balance_wallet_rounded, net < 0 ? c.errorColor : c.primaryColor),
      _Stat(context.local.entries, '${widget.deposits.length}', Icons.receipt_long_rounded, c.infoColor),
    ];
  }

  void _onEdit(BuildContext context, DepositEntity deposit) {
    final bloc = context.read<DepositBloc>();
    showDepositFormSheet(
      context: context,
      members: widget.members,
      existing: deposit,
      onSave: ({required memberId, required amount, required date, note}) => bloc.add(DepositEvent.update(id: deposit.id, amount: amount, date: date, note: note)),
    );
  }

  Future<void> _onDelete(BuildContext context, DepositEntity deposit) async {
    final bloc = context.read<DepositBloc>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.local.uiDeleteDeposit,
      message: context.local.uiDeleteDepositConfirmation(deposit.isCredit ? context.local.credit : context.local.debit, DepositFormatters.taka(deposit.absoluteAmount), deposit.memberName),
      confirmLabel: context.local.delete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed) {
      bloc.add(DepositEvent.delete(deposit.id));
    }
  }

  String _listTitle(BuildContext context) {
    switch (widget.mode) {
      case DepositViewMode.byMember:
        return widget.selectedMember == null ? context.local.uiAllMembers : context.local.uiMemberDeposits(widget.selectedMember!.name);
      case DepositViewMode.byDate:
        switch (widget.dateFilter) {
          case DepositDateFilter.allTime:
            return context.local.uiAllDeposits;
          case DepositDateFilter.day:
            return context.local.uiDepositsForDate(DepositFormatters.shortDate(widget.selectedDate));
          case DepositDateFilter.range:
            final r = widget.selectedRange;
            return r == null ? context.local.uiAllDeposits : context.local.uiDepositsForDate(DepositFormatters.rangeLabel(r.start, r.end));
        }
      case DepositViewMode.mine:
        return context.local.myDeposits;
    }
  }

  /// Measures the wrapped filter bar so the pinned header can take exactly the
  /// height the filters need on the current width and locale.
  void _measureFilterBar() {
    if (!widget.isAdmin || _measureQueued) return;
    _measureQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureQueued = false;
      if (!mounted) return;
      final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final height = box.size.height + Dimensions.paddingSizeDefault * 2;
      if ((height - _filterHeight).abs() > 0.5) setState(() => _filterHeight = height);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show the member name whenever the list can span more than one member.
    final showMember = widget.mode == DepositViewMode.byDate || (widget.mode == DepositViewMode.byMember && widget.selectedMember == null);
    final stats = _summary(context);
    final showFooter = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    _measureFilterBar();

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = (constraints.maxWidth < Dimensions.webMaxWidth ? constraints.maxWidth : Dimensions.webMaxWidth) - Dimensions.paddingSizeLarge * 2;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, widget.isAdmin ? 0 : Dimensions.paddingSizeLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.isAdmin) SectionTitle(title: context.local.filteredSummary, icon: Icons.filter_alt_outlined),
                              _SummaryGrid(stats: stats),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isAdmin)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _DepositFilterHeader(
                        height: _filterHeight,
                        mode: widget.mode,
                        members: widget.members,
                        selectedMember: widget.selectedMember,
                        dateFilter: widget.dateFilter,
                        selectedDate: widget.selectedDate,
                        selectedRange: widget.selectedRange,
                      ),
                    ),
                  SliverLayoutBuilder(
                    builder: (context, sliverConstraints) {
                      final remaining = sliverConstraints.viewportMainAxisExtent - sliverConstraints.precedingScrollExtent;
                      final list = Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SectionTitle(title: _listTitle(context), icon: Icons.receipt_long_rounded),
                                if (widget.deposits.isEmpty)
                                  const _EmptyView()
                                else
                                  _DepositList(
                                    deposits: widget.deposits,
                                    showMember: showMember,
                                    isAdmin: widget.isAdmin,
                                    onEdit: (d) => _onEdit(context, d),
                                    onDelete: (d) => _onDelete(context, d),
                                  ),
                                SizedBox(height: context.bottomPadding + Dimensions.paddingSizeExtraLarge),
                              ],
                            ),
                          ),
                        ),
                      );
                      if (!showFooter) return SliverToBoxAdapter(child: list);
                      return SliverToBoxAdapter(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: remaining > 0 ? remaining : 0.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [list, const AppFooter()],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (widget.isAdmin)
              Positioned(
                left: 0,
                top: 0,
                child: Offstage(
                  child: SizedBox(
                    width: contentWidth,
                    child: KeyedSubtree(
                      key: _measureKey,
                      child: DepositFilterBar(
                        mode: widget.mode,
                        members: widget.members,
                        selectedMember: widget.selectedMember,
                        dateFilter: widget.dateFilter,
                        selectedDate: widget.selectedDate,
                        selectedRange: widget.selectedRange,
                      ),
                    ),
                  ),
                ),
              ),
      ],
        );
      },
    );
  }
}

/// Pinned filter header: the filter controls stay at the top while the list
/// scrolls. Its height follows the measured wrap so the chips keep the same
/// layout they had in the page flow.
class _DepositFilterHeader extends SliverPersistentHeaderDelegate {
  _DepositFilterHeader({required this.height, required this.mode, required this.members, required this.selectedMember, required this.dateFilter, required this.selectedDate, required this.selectedRange});

  final double height;
  final DepositViewMode mode;
  final List<DepositMemberEntity> members;
  final DepositMemberEntity? selectedMember;
  final DepositDateFilter dateFilter;
  final DateTime selectedDate;
  final DateTimeRange? selectedRange;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final colors = context.customThemeColors;
    final pinned = overlapsContent || shrinkOffset > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: pinned ? context.theme.scaffoldBackgroundColor : context.theme.scaffoldBackgroundColor.withValues(alpha: 0),
        boxShadow: pinned ? [BoxShadow(color: colors.shadowColor, blurRadius: 8, offset: const Offset(0, 4))] : null,
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
                  child: DepositFilterBar(
                    mode: mode,
                    members: members,
                    selectedMember: selectedMember,
                    dateFilter: dateFilter,
                    selectedDate: selectedDate,
                    selectedRange: selectedRange,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DepositFilterHeader oldDelegate) => true;
}

/// The "Add deposit" tab — the same form used in the sheet, hosted inline.
class _AddDepositTab extends StatelessWidget {
  const _AddDepositTab({required this.members, required this.onSaved});

  final List<DepositMemberEntity> members;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<DepositBloc>();

    return LayoutBuilder(
      builder: (context, viewportConstraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
          child: Column(
            mainAxisAlignment: (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
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
                        DepositForm(
                          members: members,
                          inline: true,
                          showHeader: false,
                          popOnSave: false,
                          onCancel: onSaved,
                          onSave: ({required memberId, required amount, required date, note}) {
                            bloc.add(DepositEvent.add(memberId: memberId, amount: amount, date: date, note: note));
                            onSaved();
                          },
                        ),
                        SizedBox(height: context.bottomPadding + Dimensions.paddingSizeExtraLarge),
                      ],
                    ),
                  ),
                ),
              ),
              if (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive deposit list — a single column on phones, two balanced columns
/// once there's room (tablet / desktop).
class _DepositList extends StatelessWidget {
  const _DepositList({required this.deposits, required this.showMember, required this.isAdmin, required this.onEdit, required this.onDelete});

  final List<DepositEntity> deposits;
  final bool showMember;
  final bool isAdmin;
  final ValueChanged<DepositEntity> onEdit;
  final ValueChanged<DepositEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumn = constraints.maxWidth >= 720;
        final tiles = [
          for (var i = 0; i < deposits.length; i++)
            AnimatedEntrance(
              delay: Duration(milliseconds: 25 * i),
              child: DepositTile(deposit: deposits[i], showMember: showMember, showActions: isAdmin, onEdit: () => onEdit(deposits[i]), onDelete: () => onDelete(deposits[i])),
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
    return AppEmptyState(title: context.local.stateNoDeposits, icon: Icons.account_balance_wallet_outlined);
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
