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
        body: showWebAppBar ? Column(children: [const DashboardTopBar(active: DashboardSection.cost), Expanded(child: _content())]) : _content(),
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
                      Center(
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
                          ? _ListTab(costs: costs, seasonName: seasonName, isAdmin: isAdmin, members: members)
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
  const _ListTab({required this.costs, required this.seasonName, required this.isAdmin, required this.members});

  final List<CostEntity> costs;
  final String seasonName;
  final bool isAdmin;
  final List<CostMemberEntity> members;

  @override
  State<_ListTab> createState() => _ListTabState();
}

class _ListTabState extends State<_ListTab> {
  CostViewMode _mode = CostViewMode.byDate;
  CostDateFilter _dateFilter = CostDateFilter.allTime;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedRange;
  CostMemberEntity? _selectedMember;

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
            if (widget.seasonName.isNotEmpty) SectionTitle(title: context.local.seasonName(widget.seasonName), icon: Icons.event_note_rounded),
            _SummaryGrid(stats: _summary(context, filtered)),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            CostFilterBar(
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
            const SizedBox(height: Dimensions.paddingSizeLarge),
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
            mainAxisAlignment: (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)) ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                  child: Padding(padding: const EdgeInsets.all(Dimensions.paddingSizeLarge), child: child),
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
