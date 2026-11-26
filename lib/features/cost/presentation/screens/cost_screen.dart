import 'package:mess_pilot/core/widgets/app_state_view.dart';
import 'package:mess_pilot/core/widgets/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
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
import 'package:mess_pilot/core/widgets/stat_card_slider.dart';
import 'package:mess_pilot/features/home/presentation/widgets/web_profile_drawer.dart';
import 'package:mess_pilot/features/cost/domain/entities/cost_entity.dart';
import 'package:mess_pilot/features/cost/presentation/bloc/cost_bloc.dart';
import 'package:mess_pilot/features/cost/presentation/bloc/cost_event.dart';
import 'package:mess_pilot/features/cost/presentation/bloc/cost_state.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mess_pilot/features/auth/presentation/bloc/auth_state.dart';
import 'package:mess_pilot/features/cost/presentation/widgets/cost_entry_form.dart';
import 'package:mess_pilot/features/cost/presentation/widgets/cost_filter_bar.dart';
import 'package:mess_pilot/features/cost/presentation/widgets/cost_formatters.dart';
import 'package:mess_pilot/features/cost/presentation/widgets/cost_tile.dart';

/// Cost (bazar) screen — the active season's shopping entries.
///
/// * **Manager / acting manager** — two tabs: *Cost List* (browse, edit, delete) and
///   *Cost Entry* (record a new Cost with multiple products).
/// * **Member** — the read-only *Cost List* only.
class CostScreen extends StatelessWidget {
  const CostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<RoleCubit>().state.canManage;
    return BlocProvider<CostBloc>(
      create: (_) => getIt<CostBloc>()..add(CostEvent.started(isAdmin: canManage)),
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
  final _summaryRowController = ScrollController();

  @override
  void dispose() {
    _summaryRowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);

    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, role) {
        setState(() => _tab = _CostTab.list);
        context.read<CostBloc>().add(CostEvent.started(isAdmin: role.canManage));
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
        appBar: showWebAppBar ? null : AppBar(
          leading: const HomeBackButton(),
          title: Text(context.local.cost),
          actions: [IconButton(tooltip: context.local.refresh, icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<CostBloc>().add(const CostEvent.refresh()))],
        ),
        body: Column(
          children: [
            // Single fixed-type slot so crossing the responsive breakpoint
            // never remounts the content subtree (tab/filter/form state).
            showWebAppBar ? const DashboardTopBar(active: DashboardSection.cost) : const SizedBox.shrink(),
            Expanded(child: _content()),
          ],
        ),
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
          loading: () => const Center(child: AppLoader()),
          error: (message) => _ErrorView(message: message),
          loaded: (costs, seasonName, members, isAdmin, saving, _) {
            final tab = isAdmin ? _tab : _CostTab.list;
            return Stack(
              children: [
                Column(
                  children: [
                    if (isAdmin)
                      Align(alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, 0),
                            child: SegmentedTabBar<_CostTab>(
                              tabs: [PillTab(value: _CostTab.list, label: context.local.costList), PillTab(value: _CostTab.entry, label: context.local.costEntry)],
                              selected: tab,
                              onChanged: (t) => setState(() => _tab = t),
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: tab == _CostTab.list
                          ? _ListTab(costs: costs, seasonName: seasonName, isAdmin: isAdmin, members: members, summaryRowController: _summaryRowController)
                          : _EntryTab(members: members),
                    ),
                  ],
                ),
                if (saving) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
              ],
            );
          },
          orElse: () => const Center(child: AppLoader()),
        );
      },
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────
// List tab
// ─────────────────────────────────────────────────────────────────────────

class _ListTab extends StatefulWidget {
  const _ListTab({required this.costs, required this.seasonName, required this.isAdmin, required this.members, required this.summaryRowController});

  final List<CostEntity> costs;
  final String seasonName;
  final bool isAdmin;
  final List<CostMemberEntity> members;
  final ScrollController summaryRowController;

