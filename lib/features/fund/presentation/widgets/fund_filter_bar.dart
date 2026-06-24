import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../bloc/fund_bloc.dart';
import '../bloc/fund_date_filter.dart';
import '../bloc/fund_event.dart';
import 'fund_formatters.dart';

/// Compact, wrap-based date filter for the fund view.
///
/// Funds have no member dimension, so the only filter is the date scope:
/// `[All time] [Day] [Range]`. The chips reflow onto multiple rows on a phone
/// and stay inline on tablet / desktop.
class FundFilterBar extends StatelessWidget {
  const FundFilterBar({
    required this.dateFilter,
    required this.selectedDate,
    required this.selectedRange,
    super.key,
  });

  final FundDateFilter dateFilter;
  final DateTime selectedDate;
  final DateTimeRange? selectedRange;

  FundBloc _bloc(BuildContext context) => context.read<FundBloc>();

  Future<void> _pickDay(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(selectedDate.year - 2),
      lastDate: DateTime(selectedDate.year + 2),
    );
    if (picked != null && context.mounted) {
      _bloc(context).add(FundEvent.selectDate(picked));
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
        FundEvent.selectRange(start: picked.start, end: picked.end),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _SelectChip(
          label: 'All time',
          selected: dateFilter == FundDateFilter.allTime,
          onTap: () => _bloc(context).add(
            const FundEvent.changeDateFilter(FundDateFilter.allTime),
          ),
        ),
        _SelectChip(
          label: dateFilter == FundDateFilter.day
              ? FundFormatters.shortDate(selectedDate)
              : 'Day',
          icon: Icons.event_rounded,
          selected: dateFilter == FundDateFilter.day,
          onTap: () => _pickDay(context),
        ),
        _SelectChip(
          label: dateFilter == FundDateFilter.range && selectedRange != null
              ? FundFormatters.rangeLabel(
                  selectedRange!.start, selectedRange!.end)
              : 'Range',
          icon: Icons.date_range_rounded,
          selected: dateFilter == FundDateFilter.range,
          onTap: () => _pickRange(context),
        ),
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
