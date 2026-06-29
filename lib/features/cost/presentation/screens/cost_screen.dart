import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/di/injection.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/core/extensions/overly_extensions.dart';
import 'package:clean_boilerplate/core/extensions/screen_matres_extensions.dart';
import 'package:clean_boilerplate/core/role/role_cubit.dart';
import 'package:clean_boilerplate/core/widgets/home_back_button.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/animated_entrance.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/section_title.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/stat_card.dart';
import 'package:clean_boilerplate/features/cost/domain/entities/cost_entity.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_bloc.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_event.dart';
import 'package:clean_boilerplate/features/cost/presentation/bloc/cost_state.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_entry_form.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_formatters.dart';
import 'package:clean_boilerplate/features/cost/presentation/widgets/cost_tile.dart';

/// Cost (bazar) screen.
///
/// * **Admin** — two tabs: *Bazar List* (browse, edit, delete) and
///   *Bazar Entry* (record a new bazar with multiple products).
/// * **User** — the read-only *Bazar List* only.
///
/// A "tap to see cost" banner masks every total until revealed.
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
  bool _showCost = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, role) {
        setState(() => _tab = _CostTab.list);
        context.read<CostBloc>().add(CostEvent.started(isAdmin: role.isAdmin));
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: const HomeBackButton(),
          title: const Text('Cost'),
          actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded), onPressed: () => context.read<CostBloc>().add(const CostEvent.refresh()))],
        ),
        body: BlocConsumer<CostBloc, CostState>(
          listener: (context, state) {
            state.maybeWhen(
              loaded: (costs, members, isAdmin, saving, justSaved) {
                if (justSaved) {
                  setState(() => _tab = _CostTab.list);
                  context.showSuccessSnackBar('Bazar entry saved');
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
              loaded: (costs, members, isAdmin, saving, _) {
                final tab = isAdmin ? _tab : _CostTab.list;
                return Stack(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
                        child: Column(
                          children: [
                            if (isAdmin)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge, 0),
                                child: _TabSwitch(tab: tab, onChanged: (t) => setState(() => _tab = t)),
                              ),
                            Expanded(
                              child: tab == _CostTab.list
                                  ? _ListTab(costs: costs, isAdmin: isAdmin, members: members, showCost: _showCost, onToggleCost: () => setState(() => _showCost = !_showCost))
                                  : _EntryTab(members: members),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (saving) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
                  ],
                );
              },
              orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
            );
          },
        ),
      ),
    );
  }
}

/// Segmented `Bazar List / Bazar Entry` switch.
class _TabSwitch extends StatelessWidget {
  const _TabSwitch({required this.tab, required this.onChanged});
  final _CostTab tab;
  final ValueChanged<_CostTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_CostTab>(
      segments: const [
        ButtonSegment(value: _CostTab.list, icon: Icon(Icons.format_list_numbered_rounded), label: Text('Bazar List')),
        ButtonSegment(value: _CostTab.entry, icon: Icon(Icons.edit_rounded), label: Text('Bazar Entry')),
      ],
      selected: {tab},
      showSelectedIcon: false,
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// List tab
// ─────────────────────────────────────────────────────────────────────────

class _ListTab extends StatelessWidget {
  const _ListTab({required this.costs, required this.isAdmin, required this.members, required this.showCost, required this.onToggleCost});

  final List<CostEntity> costs;
  final bool isAdmin;
  final List<CostMemberEntity> members;
  final bool showCost;
  final VoidCallback onToggleCost;

  String _mask(double v) => showCost ? CostFormatters.taka(v) : '৳ ••••';

  List<_Stat> _summary(BuildContext context) {
    final c = context.customThemeColors;
    final avg = costs.isEmpty ? 0.0 : costs.grandTotal / costs.length;
    return [
      _Stat('Total Cost', _mask(costs.grandTotal), Icons.shopping_cart_rounded, c.primaryColor),
      _Stat('Entries', '${costs.length}', Icons.receipt_long_rounded, c.infoColor),
      _Stat('Products', '${costs.totalItems}', Icons.inventory_2_rounded, c.secondaryColor),
      _Stat('Avg / Entry', _mask(avg), Icons.trending_up_rounded, c.successColor),
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
        title: const Text('Delete bazar entry'),
        content: Text(
          'Delete ${cost.personName}\'s bazar of '
          '${CostFormatters.taka(cost.total)} '
          '(${cost.itemCount} item${cost.itemCount == 1 ? '' : 's'})?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
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
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SummaryGrid(stats: _summary(context)),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            _CostBanner(showCost: showCost, onTap: onToggleCost),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            if (costs.isEmpty)
              const _EmptyView()
            else
              for (var i = 0; i < costs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                  child: AnimatedEntrance(
                    delay: Duration(milliseconds: 30 * i),
                    child: CostTile(cost: costs[i], index: i, maskCost: !showCost, showActions: isAdmin, onEdit: () => _onEdit(context, costs[i]), onDelete: () => _onDelete(context, costs[i])),
                  ),
                ),
            SizedBox(height: context.bottomPadding),
          ],
        ),
      ),
    );
  }
}

/// The "tap to see cost" reveal banner.
class _CostBanner extends StatelessWidget {
  const _CostBanner({required this.showCost, required this.onTap});
  final bool showCost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Material(
      color: colors.primaryColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeDefault + 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  showCost ? 'tap to hide Cost' : 'tap to see Cost',
                  style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white),
                ),
              ),
              Icon(showCost ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: Colors.white),
            ],
          ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionTitle(title: 'New bazar', icon: Icons.add_shopping_cart_rounded),
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
          'Edit bazar entry',
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
              label: const Text('Retry'),
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
          Text('No bazar entries yet', style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
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
