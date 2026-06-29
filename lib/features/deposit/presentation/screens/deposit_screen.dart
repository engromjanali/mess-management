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
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_entity.dart';
import 'package:clean_boilerplate/features/deposit/presentation/bloc/deposit_bloc.dart';
import 'package:clean_boilerplate/features/deposit/presentation/bloc/deposit_event.dart';
import 'package:clean_boilerplate/features/deposit/presentation/bloc/deposit_state.dart';
import 'package:clean_boilerplate/features/deposit/presentation/bloc/deposit_view_mode.dart';
import 'package:clean_boilerplate/features/deposit/presentation/widgets/deposit_filter_bar.dart';
import 'package:clean_boilerplate/features/deposit/presentation/widgets/deposit_form_sheet.dart';
import 'package:clean_boilerplate/features/deposit/presentation/widgets/deposit_formatters.dart';
import 'package:clean_boilerplate/features/deposit/presentation/widgets/deposit_tile.dart';

/// Deposit screen.
///
/// * **Admin** — add / edit / delete deposits, and browse them by member
///   (incl. "all members") or by date (a single day, a custom range, or all
///   time).
/// * **User** — a read-only list of their own deposits.
class DepositScreen extends StatelessWidget {
  const DepositScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<RoleCubit>().state.isAdmin;
    return BlocProvider<DepositBloc>(
      create: (_) => getIt<DepositBloc>()..add(DepositEvent.started(isAdmin: isAdmin)),
      child: const _DepositView(),
    );
  }
}

class _DepositView extends StatelessWidget {
  const _DepositView();

  @override
  Widget build(BuildContext context) {
    // Re-load when the global role switcher flips between user / admin.
    return BlocListener<RoleCubit, UserRole>(
      listenWhen: (prev, curr) => prev != curr,
      listener: (context, role) => context.read<DepositBloc>().add(DepositEvent.started(isAdmin: role.isAdmin)),
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(leading: const HomeBackButton(), title: const Text('Deposits')),
        floatingActionButton: BlocBuilder<DepositBloc, DepositState>(
          builder: (context, state) {
            final canAdd = state.maybeWhen(loaded: (_, _, _, _, _, isAdmin, _, _, _) => isAdmin, orElse: () => false);
            if (!canAdd) return const SizedBox.shrink();
            return FloatingActionButton.extended(onPressed: () => _openAdd(context, state), icon: const Icon(Icons.add_rounded), label: const Text('Add deposit'));
          },
        ),
        body: BlocConsumer<DepositBloc, DepositState>(
          listener: (context, state) {
            state.maybeWhen(error: (message) => context.showErrorSnackBar(message), orElse: () {});
          },
          builder: (context, state) {
            return state.maybeWhen(
              loading: () => const Center(child: CircularProgressIndicator.adaptive()),
              error: (message) => _ErrorView(message: message),
              loaded: (mode, deposits, members, dateFilter, selectedDate, isAdmin, selectedMember, selectedRange, saving) => _DepositBody(
                mode: mode,
                deposits: deposits,
                members: members,
                dateFilter: dateFilter,
                selectedDate: selectedDate,
                isAdmin: isAdmin,
                selectedMember: selectedMember,
                selectedRange: selectedRange,
                saving: saving,
              ),
              orElse: () => const Center(child: CircularProgressIndicator.adaptive()),
            );
          },
        ),
      ),
    );
  }

  void _openAdd(BuildContext context, DepositState state) {
    final members = state.maybeWhen(loaded: (_, _, members, _, _, _, _, _, _) => members, orElse: () => const <DepositMemberEntity>[]);
    final bloc = context.read<DepositBloc>();
    showDepositFormSheet(
      context: context,
      members: members,
      onSave: ({required memberId, required amount, required date, note}) => bloc.add(DepositEvent.add(memberId: memberId, amount: amount, date: date, note: note)),
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
              onPressed: () => context.read<DepositBloc>().add(DepositEvent.started(isAdmin: isAdmin)),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepositBody extends StatelessWidget {
  const _DepositBody({
    required this.mode,
    required this.deposits,
    required this.members,
    required this.dateFilter,
    required this.selectedDate,
    required this.isAdmin,
    required this.selectedMember,
    required this.selectedRange,
    required this.saving,
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

  List<_Stat> _summary(BuildContext context) {
    final c = context.customThemeColors;
    final net = deposits.net;
    return [
      _Stat('Total Credit', DepositFormatters.taka(deposits.totalCredit), Icons.south_west_rounded, c.successColor),
      _Stat('Total Debit', DepositFormatters.taka(deposits.totalDebit), Icons.north_east_rounded, c.errorColor),
      _Stat('Net Balance', DepositFormatters.signedTaka(net), Icons.account_balance_wallet_rounded, net < 0 ? c.errorColor : c.primaryColor),
      _Stat('Entries', '${deposits.length}', Icons.receipt_long_rounded, c.infoColor),
    ];
  }

  void _onEdit(BuildContext context, DepositEntity deposit) {
    final bloc = context.read<DepositBloc>();
    showDepositFormSheet(
      context: context,
      members: members,
      existing: deposit,
      onSave: ({required memberId, required amount, required date, note}) => bloc.add(DepositEvent.update(id: deposit.id, amount: amount, date: date, note: note)),
    );
  }

  Future<void> _onDelete(BuildContext context, DepositEntity deposit) async {
    final bloc = context.read<DepositBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete deposit'),
        content: Text(
          'Delete this ${deposit.type.label.toLowerCase()} of '
          '${DepositFormatters.taka(deposit.absoluteAmount)} for '
          '${deposit.memberName}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(DepositEvent.delete(deposit.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show the member name whenever the list can span more than one member.
    final showMember = mode == DepositViewMode.byDate || (mode == DepositViewMode.byMember && selectedMember == null);

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
                    if (isAdmin) ...[
                      DepositFilterBar(mode: mode, members: members, selectedMember: selectedMember, dateFilter: dateFilter, selectedDate: selectedDate, selectedRange: selectedRange),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                    ],
                    SectionTitle(title: _listTitle(), icon: Icons.receipt_long_rounded),
                    if (deposits.isEmpty)
                      const _EmptyView()
                    else
                      _DepositList(deposits: deposits, showMember: showMember, isAdmin: isAdmin, onEdit: (d) => _onEdit(context, d), onDelete: (d) => _onDelete(context, d)),
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
    switch (mode) {
      case DepositViewMode.byMember:
        return selectedMember == null ? 'All members' : '${selectedMember!.name}\'s deposits';
      case DepositViewMode.byDate:
        switch (dateFilter) {
          case DepositDateFilter.allTime:
            return 'All deposits';
          case DepositDateFilter.day:
            return 'Deposits · ${DepositFormatters.shortDate(selectedDate)}';
          case DepositDateFilter.range:
            final r = selectedRange;
            return r == null ? 'All deposits' : 'Deposits · ${DepositFormatters.rangeLabel(r.start, r.end)}';
        }
      case DepositViewMode.mine:
        return 'My deposits';
    }
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
    final colors = context.customThemeColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraLarge32),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: Dimensions.iconSizeExtraLarge, color: colors.textHintColor),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text('No deposits yet', style: AppTextStyles.sfProRoundedMedium.copyWith(color: colors.textSecondaryColor)),
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
