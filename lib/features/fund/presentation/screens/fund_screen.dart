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
import 'package:clean_boilerplate/features/fund/domain/entities/fund_entity.dart';
import 'package:clean_boilerplate/features/fund/presentation/bloc/fund_bloc.dart';
import 'package:clean_boilerplate/features/fund/presentation/bloc/fund_date_filter.dart';
import 'package:clean_boilerplate/features/fund/presentation/bloc/fund_event.dart';
import 'package:clean_boilerplate/features/fund/presentation/bloc/fund_state.dart';
import 'package:clean_boilerplate/features/fund/presentation/widgets/fund_filter_bar.dart';
import 'package:clean_boilerplate/features/fund/presentation/widgets/fund_form_sheet.dart';
import 'package:clean_boilerplate/features/fund/presentation/widgets/fund_formatters.dart';
import 'package:clean_boilerplate/features/fund/presentation/widgets/fund_tile.dart';

/// Fund screen.
///
/// * **Admin** — add / edit / delete shared mess fund entries.
/// * **User** — a read-only list of fund entries.
///
/// Both can browse by date (a single day, a custom range, or all time).
class FundScreen extends StatelessWidget {
  const FundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<RoleCubit>().state.isAdmin;
    return BlocProvider<FundBloc>(
      create: (_) => getIt<FundBloc>()..add(FundEvent.started(isAdmin: isAdmin)),
      child: const _FundView(),
    );
  }
}

class _FundView extends StatelessWidget {
  const _FundView();

  @override
  Widget build(BuildContext context) {
    // Re-load when the global role switcher flips between user / admin.
    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, role) => context.read<FundBloc>().add(FundEvent.started(isAdmin: role.isAdmin)),
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(leading: const HomeBackButton(), title: const Text('Fund')),
        floatingActionButton: BlocBuilder<FundBloc, FundState>(
          builder: (context, state) {
            final canAdd = state.maybeWhen(loaded: (_, _, _, isAdmin, _, _) => isAdmin, orElse: () => false);
            if (!canAdd) return const SizedBox.shrink();
            return FloatingActionButton.extended(onPressed: () => _openAdd(context), icon: const Icon(Icons.add_rounded), label: const Text('Add fund'));
          },
        ),
        body: BlocConsumer<FundBloc, FundState>(
          listener: (context, state) {
            state.maybeWhen(error: (message) => context.showErrorSnackBar(message), orElse: () {});
          },
          builder: (context, state) {
            return state.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator.adaptive()),
              error: (message) => _ErrorView(message: message),
              loaded: (funds, dateFilter, selectedDate, isAdmin, selectedRange, saving) =>
                  _FundBody(funds: funds, dateFilter: dateFilter, selectedDate: selectedDate, isAdmin: isAdmin, selectedRange: selectedRange, saving: saving),
              orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
            );
          },
        ),
      ),
    );
  }

  void _openAdd(BuildContext context) {
    final bloc = context.read<FundBloc>();
    showFundFormSheet(
      context: context,
      onSave: ({required amount, required date, note}) => bloc.add(FundEvent.add(amount: amount, date: date, note: note)),
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
              onPressed: () => context.read<FundBloc>().add(FundEvent.started(isAdmin: isAdmin)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundBody extends StatelessWidget {
  const _FundBody({required this.funds, required this.dateFilter, required this.selectedDate, required this.isAdmin, required this.selectedRange, required this.saving});

  final List<FundEntity> funds;
  final FundDateFilter dateFilter;
  final DateTime selectedDate;
  final bool isAdmin;
  final DateTimeRange? selectedRange;
  final bool saving;

  List<_Stat> _summary(BuildContext context) {
    final c = context.customThemeColors;
    final net = funds.net;
    return [
      _Stat('Total Credit', FundFormatters.taka(funds.totalCredit), Icons.south_west_rounded, c.successColor),
      _Stat('Total Debit', FundFormatters.taka(funds.totalDebit), Icons.north_east_rounded, c.errorColor),
      _Stat('Net Balance', FundFormatters.signedTaka(net), Icons.savings_rounded, net < 0 ? c.errorColor : c.primaryColor),
      _Stat('Entries', '${funds.length}', Icons.receipt_long_rounded, c.infoColor),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete fund'),
        content: Text(
          'Delete this ${fund.type.label.toLowerCase()} of '
          '${FundFormatters.taka(fund.absoluteAmount)} on '
          '${FundFormatters.date(fund.date)}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(FundEvent.delete(fund.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SummaryGrid(stats: _summary(context)),
                    const SizedBox(height: Dimensions.paddingSizeLarge),
                    FundFilterBar(dateFilter: dateFilter, selectedDate: selectedDate, selectedRange: selectedRange),
                    const SizedBox(height: Dimensions.paddingSizeDefault),
                    SectionTitle(title: _listTitle(), icon: Icons.receipt_long_rounded),
                    if (funds.isEmpty) const _EmptyView() else _FundList(funds: funds, isAdmin: isAdmin, onEdit: (f) => _onEdit(context, f), onDelete: (f) => _onDelete(context, f)),
                    SizedBox(height: context.bottomPadding + 72),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (saving) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }

  String _listTitle() {
    switch (dateFilter) {
      case FundDateFilter.allTime:
        return 'All funds';
      case FundDateFilter.day:
        return 'Funds · ${FundFormatters.shortDate(selectedDate)}';
      case FundDateFilter.range:
        final r = selectedRange;
        return r == null ? 'All funds' : 'Funds · ${FundFormatters.rangeLabel(r.start, r.end)}';
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
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge32),
      child: Column(
        children: [
          Icon(Icons.savings_outlined, size: Dimensions.iconSizeExtraLarge, color: colors.textHintColor),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text('No fund entries yet', style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
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
