import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/deposit/domain/entities/deposit_entity.dart';
import 'package:clean_boilerplate/features/deposit/presentation/bloc/deposit_bloc.dart';
import 'package:clean_boilerplate/features/deposit/presentation/bloc/deposit_event.dart';
import 'package:clean_boilerplate/features/deposit/presentation/bloc/deposit_view_mode.dart';
import 'package:clean_boilerplate/features/deposit/presentation/widgets/deposit_formatters.dart';

/// Compact, wrap-based filter controls for the admin deposit view.
///
/// Everything is laid out in a [Wrap] of small pill chips, so it collapses
/// onto multiple rows on a phone and stays inline on tablet / desktop:
///   `[By member] [By date]` then the contextual selector
///   (member picker, or `All time / Day / Range`).
class DepositFilterBar extends StatelessWidget {
  const DepositFilterBar({
    required this.mode,
    required this.members,
    required this.selectedMember,
    required this.dateFilter,
    required this.selectedDate,
    required this.selectedRange,
    super.key,
  });

  final DepositViewMode mode;
  final List<DepositMemberEntity> members;
  final DepositMemberEntity? selectedMember;
  final DepositDateFilter dateFilter;
  final DateTime selectedDate;
  final DateTimeRange? selectedRange;

  DepositBloc _bloc(BuildContext context) => context.read<DepositBloc>();

  Future<void> _pickDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(selectedDate.year - 2),
      lastDate: DateTime(selectedDate.year + 2),
    );
    if (picked != null && context.mounted) {
      _bloc(context).add(DepositEvent.selectDate(picked));
    }
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: selectedRange,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && context.mounted) {
      _bloc(context).add(
        DepositEvent.selectRange(start: picked.start, end: picked.end),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final byMember = mode == DepositViewMode.byMember;

    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Mode selector.
        _SelectChip(
          label: 'By member',
          icon: Icons.person_rounded,
          selected: byMember,
          onTap: () => _bloc(context)
              .add(const DepositEvent.changeMode(DepositViewMode.byMember)),
        ),
        _SelectChip(
          label: 'By date',
          icon: Icons.calendar_today_rounded,
          selected: !byMember,
          onTap: () => _bloc(context)
              .add(const DepositEvent.changeMode(DepositViewMode.byDate)),
        ),

        // A subtle divider between mode and its sub-filters.
        const _ChipDivider(),

        // Contextual sub-filter.
        if (byMember)
          _MemberMenuChip(
            members: members,
            selectedMember: selectedMember,
            onSelected: (id) =>
                _bloc(context).add(DepositEvent.selectMember(id)),
          )
        else ...[
          _SelectChip(
            label: 'All time',
            selected: dateFilter == DepositDateFilter.allTime,
            onTap: () => _bloc(context).add(
              const DepositEvent.changeDateFilter(DepositDateFilter.allTime),
            ),
          ),
          _SelectChip(
            label: dateFilter == DepositDateFilter.day
                ? DepositFormatters.shortDate(selectedDate)
                : 'Day',
            icon: Icons.event_rounded,
            selected: dateFilter == DepositDateFilter.day,
            onTap: () => _pickDay(context),
          ),
          _SelectChip(
            label: dateFilter == DepositDateFilter.range && selectedRange != null
                ? DepositFormatters.rangeLabel(
                    selectedRange!.start, selectedRange!.end)
                : 'Range',
            icon: Icons.date_range_rounded,
            selected: dateFilter == DepositDateFilter.range,
            onTap: () => _pickRange(context),
          ),
        ],
      ],
    );
  }
}

/// A small selectable pill.
class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final fg = selected ? colors.primaryColor : colors.textSecondaryColor;

    return Material(
      color: selected
          ? colors.primaryColor.withValues(alpha: 0.12)
          : colors.cardBackgroundColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            border: Border.all(
              color: selected ? colors.primaryColor : colors.borderColor,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: Dimensions.iconSizeSmall, color: fg),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              ],
              Text(
                label,
                style: AppTextStyles.sfProRoundedSemiBold.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pill that opens a member menu (incl. an "All members" entry).
class _MemberMenuChip extends StatelessWidget {
  const _MemberMenuChip({
    required this.members,
    required this.selectedMember,
    required this.onSelected,
  });

  final List<DepositMemberEntity> members;
  final DepositMemberEntity? selectedMember;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final label = selectedMember?.name ?? 'All members';

    return PopupMenuButton<String?>(
      tooltip: 'Filter by member',
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        // value defaults to null → the "all members" selection.
        const PopupMenuItem<String?>(
          child: Text('All members'),
        ),
        const PopupMenuDivider(),
        for (final m in members)
          PopupMenuItem<String?>(value: m.id, child: Text(m.name)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeDefault,
          vertical: Dimensions.paddingSizeSmall,
        ),
        decoration: BoxDecoration(
          color: colors.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          border: Border.all(color: colors.primaryColor, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_rounded,
                size: Dimensions.iconSizeSmall, color: colors.primaryColor),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sfProRoundedSemiBold.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: colors.primaryColor,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: Dimensions.iconSizeDefault, color: colors.primaryColor),
          ],
        ),
      ),
    );
  }
}

class _ChipDivider extends StatelessWidget {
  const _ChipDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeExtraSmall),
      color: colors.borderColor,
    );
  }
}
