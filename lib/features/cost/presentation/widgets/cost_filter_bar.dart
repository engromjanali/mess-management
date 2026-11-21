import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:mess_pilot/features/cost/domain/entities/cost_entity.dart';
import 'package:mess_pilot/features/cost/presentation/widgets/cost_formatters.dart';

enum CostViewMode { byDate, byMember, mine }

enum CostDateFilter { allTime, day, range }

/// Compact filter controls for the cost view.
///
/// Supports filtering by date (all time, single day, date range),
/// by member, and by "mine".
class CostFilterBar extends StatelessWidget {
  const CostFilterBar({
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
    super.key,
  });

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

  Future<void> _pickDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en'),
      initialDate: selectedDate,
      firstDate: DateTime(selectedDate.year - 2),
      lastDate: DateTime(selectedDate.year + 2),
    );
    if (picked != null && context.mounted) {
      onDateChanged(picked);
    }
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      locale: const Locale('en'),
      initialDateRange: selectedRange,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null && context.mounted) {
      onRangeChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final byMember = mode == CostViewMode.byMember;
    final byDate = mode == CostViewMode.byDate;

    final chips = <Widget>[
      // Mode selector
      _SelectChip(
        label: context.local.uiByDate,
        icon: Icons.calendar_today_rounded,
        selected: byDate,
        onTap: () => onModeChanged(CostViewMode.byDate),
      ),
      _SelectChip(
        label: context.local.uiByMember,
        icon: Icons.person_rounded,
        selected: byMember,
        onTap: () => onModeChanged(CostViewMode.byMember),
      ),
      _SelectChip(
        label: context.local.mine,
        icon: Icons.account_circle_outlined,
        selected: mode == CostViewMode.mine,
        onTap: () => onModeChanged(CostViewMode.mine),
      ),

      if (byMember || byDate) const _ChipDivider(),

      // Contextual sub-filters
      if (byMember)
        _MemberMenuChip(
          members: members,
          selectedMember: selectedMember,
          onSelected: onMemberChanged,
        )
      else if (byDate) ...[
        _SelectChip(
          label: context.local.allTime,
          selected: dateFilter == CostDateFilter.allTime,
          onTap: () => onDateFilterChanged(CostDateFilter.allTime),
        ),
        _SelectChip(
          label: dateFilter == CostDateFilter.day ? CostFormatters.shortDate(selectedDate) : context.local.day,
          icon: Icons.event_rounded,
          selected: dateFilter == CostDateFilter.day,
          onTap: () => _pickDay(context),
        ),
        _SelectChip(
          label: dateFilter == CostDateFilter.range && selectedRange != null
              ? CostFormatters.rangeLabel(selectedRange!.start, selectedRange!.end)
              : context.local.range,
          icon: Icons.date_range_rounded,
          selected: dateFilter == CostDateFilter.range,
          onTap: () => _pickRange(context),
        ),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= ResponsiveHelper.mobile) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  if (i > 0) const SizedBox(width: Dimensions.paddingSizeSmall),
                  chips[i],
                ],
              ],
            ),
          );
        }
        return Wrap(
          spacing: Dimensions.paddingSizeSmall,
          runSpacing: Dimensions.paddingSizeSmall,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: chips,
        );
      },
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({required this.label, required this.selected, required this.onTap, this.icon});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final fg = selected ? colors.primaryColor : colors.textSecondaryColor;

    return Material(
      color: selected ? colors.primaryColor.withValues(alpha: 0.12) : colors.cardBackgroundColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            border: Border.all(color: selected ? colors.primaryColor : colors.borderColor, width: selected ? 1.4 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: Dimensions.iconSizeSmall, color: fg), const SizedBox(width: Dimensions.paddingSizeExtraSmall)],
              Text(
                label,
                style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberMenuChip extends StatelessWidget {
  const _MemberMenuChip({required this.members, required this.selectedMember, required this.onSelected});

  final List<CostMemberEntity> members;
  final CostMemberEntity? selectedMember;
  final ValueChanged<CostMemberEntity?> onSelected;

  static const String _allMembers = '__all_members__';

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final label = selectedMember?.name ?? context.local.uiAllMembers;

    return PopupMenuButton<String>(
      tooltip: context.local.uiFilterByMember,
      onSelected: (value) {
        if (value == _allMembers) {
          onSelected(null);
        } else {
          final found = members.where((m) => m.id == value).firstOrNull;
          onSelected(found);
        }
      },
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      itemBuilder: (context) => [
        PopupMenuItem<String>(value: _allMembers, child: Text(context.local.uiAllMembers)),
        const PopupMenuDivider(),
        for (final m in members) PopupMenuItem<String>(value: m.id, child: Text(m.name)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: colors.primaryColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          border: Border.all(color: colors.primaryColor, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_rounded, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.primaryColor),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
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
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
      color: colors.borderColor,
    );
  }
}