  @override
  State<_ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<_ListTab> {
  CostViewMode _mode = CostViewMode.byDate;
  CostDateFilter _dateFilter = CostDateFilter.allTime;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedRange;
  CostMemberEntity? _selectedMember;
  final GlobalKey _measureKey = GlobalKey();
  double _filterHeight = 84;
  bool _measureQueued = false;

  void _measureFilterBar() {
    if (_measureQueued) return;
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

  List<CostMemberEntity> _resolvedMembers() {
    if (widget.members.isNotEmpty) return widget.members;
    final map = <String, CostMemberEntity>{};
    for (final c in widget.costs) {
      if (c.personId.isNotEmpty && !map.containsKey(c.personId)) {
        map[c.personId] = CostMemberEntity(id: c.personId, name: c.personName);
      }
    }
    return map.values.toList();
  }

  List<CostEntity> _filteredCosts() {
    final user = context.read<AuthBloc>().state.maybeWhen(authenticated: (u) => u, orElse: () => null);

    return widget.costs.where((cost) {
      switch (_mode) {
        case CostViewMode.byMember:
          if (_selectedMember != null) {
            if (cost.personId != _selectedMember!.id && cost.personName.toLowerCase() != _selectedMember!.name.toLowerCase()) {
              return false;
            }
          }
          return true;

        case CostViewMode.byDate:
          switch (_dateFilter) {
            case CostDateFilter.allTime:
              return true;
            case CostDateFilter.day:
              return cost.date.year == _selectedDate.year &&
                  cost.date.month == _selectedDate.month &&
                  cost.date.day == _selectedDate.day;
            case CostDateFilter.range:
              if (_selectedRange == null) return true;
              final start = DateTime(_selectedRange!.start.year, _selectedRange!.start.month, _selectedRange!.start.day);
              final end = DateTime(_selectedRange!.end.year, _selectedRange!.end.month, _selectedRange!.end.day, 23, 59, 59);
              return !cost.date.isBefore(start) && !cost.date.isAfter(end);
          }

        case CostViewMode.mine:
          if (user == null) return true;
          return cost.personId == user.id || cost.personName.toLowerCase() == user.name.toLowerCase();
      }
    }).toList();
  }

  List<_Stat> _summary(BuildContext context, List<CostEntity> filtered) {
    final c = context.customThemeColors;
    final avg = filtered.isEmpty ? 0.0 : filtered.grandTotal / filtered.length;
    return [
      _Stat(context.local.totalCost, CostFormatters.taka(filtered.grandTotal), Icons.shopping_cart_rounded, c.primaryColor),
      _Stat(context.local.entries, '${filtered.length}', Icons.receipt_long_rounded, c.infoColor),
      _Stat(context.local.products, '${filtered.totalItems}', Icons.inventory_2_rounded, c.secondaryColor),
      _Stat(context.local.avgPerEntry, CostFormatters.taka(avg), Icons.trending_up_rounded, c.successColor),
    ];
  }

  void _onEdit(BuildContext context, CostEntity cost) {
    final bloc = context.read<CostBloc>();
    showCostEditSheet(
      context: context,
      members: widget.members,
      existing: cost,
      onSubmit: ({required personId, required date, required items}) => bloc.add(CostEvent.update(id: cost.id, personId: personId, date: date, items: items)),
    );
  }

  Future<void> _onDelete(BuildContext context, CostEntity cost) async {
    final bloc = context.read<CostBloc>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: context.local.deleteCost,
      message: context.local.deleteCostConfirm(cost.personName, CostFormatters.taka(cost.total), cost.itemCount),
      confirmLabel: context.local.delete,
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed) {
      bloc.add(CostEvent.delete(cost.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCosts();
    final members = _resolvedMembers();
    final showFooter = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);
    _measureFilterBar();

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = (constraints.maxWidth < Dimensions.webMaxWidth ? constraints.maxWidth : Dimensions.webMaxWidth) - Dimensions.paddingSizeLarge * 2;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<CostBloc>().add(const CostEvent.refresh());
            await Future<void>.delayed(const Duration(milliseconds: 600));
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Align(alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (widget.seasonName.isNotEmpty) SectionTitle(title: context.local.seasonName(widget.seasonName), icon: Icons.event_note_rounded, trailing: StatRowScrollArrows(controller: widget.summaryRowController, strideBuilder: (viewport) => StatCardSlider.strideFor(context, viewport, maxCardWidth: 200))),
                                _SummaryGrid(stats: _summary(context, filtered), controller: widget.summaryRowController),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _CostFilterHeader(
                        height: _filterHeight,
                        mode: _mode,
                        members: members,
                        selectedMember: _selectedMember,
                        dateFilter: _dateFilter,
                        selectedDate: _selectedDate,
                        selectedRange: _selectedRange,
                        onModeChanged: (m) => setState(() => _mode = m),
                        onMemberChanged: (m) => setState(() => _selectedMember = m),
                        onDateFilterChanged: (d) => setState(() => _dateFilter = d),
                        onDateChanged: (d) => setState(() {
                          _selectedDate = d;
                          _dateFilter = CostDateFilter.day;
                        }),
                        onRangeChanged: (r) => setState(() {
                          _selectedRange = r;
                          _dateFilter = CostDateFilter.range;
                        }),
                      ),
                    ),
                    SliverLayoutBuilder(
                      builder: (context, sliverConstraints) {
                        final remaining = sliverConstraints.viewportMainAxisExtent - sliverConstraints.precedingScrollExtent;
                        final list = Align(alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeDefault),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (filtered.isEmpty)
                                    const _EmptyView()
                                  else
                                    for (var i = 0; i < filtered.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                                        child: AnimatedEntrance(
                                          delay: Duration(milliseconds: 30 * i),
                                          child: CostTile(cost: filtered[i], index: i, maskCost: false, showActions: widget.isAdmin, onEdit: () => _onEdit(context, filtered[i]), onDelete: () => _onDelete(context, filtered[i])),
                                        ),
                                      ),
                                  SizedBox(height: context.bottomPadding),
                                ],
                              ),
                            ),
                          ),
                        );
                        if (!showFooter) return SliverToBoxAdapter(child: list);
                        return SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(minHeight: remaining),
                                child: list,
                              ),
                              const AppFooter(),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: Offstage(
                  child: SizedBox(
                    width: contentWidth,
                    child: KeyedSubtree(
                      key: _measureKey,
                      child: CostFilterBar(
                        mode: _mode,
                        members: members,
                        selectedMember: _selectedMember,
                        dateFilter: _dateFilter,
                        selectedDate: _selectedDate,
                        selectedRange: _selectedRange,
                        onModeChanged: (_) {},
                        onMemberChanged: (_) {},
                        onDateFilterChanged: (_) {},
                        onDateChanged: (_) {},
                        onRangeChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pinned filter header: the filter controls stay at the top while the list
/// scrolls. Its height follows the measured wrap so the chips keep the same
/// layout they had in the page flow.
class _CostFilterHeader extends SliverPersistentHeaderDelegate {
  _CostFilterHeader({
    required this.height,
    required this.mode,
    required this.members,
    required this.selectedMember,
    required this.dateFilter,
    required this.selectedDate,
    required this.selectedRange,
    required this.onModeChanged,
    required this.onMemberChanged,
    required this.onDateFilterChanged,
    required this.onDateChanged,
    required this.onRangeChanged,
  });

  final double height;
  final CostViewMode mode;
  final List<CostMemberEntity> members;
  final CostMemberEntity? selectedMember;
  final CostDateFilter dateFilter;
  final DateTime selectedDate;
  final DateTimeRange? selectedRange;
  final ValueChanged<CostViewMode> onModeChanged;
  final ValueChanged<CostMemberEntity?> onMemberChanged;
  final ValueChanged<CostDateFilter> onDateFilterChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<DateTimeRange> onRangeChanged;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final pinned = overlapsContent || shrinkOffset > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: pinned ? context.theme.scaffoldBackgroundColor : context.theme.scaffoldBackgroundColor.withValues(alpha: 0),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: Align(alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
              child: SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault),
                  child: CostFilterBar(
                    mode: mode,
                    members: members,
                    selectedMember: selectedMember,
                    dateFilter: dateFilter,
                    selectedDate: selectedDate,
                    selectedRange: selectedRange,
                    onModeChanged: onModeChanged,
                    onMemberChanged: onMemberChanged,
                    onDateFilterChanged: onDateFilterChanged,
                    onDateChanged: onDateChanged,
                    onRangeChanged: onRangeChanged,
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
  bool shouldRebuild(covariant _CostFilterHeader oldDelegate) => true;
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
  const _CostTabScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewportConstraints) {
        final showFooter = (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context));
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: showFooter ? viewportConstraints.maxHeight : viewportConstraints.maxHeight),
                child: Align(alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                    child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge), child: child),
                  ),
                ),
              ),
              if (showFooter) const AppFooter(),
            ],
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final canManage = context.read<RoleCubit>().state.canManage;
    return AppErrorState(error: message, onRetry: () => context.read<CostBloc>().add(CostEvent.started(isAdmin: canManage)));
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(title: context.local.noCostEntries, icon: Icons.shopping_cart_outlined);
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
